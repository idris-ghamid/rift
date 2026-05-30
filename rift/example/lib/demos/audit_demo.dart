import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class AuditDemoPage extends StatelessWidget {
  const AuditDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Audit Log',
      description: 'Audit trail for all database operations',
      codeExample:
          "final audit = AuditLog();\naudit.log(AuditAction.create, 'users', key: 'u1', newValue: data);\naudit.getEntries(action: AuditAction.create);",
      runDemo: () async {
        final audit = AuditLog();
        final buf = StringBuffer();
        buf.writeln('=== Audit Log Demo ===\n');

        // Log operations
        audit.log(AuditAction.create, 'users',
            key: 'u1', newValue: {'name': 'Alice'});
        audit.log(AuditAction.read, 'users', key: 'u1');
        audit.log(AuditAction.update, 'users',
            key: 'u1',
            oldValue: {'name': 'Alice'},
            newValue: {'name': 'Alice S.'});
        audit.log(AuditAction.create, 'users',
            key: 'u2', newValue: {'name': 'Bob'});
        audit.log(AuditAction.delete, 'users',
            key: 'u2', oldValue: {'name': 'Bob'});
        audit.log(AuditAction.clear, 'users');
        buf.writeln('Logged 6 audit entries\n');

        // Get all entries
        buf.writeln('--- All Entries ---');
        for (final e in audit.getEntries()) {
          buf.writeln('  $e');
        }

        // Filter by action
        buf.writeln('\n--- Create Actions Only ---');
        for (final e in audit.getEntries(action: AuditAction.create)) {
          buf.writeln('  #${e.id} ${e.key}: ${e.newValue}');
        }

        // Filter by key
        buf.writeln('\n--- Entries for u1 ---');
        for (final e in audit.getEntriesForKey('users', 'u1')) {
          buf.writeln(
              '  #${e.id} ${e.action} at ${e.timestamp.toIso8601String()}');
        }

        // Latest
        buf.writeln('\n--- Latest Entry ---');
        buf.writeln('  ${audit.getLatest()}');

        // Export JSON
        buf.writeln('\n--- Export JSON ---');
        final json = audit.exportJson();
        buf.writeln('  ${json.length} entries exported');
        buf.writeln('  First: ${json.first}');

        buf.writeln('\n--- Stats ---');
        buf.writeln('  Total entries: ${audit.length}');

        audit.dispose();
        return buf.toString();
      },
    );
  }
}
