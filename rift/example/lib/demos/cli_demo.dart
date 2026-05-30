import 'package:flutter/material.dart';
import '../widgets/demo_page.dart';

class CliDemoPage extends StatelessWidget {
  const CliDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'CLI Tools',
      description: 'CLI tools for database inspection and management',
      codeExample:
          "await RiftCLI.run(['inspect', '/path/to/db']);\nawait RiftCLI.run(['stats', '/path/to/db']);\nawait RiftCLI.run(['validate', '/path/to/db']);\nawait RiftCLI.run(['export', 'boxName', 'out.json']);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== CLI Tools Demo ===\n');

        buf.writeln('--- inspect ---');
        buf.writeln('RiftCLI.run(["inspect", "/path/to/db"])');
        buf.writeln('''═══ Rift Database Inspection ═══

  ℹ Path: /app/data/rift

  ℹ Found 3 box file(s):

  Box              users.rift
  File             users.rift
  Size             4.2 KB
  Valid            ✓ yes

  Box              settings.rift
  File             settings.rift
  Size             1.1 KB
  Valid            ✓ yes

  Box              cache.rift
  File             cache.rift
  Size             128 B
  Valid            ✓ yes

WAL File          none''');

        buf.writeln('\n--- stats ---');
        buf.writeln('RiftCLI.run(["stats", "/path/to/db"])');
        buf.writeln('''═══ Rift Database Statistics ═══

  Total boxes          3
  Total size           5.5 KB

  Per-box breakdown:

  Box Name                         Entries         Size
  ──────────────────────────────── ────────── ────────────
  users                                   15       4.2 KB
  settings                                 5       1.1 KB
  cache                                    3        128 B

  WAL                none
  Disk usage         5.5 KB''');

        buf.writeln('\n--- export ---');
        buf.writeln('RiftCLI.run(["export", "users", "users_backup.json"])');
        buf.writeln('''═══ Rift Data Export ═══

  ✓ Exported 15 entries to users_backup.json
  ℹ File size: 2.8 KB''');

        buf.writeln('\n--- import ---');
        buf.writeln('RiftCLI.run(["import", "users", "users_backup.json"])');
        buf.writeln('''═══ Rift Data Import ═══

  ✓ Imported 15 entries to users''');

        buf.writeln('\n--- validate ---');
        buf.writeln('RiftCLI.run(["validate", "/path/to/db"])');
        buf.writeln('''═══ Rift Database Validation ═══

  ℹ Validating 3 box file(s)...

  ✓ users.rift — OK
  ✓ settings.rift — OK
  ✗ cache.rift — 1 issue(s):
    - File is empty (0 bytes)

  ℹ WAL file present (256 B)

  ✗ Found 1 issue(s). See above for details.''');

        buf.writeln('\n--- migrate ---');
        buf.writeln('RiftCLI.run(["migrate", "/path/to/db", "2"])');
        buf.writeln('''═══ Rift Schema Migration ═══

  ℹ Target version: 2
  Current version   1
  Target version    2
  ℹ Applying migration step: v1 → v2
  ✓   Step v2 applied successfully.
  ✓ Migration complete: v1 → v2''');

        return buf.toString();
      },
    );
  }
}
