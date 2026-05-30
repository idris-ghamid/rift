import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:rift/rift.dart';
import 'package:rift/src/backend/lock_props.dart';
import 'package:rift/src/backend/storage_backend.dart';
import 'package:rift/src/backend/vm/read_write_sync.dart';
import 'package:rift/src/binary/frame.dart';
import 'package:rift/src/box/keystore.dart';
import 'package:rift/src/io/buffered_file_reader.dart';
import 'package:rift/src/io/buffered_file_writer.dart';
import 'package:rift/src/io/frame_io_helper.dart';
import 'package:rift/src/util/logger.dart';
import 'package:rift/src/wal/wal_manager.dart';
import 'package:rift/src/wal/wal_entry.dart';
import 'package:rift/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';

/// Storage backend for the Dart VM
class StorageBackendVm extends StorageBackend {
  final File _file;
  final File _lockFile;
  final bool _crashRecovery;
  final RiftCipher? _cipher;
  final int? _keyCrc;
  final FrameIoHelper _frameHelper;

  final ReadWriteSync _sync;

  /// Optional WAL manager for crash safety. When provided, all write
  /// operations are logged to the WAL before being applied to the main
  /// data file. On recovery, uncommitted WAL entries are replayed.
  final WALManager? walManager;

  /// The box name associated with this backend. Used for WAL logging.
  String _boxName = '';

  /// Not part of public API
  ///
  /// Not `late final` for testing
  @visibleForTesting
  late RandomAccessFile readRaf;

  /// Not part of public API
  ///
  /// Not `late final` for testing
  @visibleForTesting
  late RandomAccessFile writeRaf;

  /// Not part of public API
  @visibleForTesting
  late RandomAccessFile lockRaf;

  /// Not part of public API
  @visibleForTesting
  var writeOffset = 0;

  /// Not part of public API
  @visibleForTesting
  late final TypeRegistry registry;

  var _compactionScheduled = false;

  /// The file header for this database file, or a legacy header if the file
  /// was created by old Rift without a header.
  FileHeader _fileHeader = FileHeader.legacy();

  /// Whether the header has been written to the file on disk
  bool _headerWritten = false;

  /// Not part of public API
  StorageBackendVm(
    this._file,
    this._lockFile,
    this._crashRecovery,
    this._cipher,
    this._keyCrc, {
    this.walManager,
  }) : _frameHelper = FrameIoHelper(),
       _sync = ReadWriteSync();

  /// Not part of public API
  StorageBackendVm.debug(
    this._file,
    this._lockFile,
    this._crashRecovery,
    this._cipher,
    this._keyCrc,
    this._frameHelper,
    this._sync, {
    this.walManager,
  });

  @override
  String get path => _file.path;

  @override
  var supportsCompaction = true;

  /// Not part of public API
  Future open() async {
    readRaf = await _file.open();
    writeRaf = await _file.open(mode: FileMode.writeOnlyAppend);
    writeOffset = await writeRaf.length();

    // Check for existing file header
    if (writeOffset >= FileHeader.headerSize) {
      await readRaf.setPosition(0);
      final headerBytes = await readRaf.read(FileHeader.headerSize);
      final header = FileHeader.fromBytes(headerBytes);
      if (header != null) {
        _fileHeader = header;
        _headerWritten = true;
      } else {
        // Legacy file without a RIFT header
        _fileHeader = FileHeader.legacy();
        _headerWritten = false;
      }
    } else if (writeOffset == 0) {
      // New file — write the header
      _fileHeader = FileHeader();
      final headerBytes = _fileHeader.toBytes();
      await writeRaf.writeFrom(headerBytes);
      writeOffset = FileHeader.headerSize;
      _headerWritten = true;
    }
  }

  /// Sets the box name for this backend, used for WAL logging.
  void setBoxName(String name) {
    _boxName = name;
  }

