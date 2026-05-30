@TestOn('vm')
library;

import 'dart:async';
import 'dart:isolate';

import 'package:rift/rift.dart';
import 'package:rift/src/rift_impl.dart';
import 'package:rift/src/isolate/handler/isolate_entry_point.dart';
import 'package:rift/src/isolate/isolated_rift_impl/rift_isolate.dart';
import 'package:rift/src/isolate/isolated_rift_impl/rift_isolate_name.dart';
import 'package:rift/src/isolate/isolated_rift_impl/isolated_rift_impl.dart';
import 'package:rift/src/util/logger.dart';
import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

import '../util/print_utils.dart';
import '../tests/common.dart';
import 'integration.dart';

/// Exists to silence the warning about not passing an INS
class StubIns extends IsolateNameServer {
  @override
  dynamic lookupPortByName(String name) => null;

  @override
  bool registerPortWithName(dynamic port, String name) => true;

  @override
  bool removePortNameMapping(String name) => true;
}

class TestIns extends IsolateNameServer {
  final _ports = <String, SendPort>{};

  @override
  dynamic lookupPortByName(String name) => _ports[name];

  @override
  bool registerPortWithName(dynamic port, String name) {
    _ports[name] = port;
    return true;
  }

  @override
  bool removePortNameMapping(String name) {
    _ports.remove(name);
    return true;
  }
}

final isolateNameRegex = RegExp(r'\(current isolate: .+?\)');

