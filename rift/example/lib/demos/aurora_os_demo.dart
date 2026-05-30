import 'package:flutter/material.dart';
import '../widgets/demo_page.dart';

class AuroraOsDemoPage extends StatelessWidget {
  const AuroraOsDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Aurora OS Support',
      description: 'Aurora OS support via federated plugin architecture',
      codeExample:
          "// Same API on all platforms including Aurora OS\nawait Rift.init('/path/to/data');\nfinal box = await Rift.openBox<Map>('settings');",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Aurora OS Support ===\n');

        buf.writeln('Aurora OS is a Russian mobile operating system based on');
        buf.writeln(
            'Linux/Sailfish OS, used in government and enterprise sectors.\n');

        buf.writeln('--- Federated Plugin Architecture ---\n');

        buf.writeln(
            'Rift supports Aurora OS through the federated plugin pattern,');
        buf.writeln(
            'the same architecture used by Flutter for platform plugins.\n');

        buf.writeln('┌──────────────────────────────────────┐');
        buf.writeln('│        rift_flutter (App layer)       │');
        buf.writeln('│   Common Dart API — Rift.openBox()    │');
        buf.writeln('└──────────────┬───────────────────────┘');
        buf.writeln('               │');
        buf.writeln('┌──────────────▼───────────────────────┐');
        buf.writeln('│    rift_flutter_platform_interface    │');
        buf.writeln('│   Abstract platform interface         │');
        buf.writeln('└──────────────┬───────────────────────┘');
        buf.writeln('        ┌──────┼──────────┬──────────┐');
        buf.writeln('  ┌─────▼───┐ ┌▼────────┐ ┌▼────────┐');
        buf.writeln('  │ Android │ │  iOS    │ │ Aurora  │');
        buf.writeln('  │  impl   │ │  impl   │ │  impl   │');
        buf.writeln('  └─────────┘ └─────────┘ └─────────┘');
        buf.writeln('');

        buf.writeln('--- How Aurora OS Support Works ---\n');

        buf.writeln('1. rift_flutter');
        buf.writeln('   The main package that users import.');
        buf.writeln('   Provides the Dart API (Rift.openBox, etc.)');
        buf.writeln('   Delegates to platform-specific implementations.\n');

        buf.writeln('2. rift_flutter_platform_interface');
        buf.writeln('   Defines the abstract interface that all platforms');
        buf.writeln('   must implement. Ensures consistent behavior.\n');

        buf.writeln('3. rift_flutter_aurora');
        buf.writeln('   The Aurora OS-specific implementation.');
        buf.writeln('   Uses Aurora OS APIs for file I/O and storage.');
        buf.writeln('   Handles sandbox paths and permissions.\n');

        buf.writeln('--- Platform Detection ---\n');
        buf.writeln('Rift automatically selects the correct backend:');
        buf.writeln('  • Android → StorageBackendVm (Dart VM + file I/O)');
        buf.writeln('  • iOS     → StorageBackendVm (Dart VM + file I/O)');
        buf.writeln('  • macOS   → StorageBackendVm (Dart VM + file I/O)');
        buf.writeln('  • Windows → StorageBackendVm (Dart VM + file I/O)');
        buf.writeln('  • Linux   → StorageBackendVm (Dart VM + file I/O)');
        buf.writeln('  • Aurora  → StorageBackendVm (Aurora-specific paths)');
        buf.writeln('  • Web     → StorageBackendJs (IndexedDB)');
        buf.writeln('');

        buf.writeln('--- Aurora OS Specifics ---\n');
        buf.writeln('• File paths use Aurora OS sandbox conventions');
        buf.writeln('• Data is stored in the app\'s private sandbox');
        buf.writeln('• Path: /home/defaultuser/.local/share/<app_id>/');
        buf.writeln('• Encrypted storage available via Aurora security APIs');
        buf.writeln('• Works with Aurora CLI and SDK for building');
        buf.writeln('');

        buf.writeln('--- Using Rift on Aurora OS ---\n');
        buf.writeln('The API is identical to other platforms:');
        buf.writeln('');
        buf.writeln('  import \'package:rift/rift.dart\';');
        buf.writeln('');
        buf.writeln('  // Same code works on ALL platforms including Aurora');
        buf.writeln('  await Rift.init(\'/path/to/data\');');
        buf.writeln('  final box = await Rift.openBox<Map>(\'settings\');');
        buf.writeln('  await box.put(\'theme\', \'dark\');');
        buf.writeln('');

        buf.writeln('--- Build for Aurora OS ---\n');
        buf.writeln('  flutter build aurora');
        buf.writeln('  # Or with the Aurora SDK:');
        buf.writeln('  aurora-cli build --target aurora');
        buf.writeln('');

        buf.writeln('--- Summary ---');
        buf.writeln(
            '  ✅ Federated plugin = same Dart API, platform-specific impl');
        buf.writeln('  ✅ Aurora OS uses the VM backend with custom paths');
        buf.writeln('  ✅ No code changes needed — works out of the box');
        buf.writeln('  ✅ Full CRUD, encryption, and compaction support');

        return buf.toString();
      },
    );
  }
}