  @override
  Future<void> initialize(
    TypeRegistry registry,
    Keystore keystore,
    bool lazy, {
    bool isolated = false,
  }) async {
    this.registry = registry;

    // Set the type registry on the WAL manager so it can serialize values
    if (walManager != null) {
      walManager!.setRegistry(registry as TypeRegistryImpl);
    }

    if (_lockFile.existsSync()) {
      late final LockProps props;
      try {
        props = LockProps.fromJson(jsonDecode(_lockFile.readAsStringSync()));
      } catch (_) {
        props = LockProps();
      }
      if (Logger.unmatchedIsolationWarning && props.isolated && !isolated) {
        Logger.w(RiftWarning.unmatchedIsolation);
      }
    }

    lockRaf = await _lockFile.open(mode: FileMode.write);
    lockRaf.writeStringSync(jsonEncode(LockProps(isolated: isolated)));
    lockRaf.flushSync();
    await lockRaf.lock();

    int recoveryOffset;
    final dataStartOffset = _headerWritten ? FileHeader.headerSize : 0;
    if (!lazy) {
      recoveryOffset = await _frameHelper.framesFromFile(
        path,
        keystore,
        registry,
        _cipher,
        _keyCrc,
        verbatim: isolated,
        dataStartOffset: dataStartOffset,
      );
    } else {
      recoveryOffset = await _frameHelper.keysFromFile(
        path,
        keystore,
        _cipher,
        _keyCrc,
        dataStartOffset: dataStartOffset,
      );
    }

    if (recoveryOffset != -1) {
      if (_crashRecovery) {
        Logger.i('Recovering corrupted box.');
        await writeRaf.truncate(recoveryOffset);
        await writeRaf.setPosition(recoveryOffset);
        writeOffset = recoveryOffset;
      } else {
        throw RiftError('Wrong checksum in Rift file. Box may be corrupted.');
      }
    }

    // Replay WAL entries for this box after normal initialization
    if (walManager != null && _boxName.isNotEmpty) {
      await walManager!.recover();
    }
  }

  @override
  Future<dynamic> readValue(Frame frame, {bool verbatim = false}) {
    return _sync.syncRead(() async {
      await readRaf.setPosition(frame.offset);

      final bytes = await readRaf.read(frame.length!);

      final reader = BinaryReaderImpl(bytes, registry);
      final readFrame = reader.readFrame(
        cipher: _cipher,
        keyCrc: _keyCrc,
        lazy: false,
        verbatim: verbatim,
      );

      if (readFrame == null) {
        throw RiftError(
          'Could not read value from box. Maybe your box is corrupted.',
        );
      }

      return readFrame.value;
    });
  }

  @override
  Future<void> writeFrames(List<Frame> frames, {bool verbatim = false}) async {
    // Log to WAL before writing to the main data file
    if (walManager != null && _boxName.isNotEmpty) {
      final entries = <WALEntry>[];
      for (final frame in frames) {
        if (frame.deleted) {
          entries.add(walManager!.createDeleteEntry(_boxName, frame.key));
        } else {
          // Serialize the frame value for the WAL entry
          Uint8List? serializedValue;
          if (verbatim && frame.value is Uint8List) {
            serializedValue = frame.value as Uint8List;
          } else {
            try {
              final valueWriter = BinaryWriterImpl(registry);
              valueWriter.writeFrame(
                frame,
                cipher: _cipher,
                keyCrc: _keyCrc,
                verbatim: verbatim,
              );
              serializedValue = valueWriter.toBytes();
            } catch (_) {
              // If serialization fails, still proceed with the write
              // without a complete WAL entry value
            }
          }
          entries.add(
            walManager!.createPutEntry(_boxName, frame.key, serializedValue),
          );
        }
      }
      await walManager!.logBatch(entries);
    }

    return _sync.syncWrite(() async {
      final writer = BinaryWriterImpl(registry);

      for (final frame in frames) {
        frame.length = writer.writeFrame(
          frame,
          cipher: _cipher,
          keyCrc: _keyCrc,
          verbatim: verbatim,
        );
      }

      try {
        await writeRaf.writeFrom(writer.toBytes());
      } catch (e) {
        await writeRaf.setPosition(writeOffset);
        rethrow;
      }

      for (final frame in frames) {
        frame.offset = writeOffset;
        writeOffset += frame.length!;
      }
    });
  }

