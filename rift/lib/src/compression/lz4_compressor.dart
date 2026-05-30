import 'dart:typed_data';

/// A simplified LZ4-style compression implementation in pure Dart.
///
/// Not full LZ4 spec-compatible, but follows the same design philosophy:
/// - For each 4-byte sequence, check if it appeared in the last 64KB
/// - If yes, encode as (offset, length) match
/// - If no, encode as literal bytes
/// - This gives decent compression with very fast speed
///
/// Binary format:
/// ```
/// [token] [literals...] [offset_high] [offset_low] [match_length_ext...]
/// ```
///
/// Token byte:
/// - High 4 bits: literal length (0-15, 15 means extended)
/// - Low 4 bits: match length - 4 (0-15, 15 means extended)
///
/// Extended lengths use additional bytes (each 255 means add 255 and continue).
/// Match offset is stored as big-endian uint16.
class Lz4Compressor {
  /// Maximum match offset (64KB window).
  static const int _maxOffset = 65536;

  /// Minimum match length.
  static const int _minMatch = 4;

  /// Maximum match length (including the 4-byte base).
  static const int _maxMatch = 0xFFFF + _minMatch;

  /// Maximum literal run length per token.
  static const int _maxLiteralPerToken = 0xF;

  /// Hash table size (16-bit hash for 4-byte sequences).
  static const int _hashSize = 1 << 16;

  /// Hash shift for computing 4-byte sequence hash.
  static const int _hashShift = 16;

  // ---------- Compression ----------

  /// Compress [data] using simplified LZ4 scheme.
  static Uint8List compress(Uint8List data) {
    final len = data.length;
    if (len < _minMatch) {
      // Too small to compress, just emit as literals
      return _emitLiteralsOnly(data);
    }

    // Output buffer — worst case is slightly larger than input
    final out = Uint8List(len + len ~/ 255 + 16);
    var outPos = 0;

    // Hash table: maps 4-byte hash to position in input
    final hashTable = Int32List(_hashSize);

    // Anchor is the start of the current literal run
    var anchor = 0;
    var pos = 0;

    while (pos < len - _minMatch) {
      // Hash the next 4 bytes
      final h = _hash4(data, pos);

      // Check for a match in the hash table
      final ref = hashTable[h];
      hashTable[h] = pos;

      // Is the reference within the window?
      if (ref < 0 || pos - ref > _maxOffset || ref >= pos) {
        pos++;
        continue;
      }

      // Verify the match — at least 4 bytes must match
      if (!_matchAt(data, ref, pos, _minMatch)) {
        pos++;
        continue;
      }

      // Found a match! Extend it as far as possible.
      var matchLen = _minMatch;
      while (pos + matchLen < len &&
          matchLen < _maxMatch &&
          data[ref + matchLen] == data[pos + matchLen]) {
        matchLen++;
      }

      // Emit any pending literals before this match
      final literalLen = pos - anchor;
      outPos = _encodeTokenAndLiterals(
        out,
        outPos,
        literalLen,
        data,
        anchor,
        matchLen - _minMatch,
      );

      // Encode the match offset (big-endian uint16)
      final offset = pos - ref;
      out[outPos++] = (offset >> 8) & 0xFF;
      out[outPos++] = offset & 0xFF;

      // Advance position past the match
      pos += matchLen;
      anchor = pos;

      // Update hash table for positions we skipped
      // (helps find more matches later)
      if (pos < len - _minMatch) {
        hashTable[_hash4(data, pos - 2)] = pos - 2;
      }
    }

    // Emit remaining literals
    if (anchor < len) {
      final literalLen = len - anchor;
      outPos = _encodeTokenAndLiterals(
        out,
        outPos,
        literalLen,
        data,
        anchor,
        0, // no match after final literals
      );
    }

    return Uint8List.sublistView(out, 0, outPos);
  }

  // ---------- Decompression ----------

