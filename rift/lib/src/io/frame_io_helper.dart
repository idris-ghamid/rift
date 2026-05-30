import 'dart:io';
import 'dart:typed_data';

import 'package:rift/rift.dart';
import 'package:rift/src/binary/frame_helper.dart';
import 'package:rift/src/box/keystore.dart';
import 'package:rift/src/io/buffered_file_reader.dart';
import 'package:rift/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';

/// Not part of public API
class FrameIoHelper extends FrameHelper {
  /// Not part of public API
  @visibleForTesting
  Future<RandomAccessFile> openFile(String path) {
    return File(path).open();
  }

  /// Not part of public API
  @visibleForTesting
  Future<List<int>> readFile(String path) {
    return File(path).readAsBytes();
  }

  /// Not part of public API
  Future<int> keysFromFile(
    String path,
    Keystore keystore,
    RiftCipher? cipher,
    int? keyCrc, {
    int dataStartOffset = 0,
  }) async {
    final raf = await openFile(path);
    final fileReader = BufferedFileReader(raf);
    if (dataStartOffset > 0) {
      await raf.setPosition(dataStartOffset);
    }
    try {
      return await _KeyReader(
        fileReader,
        dataStartOffset,
      ).readKeys(keystore, cipher, keyCrc);
    } finally {
      await raf.close();
    }
  }

  /// Not part of public API
  Future<int> framesFromFile(
    String path,
    Keystore keystore,
    TypeRegistry registry,
    RiftCipher? cipher,
    int? keyCrc, {
    bool verbatim = false,
    int dataStartOffset = 0,
  }) async {
    final bytes = await readFile(path);
    final dataBytes = dataStartOffset > 0
        ? Uint8List.sublistView(bytes as Uint8List, dataStartOffset)
        : bytes as Uint8List;
    final result = framesFromBytes(
      dataBytes,
      keystore,
      registry,
      cipher,
      keyCrc,
      verbatim: verbatim,
    );
    // Adjust returned recovery offset and frame offsets for the header
    if (dataStartOffset > 0) {
      for (final key in keystore.getKeys()) {
        final frame = keystore.get(key);
        if (frame != null && frame.offset >= 0) {
          frame.offset += dataStartOffset;
        }
      }
      if (result != -1) {
        return result + dataStartOffset;
      }
    }
    return result;
  }
}

class _KeyReader {
  final BufferedFileReader fileReader;

  /// Offset to add to frame positions (accounts for file header)
  final int _dataStartOffset;

  late BinaryReaderImpl _reader;

  _KeyReader(this.fileReader, this._dataStartOffset);

  Future<int> readKeys(
    Keystore keystore,
    RiftCipher? cipher,
    int? keyCrc,
  ) async {
    await _load(4);
    while (true) {
      final frameOffset = fileReader.offset + _dataStartOffset;

      if (_reader.availableBytes < 4) {
        final available = await _load(4);
        if (available == 0) {
          break;
        } else if (available < 4) {
          return frameOffset;
        }
      }

      final frameLength = _reader.peekUint32();
      if (_reader.availableBytes < frameLength) {
        final available = await _load(frameLength);
        if (available < frameLength) return frameOffset;
      }

      final frame = _reader.readFrame(
        cipher: cipher,
        keyCrc: keyCrc,
        lazy: true,
        frameOffset: frameOffset,
      );
      if (frame == null) return frameOffset;

      keystore.insert(frame, notify: false);

      fileReader.skip(frameLength);
    }

    return -1;
  }

  Future<int> _load(int bytes) async {
    final loadedBytes = await fileReader.loadBytes(bytes);
    final buffer = fileReader.peekBytes(loadedBytes);
    _reader = BinaryReaderImpl(buffer, TypeRegistryImpl.nullImpl);

    return loadedBytes;
  }
}