  @override
  Future<void> compact(Iterable<Frame> frames) {
    if (_compactionScheduled) return Future.value();
    _compactionScheduled = true;

    return _sync.syncReadWrite(() async {
      // Checkpoint the WAL before compaction — after compaction the data
      // file is consistent, so prior WAL entries are no longer needed.
      if (walManager != null) {
        await walManager!.checkpoint();
      }
      await readRaf.setPosition(0);
      final reader = BufferedFileReader(readRaf);

      final fileDirectory = path.substring(0, path.length - 5);
      final compactFile = File('$fileDirectory.hivec');
      final compactRaf = await compactFile.open(mode: FileMode.write);
      final writer = BufferedFileWriter(compactRaf);

      // Write the file header at the beginning of the compacted file.
      // This upgrades legacy files to the new format on compaction.
      final header = _fileHeader.isLegacy ? FileHeader() : _fileHeader;
      await writer.write(header.toBytes());
      _fileHeader = header;
      _headerWritten = true;

      final sortedFrames = frames.toList();
      sortedFrames.sort((a, b) => a.offset.compareTo(b.offset));
      try {
        for (final frame in sortedFrames) {
          if (frame.offset == -1) continue; // Frame has not been written yet
          if (frame.offset != reader.offset) {
            final skip = frame.offset - reader.offset;
            if (reader.remainingInBuffer < skip) {
              if (await reader.loadBytes(skip) < skip) {
                throw RiftError('Could not compact box: Unexpected EOF.');
              }
            }
            reader.skip(skip);
          }

          if (reader.remainingInBuffer < frame.length!) {
            if (await reader.loadBytes(frame.length!) < frame.length!) {
              throw RiftError('Could not compact box: Unexpected EOF.');
            }
          }
          await writer.write(reader.viewBytes(frame.length!));
        }
        await writer.flush();
      } finally {
        await compactRaf.close();
      }

      await readRaf.close();
      await writeRaf.close();

      try {
        // This can fail on some systems
        await compactFile.rename(path);
      } catch (e) {
        await compactFile.delete();
        rethrow;
      } finally {
        await open();
        _compactionScheduled = false;
      }

      var offset = FileHeader.headerSize;
      for (final frame in sortedFrames) {
        if (frame.offset == -1) continue;
        frame.offset = offset;
        offset += frame.length!;
      }
    });
  }

  @override
  Future<void> clear() async {
    // Log the clear operation to WAL before clearing the data file
    if (walManager != null) {
      await walManager!.log(walManager!.createClearEntry(_boxName));
    }

    return _sync.syncReadWrite(() async {
      await writeRaf.truncate(0);
      await writeRaf.setPosition(0);
      // Re-write the file header after clearing
      _fileHeader = FileHeader();
      final headerBytes = _fileHeader.toBytes();
      await writeRaf.writeFrom(headerBytes);
      writeOffset = FileHeader.headerSize;
      _headerWritten = true;
    });
  }

  Future _closeInternal() async {
    await readRaf.close();
    await writeRaf.close();

    await lockRaf.close();
    await _lockFile.delete();

    // Unregister this box from WAL replay callbacks
    if (walManager != null && _boxName.isNotEmpty) {
      walManager!.unregisterReplayCallback(_boxName);
    }
  }

  @override
  Future<void> close() {
    return _sync.syncReadWrite(_closeInternal);
  }

  @override
  Future<void> deleteFromDisk() {
    return _sync.syncReadWrite(() async {
      await _closeInternal();
      await _file.delete();
    });
  }

  @override
  Future<void> flush() {
    return _sync.syncWrite(() async {
      await writeRaf.flush();
    });
  }
}
