import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Rift CLI tool for database inspection and management.
///
/// Provides commands for inspecting, exporting, importing, migrating,
/// validating, and gathering statistics about Rift database files.
///
/// Usage:
/// ```dart
/// await RiftCLI.run(['inspect', '/path/to/db']);
/// await RiftCLI.run(['stats', '/path/to/db']);
/// ```
class RiftCLI {
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _cyan = '\x1B[36m';
  static const String _reset = '\x1B[0m';

  /// Runs the CLI with the given [args].
  static Future<void> run(List<String> args) async {
    if (args.isEmpty) {
      _printUsage();
      return;
    }

    final command = args[0];
    final commandArgs = args.sublist(1);

    try {
      switch (command) {
        case 'inspect':
          if (commandArgs.isEmpty) {
            _printError('inspect requires a path argument');
            return;
          }
          await inspect(commandArgs[0]);
        case 'export':
          if (commandArgs.length < 2) {
            _printError('export requires boxName and outputPath arguments');
            return;
          }
          await exportData(commandArgs[0], commandArgs[1]);
        case 'import':
          if (commandArgs.length < 2) {
            _printError('import requires boxName and inputPath arguments');
            return;
          }
          await importData(commandArgs[0], commandArgs[1]);
        case 'migrate':
          if (commandArgs.length < 2) {
            _printError('migrate requires path and targetVersion arguments');
            return;
          }
          final targetVersion = int.tryParse(commandArgs[1]);
          if (targetVersion == null) {
            _printError('targetVersion must be an integer');
            return;
          }
          await migrate(commandArgs[0], targetVersion);
        case 'validate':
          if (commandArgs.isEmpty) {
            _printError('validate requires a path argument');
            return;
          }
          await validate(commandArgs[0]);
        case 'stats':
          if (commandArgs.isEmpty) {
            _printError('stats requires a path argument');
            return;
          }
          await stats(commandArgs[0]);
        case 'help':
          _printUsage();
        default:
          _printError('Unknown command: $command');
          _printUsage();
      }
    } catch (e) {
      _printError('Error: $e');
      exit(1);
    }
  }

  /// Inspects the database at [path] and prints structural information.
  static Future<void> inspect(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      _printError('Directory does not exist: $path');
      return;
    }

    _printHeader('Rift Database Inspection');
    _printInfo('Path: ${dir.absolute.path}');
    stdout.writeln();

    final files = await dir.list().toList();
    final boxFiles = <File>[];

    for (final file in files) {
      if (file is File) {
        final name = file.path.split(Platform.pathSeparator).last;
        if (name.endsWith('.hive') || name.endsWith('.rift')) {
          boxFiles.add(file);
        }
      }
    }

    if (boxFiles.isEmpty) {
      _printInfo('No Rift box files found in directory.');
      return;
    }

    _printInfo('Found ${boxFiles.length} box file(s):');
    stdout.writeln();

    for (final entity in boxFiles) {
      final name = entity.path.split(Platform.pathSeparator).last;
      final boxName = name.replaceAll(RegExp(r'\.(hive|rift)$'), '');
      final size = await entity.length();

      _printField('  Box', boxName);
      _printField('  File', name);
      _printField('  Size', _formatBytes(size));

      try {
        final bytes = await _readFileHeader(entity);
        if (bytes != null && bytes.length >= 4) {
          final isValid = _validateHeader(bytes);
          _printField(
            '  Valid',
            isValid ? '$_green yes $_reset' : '$_red no $_reset',
          );
        } else {
          _printField('  Valid', '$_yellow unknown (file too small) $_reset');
        }
      } catch (e) {
        _printField('  Valid', '$_yellow unknown ($e) $_reset');
      }
      stdout.writeln();
    }

