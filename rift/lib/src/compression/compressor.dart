import 'dart:typed_data';

import 'package:rift/src/compression/lz4_compressor.dart';

/// Compression algorithm selector.
enum CompressionAlgorithm {
  /// LZ4-style fast compression. Good balance of speed and ratio.
  lz4,

  /// Zstandard-style compression. Better ratio but slower.
  /// (Currently falls back to LZ4-style implementation.)
  zstd,
}

/// Compression configuration for Rift boxes.
///
/// Automatically compresses values larger than a threshold
/// to save 30-70% storage space with minimal performance impact.
///
/// Usage:
/// ```dart
/// await rift.openBox('largeData', compression: RiftCompression.lz4);
/// // or
/// await rift.openBox('largeData', compression: RiftCompression(
///   algorithm: CompressionAlgorithm.lz4,
///   threshold: 512, // Only compress values > 512 bytes
/// ));
/// ```
class RiftCompression {
  /// The compression algorithm to use.
  final CompressionAlgorithm algorithm;

  /// Minimum byte size to trigger compression.
  /// Values smaller than this threshold are stored uncompressed.
  /// Set to -1 to disable compression entirely.
  final int threshold;

  /// Creates a compression configuration.
  ///
  /// [algorithm] defaults to [CompressionAlgorithm.lz4].
  /// [threshold] defaults to 256 bytes — values smaller than this
  /// are stored as-is since compression overhead outweighs gains.
  const RiftCompression({
    this.algorithm = CompressionAlgorithm.lz4,
    this.threshold = 256,
  });

  /// Preset: LZ4 compression with default threshold (256 bytes).
  static const lz4 = RiftCompression();

  /// Preset: No compression (threshold = -1 means never compress).
  static const none = RiftCompression(
    algorithm: CompressionAlgorithm.lz4,
    threshold: -1,
  );

  /// Whether compression is effectively enabled.
  bool get isEnabled => threshold >= 0;

  /// Compress [data] using the configured algorithm.
  ///
  /// If [data.length] is below [threshold], returns the data unchanged.
  /// Otherwise, compresses and wraps the result in a container that
  /// includes a header byte so [decompress] can detect compressed output.
  Uint8List compress(Uint8List data) {
    if (!isEnabled || data.length < threshold) {
      // Not compressed — prefix with 0x00 header
      final out = Uint8List(1 + data.length);
      out[0] = 0x00; // uncompressed marker
      out.setRange(1, 1 + data.length, data);
      return out;
    }

    final compressed = _compressRaw(data);
    // If compression didn't actually save space, store uncompressed
    if (compressed.length >= data.length) {
      final out = Uint8List(1 + data.length);
      out[0] = 0x00;
      out.setRange(1, 1 + data.length, data);
      return out;
    }

    // Compressed — prefix with 0x01 header + 4-byte original length
    final out = Uint8List(1 + 4 + compressed.length);
    out[0] = 0x01; // compressed marker
    // Store original length as little-endian uint32
    out[1] = data.length & 0xFF;
    out[2] = (data.length >> 8) & 0xFF;
    out[3] = (data.length >> 16) & 0xFF;
    out[4] = (data.length >> 24) & 0xFF;
    out.setRange(5, 5 + compressed.length, compressed);
    return out;
  }

  /// Decompress [data] that was previously compressed with [compress].
  ///
  /// Inspects the header byte to determine whether the payload is
  /// compressed or stored as-is.
  Uint8List decompress(Uint8List data) {
    if (data.isEmpty) return data;

    final marker = data[0];
    if (marker == 0x00) {
      // Uncompressed — skip header byte
      return Uint8List.sublistView(data, 1);
    } else if (marker == 0x01) {
      // Compressed — read original length, then decompress
      if (data.length < 5) {
        throw StateError('Invalid compressed data: header too short');
      }
      final originalLength =
          data[1] | (data[2] << 8) | (data[3] << 16) | (data[4] << 24);
      final compressed = Uint8List.sublistView(data, 5);
      return _decompressRaw(compressed, originalLength);
    } else {
      throw StateError('Invalid compression marker: $marker');
    }
  }

  /// Internal: perform raw compression (no header).
  Uint8List _compressRaw(Uint8List data) {
    switch (algorithm) {
      case CompressionAlgorithm.lz4:
      case CompressionAlgorithm.zstd:
        // Both currently use the LZ4-style compressor
        return Lz4Compressor.compress(data);
    }
  }

  /// Internal: perform raw decompression (no header).
  Uint8List _decompressRaw(Uint8List data, int originalLength) {
    switch (algorithm) {
      case CompressionAlgorithm.lz4:
      case CompressionAlgorithm.zstd:
        return Lz4Compressor.decompress(data, originalLength);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RiftCompression &&
      other.algorithm == algorithm &&
      other.threshold == threshold;

  @override
  int get hashCode => algorithm.hashCode ^ threshold.hashCode;

  @override
  String toString() =>
      'RiftCompression(algorithm: $algorithm, threshold: $threshold)';
}
