import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class VersioningDemoPage extends StatelessWidget {
  const VersioningDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Data Versioning',
      description: 'Entry version tracking with rollback support',
      codeExample:
          "final vm = VersionManager(retention: 10);\nvm.recordVersion('users', 'u1', data);\nawait vm.rollback('users', 'u1', 2);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Data Versioning Demo ===\n');

        final vm = VersionManager(retention: 10);

        // Record versions
        vm.recordVersion(
            'users', 'u1', {'name': 'Idris', 'age': 25, 'city': 'Cairo'},
            description: 'Initial create');
        vm.recordVersion(
            'users', 'u1', {'name': 'Idris', 'age': 26, 'city': 'Cairo'},
            description: 'Birthday');
        vm.recordVersion(
            'users', 'u1', {'name': 'Idris', 'age': 26, 'city': 'Dubai'},
            description: 'Moved city');
        vm.recordVersion(
            'users', 'u1', {'name': 'Ahmed', 'age': 26, 'city': 'Dubai'},
            description: 'Name change');

        // Version history
        buf.writeln('--- Version History ---');
        final history = vm.getHistory('users', 'u1');
        for (final v in history) {
          buf.writeln('  v${v.version}: ${v.value} (${v.description})');
        }

        // Current version
        buf.writeln('\n--- Current State ---');
        buf.writeln(
            '  Current version: ${vm.getCurrentVersion('users', 'u1')}');
        buf.writeln('  Latest value: ${vm.getLatestValue('users', 'u1')}');

        // Diff between versions
        buf.writeln('\n--- Diff v1 → v4 ---');
        final diff = vm.diff('users', 'u1', 1, 4);
        if (diff != null) {
          buf.writeln('  $diff');
          buf.writeln('  Added: ${diff.addedFields}');
          buf.writeln('  Removed: ${diff.removedFields}');
          buf.writeln('  Modified old: ${diff.modifiedFieldsOld}');
          buf.writeln('  Modified new: ${diff.modifiedFieldsNew}');
        }

        // Rollback to v2
        buf.writeln('\n--- Rollback to v2 ---');
        final rolledBack = await vm.rollback('users', 'u1', 2);
        buf.writeln('  Restored value: $rolledBack');

        // History after rollback
        buf.writeln('\n--- History After Rollback ---');
        final newHistory = vm.getHistory('users', 'u1');
        for (final v in newHistory) {
          buf.writeln('  v${v.version}: ${v.value} (${v.description ?? ''})');
        }

        buf.writeln('\n--- Stats ---');
        buf.writeln('  Total versions tracked: ${vm.totalVersions}');
        buf.writeln('  Boxes with history: ${vm.boxNames.toList()}');

        return buf.toString();
      },
    );
  }
}