void main() {
  Future<void> runIsolate({
    required IsolateNameServer ins,
    required String path,
    bool close = false,
  }) {
    return Isolate.run(() async {
      final hive = IsolatedRiftImpl();
      (hive as RiftIsolate).entryPoint = (send) =>
          silenceOutput(() => isolateEntryPoint(send));
      await hive.init(path, isolateNameServer: ins);
      final box = await hive.openBox<int>('test');
      for (var i = 0; i < 100; i++) {
        await box.add(i);
      }
      if (close) await hive.close();
    });
  }

  group('isolates', () {
    test('single without INS', () async {
      final dir = await getTempDir();
      final hive = IsolatedRiftImpl();
      await hive.init(dir.path, isolateNameServer: StubIns());
      await expectLater(
        runIsolate(ins: StubIns(), path: dir.path, close: true),
        completes,
      );
      final box = await hive.openBox<int>('test');
      expect(await box.length, 100);
    });

    group('multiple', () {
      test('without INS', () async {
        final dir = await getTempDir();
        final hive = IsolatedRiftImpl();
        (hive as RiftIsolate).entryPoint = (send) =>
            silenceOutput(() => isolateEntryPoint(send));
        await hive.init(dir.path, isolateNameServer: StubIns());
        await expectLater(
          Future.wait([
            for (var i = 0; i < 100; i++)
              runIsolate(ins: StubIns(), path: dir.path),
          ]),
          completes,
        );
        final box = await hive.openBox<int>('test');
        expect(await box.length, isNot(10000));
      });

      test('with INS', () async {
        final dir = await getTempDir();
        final ins = TestIns();
        final hive = IsolatedRiftImpl();
        await hive.init(dir.path, isolateNameServer: ins);
        await expectLater(
          Future.wait([
            for (var i = 0; i < 100; i++) runIsolate(ins: ins, path: dir.path),
          ]),
          completes,
        );
        final box = await hive.openBox<int>('test');
        expect(await box.length, 10000);
      });
    });

    group('warnings', () {
      test('unsafe isolate', () async {
        final patchedWarning = RiftWarning.unsafeIsolate.replaceFirst(
          isolateNameRegex,
          '',
        );

        final safeOutput = await Isolate.run(
          debugName: 'main',
          () => captureOutput(() => Rift.init(null)).toList(),
        );
        expect(safeOutput, isEmpty);

        final unsafeOutput = await Isolate.run(
          () => captureOutput(() => Rift.init(null)).toList(),
        );
        expect(
          unsafeOutput.first.replaceFirst(isolateNameRegex, ''),
          patchedWarning,
        );

        final ignoredOutput = await Isolate.run(
          () => captureOutput(() {
            RiftLogger.unsafeIsolateWarning = false;
            Rift.init(null);
          }).toList(),
        );
        expect(ignoredOutput, isEmpty);
      });

      test('safe rift isolate', () async {
        final hive = IsolatedRiftImpl();
        addTearDown(hive.close);

        (hive as RiftIsolate).entryPoint = (send) {
          final connection = setupIsolate(send);
          final riftChannel = IsolateMethodChannel('rift', connection);
          final testChannel = IsolateMethodChannel('test', connection);
          riftChannel.setMethodCallHandler((_) {});
          testChannel.setMethodCallHandler(
            (_) => captureOutput(() => Rift.init(null)).toList(),
          );
        };
        await hive.init(null, isolateNameServer: StubIns());
        final channel = IsolateMethodChannel(
          'test',
          (hive as RiftIsolate).connection,
        );
        final result = await channel.invokeListMethod('');
        expect(result, isEmpty);
      });

      test('no INS', () async {
        final unsafeOutput = await captureOutput(
          () => IsolatedRiftImpl().init(null),
        ).toList();
        expect(unsafeOutput, contains(RiftWarning.noIsolateNameServer));

        final safeOutput = await captureOutput(
          () => IsolatedRiftImpl().init(null, isolateNameServer: TestIns()),
        ).toList();
        expect(safeOutput, isEmpty);

        final ignoredOutput = await captureOutput(() {
          RiftLogger.noIsolateNameServerWarning = false;
          IsolatedRiftImpl().init(null);
        }).toList();
        expect(ignoredOutput, isEmpty);
      });

      test('unmatched isolation', () async {
        final dir = await getTempDir();
        final path = dir.path;

        await IsolatedRift.init(path, isolateNameServer: StubIns());
        Rift.init(path);

        await IsolatedRift.openBox('box1');
        final output = await captureOutput(() => Rift.openBox('box1')).toList();

        expect(output, contains(RiftWarning.unmatchedIsolation));

        await IsolatedRift.openBox('box2');
        final ignoredOutput = await captureOutput(() async {
          RiftLogger.unmatchedIsolationWarning = false;
          await Rift.openBox('box2');
        }).toList();

        expect(ignoredOutput, isNot(contains(RiftWarning.unmatchedIsolation)));
      });
    });

    test('IsolatedRift data compatible with Rift', () async {
      final dir = await getTempDir();

      final isolatedRift = IsolatedRiftImpl();
      addTearDown(isolatedRift.close);
      await isolatedRift.init(dir.path, isolateNameServer: StubIns());

      final isolatedBox = await isolatedRift.openBox('test');
      await isolatedBox.put('key', 'value');
      await isolatedBox.close();

      final rift = RiftImpl();
      addTearDown(rift.close);
      rift.init(dir.path);

      final box = await rift.openBox('test');
      expect(await box.get('key'), 'value');
    });

    test('Rift data compatible with IsolatedRift', () async {
      final dir = await getTempDir();

      final rift = RiftImpl();
      addTearDown(rift.close);
      rift.init(dir.path);

      final box = await rift.openBox('test');
      await box.put('key', 'value');
      await box.close();

      final isolatedRift = IsolatedRiftImpl();
      addTearDown(isolatedRift.close);
      await isolatedRift.init(dir.path, isolateNameServer: StubIns());

      final isolatedBox = await isolatedRift.openBox('test');
      expect(await isolatedBox.get('key'), 'value');
    });

    test('Encrypted IsolatedRift data compatible with Rift', () async {
      final dir = await getTempDir();
      final cipher = RiftAesCipher(Rift.generateSecureKey());

      final isolatedRift = IsolatedRiftImpl();
      addTearDown(isolatedRift.close);
      await isolatedRift.init(dir.path, isolateNameServer: StubIns());

      final isolatedBox = await isolatedRift.openBox(
        'test',
        encryptionCipher: cipher,
      );
      await isolatedBox.put('key', 'value');
      await isolatedBox.close();

      final rift = RiftImpl();
      addTearDown(rift.close);
      rift.init(dir.path);

      final box = await rift.openBox('test', encryptionCipher: cipher);
      expect(await box.get('key'), 'value');
    });

    test('Encrypted Rift data compatible with IsolatedRift', () async {
      final dir = await getTempDir();
      final cipher = RiftAesCipher(Rift.generateSecureKey());

      final rift = RiftImpl();
      addTearDown(rift.close);
      rift.init(dir.path);

      final box = await rift.openBox('test', encryptionCipher: cipher);
      await box.put('key', 'value');
      await box.close();

      final isolatedRift = IsolatedRiftImpl();
      addTearDown(isolatedRift.close);
      await isolatedRift.init(dir.path, isolateNameServer: StubIns());

      final isolatedBox = await isolatedRift.openBox(
        'test',
        encryptionCipher: cipher,
      );
      expect(await isolatedBox.get('key'), 'value');
    });

    test('IsolatedRift data encrypted with no keyCrc is readable', () async {
      final dir = await getTempDir();
      final key = Rift.generateSecureKey();

      final isolatedRift = IsolatedRiftImpl();
      addTearDown(isolatedRift.close);
      await isolatedRift.init(dir.path, isolateNameServer: StubIns());

      final box = await isolatedRift.openBox(
        'test',
        encryptionCipher: ZeroKeyCrcCipher(key),
      );
      await box.put('key', 'value');
      await box.close();

      final box2 = await isolatedRift.openBox(
        'test',
        encryptionCipher: RiftAesCipher(key),
      );
      expect(await box2.get('key'), 'value');
    });

    test(
      'Encrypted IsolatedBox data compatible with IsolatedLazyBox',
      () async {
        final dir = await getTempDir();
        final key = Rift.generateSecureKey();

        final isolatedRift = IsolatedRiftImpl();
        addTearDown(isolatedRift.close);
        await isolatedRift.init(dir.path, isolateNameServer: StubIns());

        final box = await isolatedRift.openBox(
          'test',
          encryptionCipher: RiftAesCipher(key),
        );
        await box.put('key', 'value');
        await box.close();

        final lazyBox = await isolatedRift.openLazyBox(
          'test',
          encryptionCipher: RiftAesCipher(key),
        );
        expect(await lazyBox.get('key'), 'value');
      },
    );

    test(
      'Encrypted IsolatedLazyBox data compatible with IsolatedBox',
      () async {
        final dir = await getTempDir();
        final key = Rift.generateSecureKey();

        final isolatedRift = IsolatedRiftImpl();
        addTearDown(isolatedRift.close);
        await isolatedRift.init(dir.path, isolateNameServer: StubIns());

        final lazyBox = await isolatedRift.openLazyBox(
          'test',
          encryptionCipher: RiftAesCipher(key),
        );
        await lazyBox.put('key', 'value');
        await lazyBox.close();

        final box = await isolatedRift.openBox(
          'test',
          encryptionCipher: RiftAesCipher(key),
        );
        expect(await box.get('key'), 'value');
      },
    );

    test('Stale send port', () async {
      final dir = await getTempDir();
      final hive = IsolatedRiftImpl();
      addTearDown(hive.close);

      final ins = TestIns();
      ins.registerPortWithName(ReceivePort().sendPort, riftIsolateName);

      var spawned = false;
      (hive as RiftIsolate).spawnRiftIsolate = () {
        spawned = true;
        return spawnIsolate(isolateEntryPoint);
      };

      await hive.init(dir.path, isolateNameServer: ins);

      expect(spawned, isTrue);
    });
  }, onPlatform: {'chrome': Skip('Isolates are not supported on web')});
}

/// Test cipher that always returns a zero key CRC
class ZeroKeyCrcCipher extends RiftAesCipher {
  ZeroKeyCrcCipher(super.key);

  @override
  int calculateKeyCrc() => 0;
}