  /// Decompress [data] that was compressed by [compress].
  /// [originalLength] is the expected output length (used for pre-allocation).
  static Uint8List decompress(Uint8List data, int originalLength) {
    final out = Uint8List(originalLength);
    var outPos = 0;
    var inPos = 0;
    final inLen = data.length;

    while (inPos < inLen) {
      // Read token
      final token = data[inPos++];

      // --- Literals ---
      var literalLen = (token >> 4) & 0x0F;
      if (literalLen == 15) {
        // Extended literal length
        while (inPos < inLen) {
          final extra = data[inPos++];
          literalLen += extra;
          if (extra != 255) break;
        }
      }

      // Copy literals
      if (literalLen > 0) {
        if (inPos + literalLen > inLen ||
            outPos + literalLen > originalLength) {
          throw StateError('Invalid compressed data: literal overrun');
        }
        out.setRange(outPos, outPos + literalLen, data, inPos);
        outPos += literalLen;
        inPos += literalLen;
      }

      // Check if we've reached end of stream (no match after last literals)
      if (inPos >= inLen) break;

      // --- Match ---
      // Read offset (big-endian uint16)
      if (inPos + 1 >= inLen) {
        throw StateError('Invalid compressed data: match offset truncated');
      }
      final offset = (data[inPos] << 8) | data[inPos + 1];
      inPos += 2;

      if (offset == 0) {
        throw StateError('Invalid compressed data: zero match offset');
      }

      var matchLen = (token & 0x0F) + _minMatch;
      if ((token & 0x0F) == 15) {
        // Extended match length
        while (inPos < inLen) {
          final extra = data[inPos++];
          matchLen += extra;
          if (extra != 255) break;
        }
      }

      // Copy match (may overlap, so copy byte-by-byte)
      final matchSrc = outPos - offset;
      if (matchSrc < 0 || matchSrc >= outPos) {
        throw StateError('Invalid compressed data: match offset out of range');
      }
      if (outPos + matchLen > originalLength) {
        throw StateError('Invalid compressed data: match overrun');
      }
      for (var i = 0; i < matchLen; i++) {
        out[outPos + i] = out[matchSrc + i];
      }
      outPos += matchLen;
    }

    if (outPos != originalLength) {
      throw StateError(
        'Decompressed size mismatch: expected $originalLength, got $outPos',
      );
    }

    return out;
  }

  // ---------- Helpers ----------

  /// Compute a 16-bit hash of the 4 bytes starting at [pos].
  static int _hash4(Uint8List data, int pos) {
    // Read 4 bytes as a 32-bit value (little-endian)
    final v =
        data[pos] |
        (data[pos + 1] << 8) |
        (data[pos + 2] << 16) |
        (data[pos + 3] << 24);
    // Multiply by a large prime and shift down to 16 bits
    return ((v * 2654435761) >> _hashShift) & (_hashSize - 1);
  }

  /// Check if [minMatch] bytes match at [ref] and [pos] in [data].
  static bool _matchAt(Uint8List data, int ref, int pos, int minMatch) {
    for (var i = 0; i < minMatch; i++) {
      if (data[ref + i] != data[pos + i]) return false;
    }
    return true;
  }

  /// Encode a token byte, literal data, and match length into [out] at [outPos].
  /// Returns the new output position.
  static int _encodeTokenAndLiterals(
    Uint8List out,
    int outPos,
    int literalLen,
    Uint8List data,
    int dataOffset,
    int matchLenMinusMin,
  ) {
    // Token: high nibble = min(literalLen, 15), low nibble = min(matchLenMinusMin, 15)
    final litBits = literalLen < 15 ? literalLen : 15;
    final matchBits = matchLenMinusMin < 15 ? matchLenMinusMin : 15;
    out[outPos++] = (litBits << 4) | matchBits;

    // Extended literal length
    if (literalLen >= 15) {
      var remaining = literalLen - 15;
      while (remaining >= 255) {
        out[outPos++] = 255;
        remaining -= 255;
      }
      out[outPos++] = remaining;
    }

    // Copy literal bytes
    out.setRange(outPos, outPos + literalLen, data, dataOffset);
    outPos += literalLen;

    // Extended match length (only if there is a match)
    if (matchLenMinusMin >= 15) {
      var remaining = matchLenMinusMin - 15;
      while (remaining >= 255) {
        out[outPos++] = 255;
        remaining -= 255;
      }
      out[outPos++] = remaining;
    }

    return outPos;
  }

  /// Emit data as a single literal run (for tiny inputs that can't be compressed).
  static Uint8List _emitLiteralsOnly(Uint8List data) {
    final len = data.length;
    final out = Uint8List(1 + (len >= 15 ? (len - 14) : 0) + len);

    var pos = 0;
    final litBits = len < 15 ? len : 15;
    out[pos++] = litBits << 4; // token: match nibble = 0 (no match)

    if (len >= 15) {
      var remaining = len - 15;
      while (remaining >= 255) {
        out[pos++] = 255;
        remaining -= 255;
      }
      out[pos++] = remaining;
    }

    out.setRange(pos, pos + len, data);
    return out;
  }
}
