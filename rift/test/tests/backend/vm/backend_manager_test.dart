@TestOn('vm')
library;

import 'package:rift/src/backend/vm/backend_manager.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../common.dart';

void main() {
  group('BackendManager', () {
    group('findRiftFileAndCleanUp', () {
      Future<void> checkfindRiftFileAndCleanUp(String folder) async {
        final hiveFileDir = await getAssetDir(
          'findRiftFileAndCleanUp',
          folder,
          'before',
        );
        final hiveFile = await BackendManager().findRiftFileAndCleanUp(
          'testBox',
          hiveFileDir.path,
        );
        expect(hiveFile.path, path.join(hiveFileDir.path, 'testBox.hive'));
        await expectDirEqualsAssetDir(
          hiveFileDir,
          'findRiftFileAndCleanUp',
          folder,
          'after',
        );
      }

      test('no hive file', () async {
        await checkfindRiftFileAndCleanUp('no_hive_file');
      });

      test('hive file', () async {
        await checkfindRiftFileAndCleanUp('hive_file');
      });

      test('hive file and compact file', () async {
        await checkfindRiftFileAndCleanUp('hive_file_and_compact_file');
      });

      test('only compact file', () async {
        await checkfindRiftFileAndCleanUp('only_compact_file');
      });
    });
  });
}
