import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class DiffpatchDemoPage extends StatelessWidget {
  const DiffpatchDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Data Diff & Patch',
      description: 'Compute diffs and apply RFC 6902 JSON Patches',
      codeExample:
          "final differ = DataDiffer();\nfinal patch = differ.diff(from, to);\nfinal result = patch.apply(from);\nfinal reversed = patch.reverse();",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Data Diff & Patch Demo ===\n');

        final differ = DataDiffer();

        // Compare two states
        final from = {'name': 'Idris', 'age': 25, 'city': 'Cairo'};
        final to = {
          'name': 'Ahmed',
          'age': 25,
          'city': 'Cairo',
          'country': 'Egypt'
        };

        buf.writeln('--- Compute Diff ---');
        buf.writeln('  From: $from');
        buf.writeln('  To:   $to');

        final patch = differ.diff(from, to);
        buf.writeln('  Operations: ${patch.length}');
        for (final op in patch.operations) {
          buf.writeln(
              '    ${op.type.name} ${op.path}${op.value != null ? ' = ${op.value}' : ''}');
        }

        // RFC 6902 JSON format
        buf.writeln('\n--- RFC 6902 JSON Patch ---');
        final json = patch.toJson();
        for (final op in json) {
          buf.writeln('  $op');
        }

        // Apply patch
        buf.writeln('\n--- Apply Patch ---');
        final result = patch.apply(from);
        buf.writeln('  Result: $result');
        buf.writeln('  Matches target: ${result.toString() == to.toString()}');

        // Reverse patch
        buf.writeln('\n--- Reverse Patch ---');
        final reversed = patch.reverse();
        final reversedResult = reversed.apply(result);
        buf.writeln('  Reversed result: $reversedResult');
        buf.writeln(
            '  Back to original: ${reversedResult.toString() == from.toString()}');

        // Changed paths
        buf.writeln('\n--- Changed Paths ---');
        final paths = differ.changedPaths(from, to);
        buf.writeln('  $paths');

        // Nested diff
        buf.writeln('\n--- Nested Diff ---');
        final nestedFrom = {
          'user': {
            'name': 'Idris',
            'settings': {'theme': 'dark'}
          },
        };
        final nestedTo = {
          'user': {
            'name': 'Ahmed',
            'settings': {'theme': 'light', 'lang': 'ar'}
          },
        };
        final nestedPatch = differ.diff(nestedFrom, nestedTo);
        for (final op in nestedPatch.operations) {
          buf.writeln(
              '  ${op.type.name} ${op.path}${op.value != null ? ' = ${op.value}' : ''}');
        }

        // Test operation
        buf.writeln('\n--- Test Operation ---');
        final testPatch = DataPatch([
          PatchOperation.replace('/name', 'Ahmed'),
          PatchOperation.test('/name', 'Ahmed'),
        ]);
        try {
          final testResult = testPatch.apply({'name': 'Idris'});
          buf.writeln('  Test passed: $testResult');
        } on PatchException catch (e) {
          buf.writeln('  Test failed: $e');
        }

        // Manual patch construction
        buf.writeln('\n--- Manual Patch Construction ---');
        final manualPatch = DataPatch([
          PatchOperation.add('/status', 'active'),
          PatchOperation.remove('/temp'),
          PatchOperation.move('/old_key', '/new_key'),
          PatchOperation.copy('/name', '/display_name'),
        ]);
        buf.writeln('  Operations: ${manualPatch.length}');
        for (final op in manualPatch.operations) {
          buf.writeln(
              '    ${op.type.name} ${op.path}${op.from != null ? ' from ${op.from}' : ''}${op.value != null ? ' = ${op.value}' : ''}');
        }

        return buf.toString();
      },
    );
  }
}