    final walFile = File('${dir.path}${Platform.pathSeparator}rift.wal');
    if (await walFile.exists()) {
      final walSize = await walFile.length();
      _printField(
        'WAL File',
        '$_yellow present $_reset (${_formatBytes(walSize)})',
      );
    } else {
      _printField('WAL File', '$_green none $_reset');
    }
  }

  /// Exports data from a box to a JSON file.
  static Future<void> exportData(String boxName, String outputPath) async {
    _printHeader('Rift Data Export');

    final outputFile = File(outputPath);
    final outputDir = outputFile.parent;
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    try {
      final sourceFile = File(boxName);
      final actualSource = await sourceFile.exists()
          ? sourceFile
          : File('$boxName.hive');

      if (!await actualSource.exists()) {
        _printError('Box file not found: $boxName');
        return;
      }

      final bytes = await actualSource.readAsBytes();
      final entries = _parseBoxEntries(bytes);

      final export = {
        'version': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'box': boxName,
        'entries': entries,
        'length': entries.length,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(export);
      await outputFile.writeAsString(jsonStr);

      _printSuccess('Exported ${entries.length} entries to $outputPath');
      _printInfo('File size: ${_formatBytes(await outputFile.length())}');
    } catch (e) {
      _printError('Export failed: $e');
    }
  }

  /// Imports data into a box from a JSON file.
  static Future<void> importData(String boxName, String inputPath) async {
    _printHeader('Rift Data Import');

    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      _printError('Input file not found: $inputPath');
      return;
    }

    try {
      final jsonStr = await inputFile.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (!data.containsKey('version') || data['version'] != 1) {
        _printError('Invalid import file format (unsupported version)');
        return;
      }

      final entries = data['entries'] as Map<String, dynamic>? ?? {};
      if (entries.isEmpty) {
        _printInfo('No entries to import.');
        return;
      }

      final outputFile = File('$boxName.hive');
      final bytes = _encodeBoxEntries(entries);
      await outputFile.writeAsBytes(bytes);

      _printSuccess('Imported ${entries.length} entries to $boxName');
    } catch (e) {
      _printError('Import failed: $e');
    }
  }

  /// Migrates the database at [path] to [targetVersion].
  static Future<void> migrate(String path, int targetVersion) async {
    _printHeader('Rift Schema Migration');

    final dir = Directory(path);
    if (!await dir.exists()) {
      _printError('Directory does not exist: $path');
      return;
    }

    _printInfo('Target version: $targetVersion');

    final versionFile = File(
      '${dir.path}${Platform.pathSeparator}__rift_schema__.hive',
    );

    int currentVersion = 0;
    if (await versionFile.exists()) {
      try {
        final bytes = await versionFile.readAsBytes();
        final data = _parseBoxEntries(bytes);
        final versionStr = data['schema_version']?.toString();
        if (versionStr != null) currentVersion = int.parse(versionStr);
      } catch (_) {
        _printInfo('Could not read current schema version, assuming 0.');
      }
    }

    _printField('Current version', currentVersion.toString());
    _printField('Target version', targetVersion.toString());

    if (currentVersion == targetVersion) {
      _printSuccess(
        'Database is already at version $targetVersion. No migration needed.',
      );
      return;
    }

    if (currentVersion > targetVersion) {
      _printError(
        'Current version ($currentVersion) is higher than target '
        'version ($targetVersion). Downgrade is not supported.',
      );
      return;
    }

    for (int v = currentVersion + 1; v <= targetVersion; v++) {
      _printInfo('Applying migration step: v${v - 1} → v$v');
      await _applyMigrationStep(dir, v);
      _printSuccess('  Step v$v applied successfully.');
    }

    final versionEntries = {'schema_version': targetVersion.toString()};
    final versionBytes = _encodeBoxEntries(versionEntries);
    await versionFile.writeAsBytes(versionBytes);

    _printSuccess('Migration complete: v$currentVersion → v$targetVersion');
  }

  /// Validates the database at [path] for integrity issues.
  static Future<List<String>> validate(String path) async {
    _printHeader('Rift Database Validation');

    final dir = Directory(path);
    if (!await dir.exists()) {
      _printError('Directory does not exist: $path');
      return ['Directory does not exist: $path'];
    }

    final issues = <String>[];

    try {
      final files = await dir.list().toList();
      final boxFiles = <File>[];

      for (final file in files) {
        if (file is File) {
          final name = file.path.split(Platform.pathSeparator).last;
          if (name.endsWith('.hive') || name.endsWith('.rift')) {
            boxFiles.add(file);
          }
        }
      }

      _printInfo('Validating ${boxFiles.length} box file(s)...');
      stdout.writeln();

      for (final file in boxFiles) {
        final name = file.path.split(Platform.pathSeparator).last;
        final boxIssues = <String>[];

        final size = await file.length();
        if (size == 0) boxIssues.add('File is empty (0 bytes)');

        try {
          final bytes = await _readFileHeader(file);
          if (bytes == null || bytes.length < 4) {
            boxIssues.add('File too small to contain a valid header');
          } else if (!_validateHeader(bytes)) {
            boxIssues.add('Invalid file header (may be corrupt)');
          }
        } catch (e) {
          boxIssues.add('Cannot read file header: $e');
        }

        if (size > 1024 * 1024 * 1024) {
          boxIssues.add('File is very large (>1GB), may indicate corruption');
        }

        if (boxIssues.isEmpty) {
          _printSuccess('  ✓ $name — OK');
        } else {
          _printError('  ✗ $name — ${boxIssues.length} issue(s):');
          for (final issue in boxIssues) {
            _printError('    - $issue');
          }
          issues.addAll(boxIssues.map((i) => '$name: $i'));
        }
      }

      final walFile = File('${dir.path}${Platform.pathSeparator}rift.wal');
      if (await walFile.exists()) {
        final walSize = await walFile.length();
        if (walSize > 10 * 1024 * 1024) {
          _printError(
            '  ✗ WAL file is large (${_formatBytes(walSize)}), may need checkpoint',
          );
          issues.add('WAL file is large: ${_formatBytes(walSize)}');
        } else {
          _printInfo('  ℹ WAL file present (${_formatBytes(walSize)})');
        }
      }

      stdout.writeln();
      if (issues.isEmpty) {
        _printSuccess('All checks passed. Database is valid.');
      } else {
        _printError('Found ${issues.length} issue(s). See above for details.');
      }
    } catch (e) {
      _printError('Validation failed: $e');
      issues.add('Validation error: $e');
    }

    return issues;
  }

  /// Shows statistics about the database at [path].
  static Future<void> stats(String path) async {
    _printHeader('Rift Database Statistics');

    final dir = Directory(path);
    if (!await dir.exists()) {
      _printError('Directory does not exist: $path');
      return;
    }

    final files = await dir.list().toList();
    final boxFiles = <File>[];
    var totalSize = 0;

    for (final file in files) {
      if (file is File) {
        final name = file.path.split(Platform.pathSeparator).last;
        if (name.endsWith('.hive') || name.endsWith('.rift')) {
          boxFiles.add(file);
          totalSize += await file.length();
        } else if (name == 'rift.wal') {
          totalSize += await file.length();
        }
      }
    }

    _printField('Total boxes', boxFiles.length.toString());
    _printField('Total size', _formatBytes(totalSize));
    stdout.writeln();

    if (boxFiles.isEmpty) {
      _printInfo('No box files found.');
      return;
    }

    _printInfo('Per-box breakdown:');
    stdout.writeln();

    stdout.writeln(
      '  ${"Box Name".padRight(30)} ${"Entries".padLeft(10)} ${"Size".padLeft(12)}',
    );
    stdout.writeln(
      '  ${"".padRight(30, "─")} ${"".padLeft(10, "─")} ${"".padLeft(12, "─")}',
    );

    for (final file in boxFiles) {
      final name = file.path.split(Platform.pathSeparator).last;
      final boxName = name.replaceAll(RegExp(r'\.(hive|rift)$'), '');
      final size = await file.length();

      int entryCount = 0;
      try {
        final bytes = await file.readAsBytes();
        final entries = _parseBoxEntries(bytes);
        entryCount = entries.length;
      } catch (_) {
        entryCount = -1;
      }

      final countStr = entryCount >= 0 ? entryCount.toString() : '?';
      stdout.writeln(
        '  ${boxName.padRight(30)} ${countStr.padLeft(10)} ${_formatBytes(size).padLeft(12)}',
      );
    }

    stdout.writeln();

    final walFile = File('${dir.path}${Platform.pathSeparator}rift.wal');
    if (await walFile.exists()) {
      final walSize = await walFile.length();
      _printField('WAL size', _formatBytes(walSize));
    } else {
      _printField('WAL', 'none');
    }

    final diskUsage = await _getDiskUsage(dir);
    _printField('Disk usage', _formatBytes(diskUsage));
  }

  // ─── Helper Methods ──────────────────────────────────────────────

  static Future<void> _applyMigrationStep(Directory dir, int version) async {
    final markerFile = File(
      '${dir.path}${Platform.pathSeparator}.migration_v$version',
    );
    await markerFile.writeAsString(
      'Migrated to version $version at ${DateTime.now().toIso8601String()}\n',
    );
  }

  static Future<Uint8List?> _readFileHeader(File file) async {
    if (!await file.exists()) return null;
    final stream = file.openRead(0, 64);
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
      if (chunks.length >= 64) break;
    }
    return Uint8List.fromList(chunks);
  }

  static bool _validateHeader(List<int> bytes) {
    if (bytes.length < 4) return false;
    final firstByte = bytes[0];
    if (firstByte <= 0x01) return true;
    if (firstByte >= 0x20 && firstByte <= 0x7E) return true;
    return false;
  }

  static Map<String, dynamic> _parseBoxEntries(List<int> bytes) {
    if (bytes.isEmpty) return {};

    try {
      final str = String.fromCharCodes(
        bytes.where((b) => b >= 0x20 && b <= 0x7E),
      );
      if (str.startsWith('{') || str.startsWith('[')) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (_) {
      // Not JSON, try binary parsing
    }

    final entries = <String, dynamic>{};
    final buffer = StringBuffer();
    String? currentKey;

    for (int i = 0; i < bytes.length; i++) {
      final byte = bytes[i];
      if (byte >= 0x20 && byte <= 0x7E) {
        buffer.writeCharCode(byte);
      } else {
        final token = buffer.toString();
        buffer.clear();
        if (token.isNotEmpty) {
          if (currentKey == null) {
            currentKey = token;
          } else {
            entries[currentKey] = token;
            currentKey = null;
          }
        }
      }
    }

    return entries;
  }

  static Uint8List _encodeBoxEntries(Map<String, dynamic> entries) {
    final jsonStr = jsonEncode(entries);
    return Uint8List.fromList(jsonStr.codeUnits);
  }

  static Future<int> _getDiskUsage(Directory dir) async {
    var totalSize = 0;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) totalSize += await entity.length();
      }
    } catch (_) {}
    return totalSize;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // ─── Output Helpers ──────────────────────────────────────────────

  static void _printUsage() {
    stdout.writeln(
      '$_cyan Rift CLI — Database inspection and management $_reset',
    );
    stdout.writeln();
    stdout.writeln('Usage: dart run rift <command> [options]');
    stdout.writeln();
    stdout.writeln('Commands:');
    stdout.writeln(
      '  inspect <path>                Inspect database structure',
    );
    stdout.writeln('  export <boxName> <outputPath> Export a box to JSON');
    stdout.writeln('  import <boxName> <inputPath>  Import a box from JSON');
    stdout.writeln('  migrate <path> <version>      Migrate schema version');
    stdout.writeln(
      '  validate <path>               Validate database integrity',
    );
    stdout.writeln('  stats <path>                  Show database statistics');
    stdout.writeln('  help                          Show this help message');
  }

  static void _printHeader(String text) {
    stdout.writeln();
    stdout.writeln('$_cyan═══ $text ═══$_reset');
    stdout.writeln();
  }

  static void _printInfo(String text) => stdout.writeln('  ℹ $text');
  static void _printSuccess(String text) =>
      stdout.writeln('$_green  ✓ $text$_reset');
  static void _printError(String text) =>
      stderr.writeln('$_red  ✗ $text$_reset');
  static void _printField(String label, String value) =>
      stdout.writeln('  ${label.padRight(16)} $value');
}
