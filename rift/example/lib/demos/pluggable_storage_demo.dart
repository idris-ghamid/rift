import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class PluggableStorageDemoPage extends StatelessWidget {
  const PluggableStorageDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Pluggable Storage',
      description: 'Pluggable storage engine with swappable backend interface',
      codeExample:
          "abstract class StorageBackend {\n  Future<void> writeFrames(List<Frame> frames);\n  Future<dynamic> readValue(Frame frame);\n  Future<void> compact(Iterable<Frame> frames);\n}\n\n// Custom: implement StorageBackend\n// Auto-selected via conditional imports",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Pluggable Storage Engine Demo ===\n');

        // StorageBackend interface
        buf.writeln('--- StorageBackend Interface ---');
        buf.writeln('  abstract class StorageBackend {');
        buf.writeln('    String? get path;');
        buf.writeln('    bool get supportsCompaction;');
        buf.writeln('    Future<void> initialize(registry, keystore, lazy);');
        buf.writeln('    Future<dynamic> readValue(Frame frame);');
        buf.writeln('    Future<void> writeFrames(List<Frame> frames);');
        buf.writeln('    Future<void> compact(Iterable<Frame> frames);');
        buf.writeln('    Future<void> clear();');
        buf.writeln('    Future<void> close();');
        buf.writeln('    Future<void> deleteFromDisk();');
        buf.writeln('    Future<void> flush();');
        buf.writeln('  }');

        // BackendManagerInterface
        buf.writeln('\n--- BackendManagerInterface ---');
        buf.writeln('  abstract class BackendManagerInterface {');
        buf.writeln(
            '    Future<StorageBackend> open(name, path, crashRecovery, ...);');
        buf.writeln('    Future<void> deleteBox(name, path, collection);');
        buf.writeln('    Future<bool> boxExists(name, path, collection);');
        buf.writeln('  }');

        // Available backends
        buf.writeln('\n--- Available Backend Implementations ---');
        buf.writeln('');
        buf.writeln('  ┌─────────────────┬──────────────────────────────────┐');
        buf.writeln(
            '  │ Backend          │ Platform                         │');
        buf.writeln('  ├─────────────────┼──────────────────────────────────┤');
        buf.writeln(
            '  │ VM Backend       │ Dart VM (mobile, desktop, server) │');
        buf.writeln(
            '  │ JS Backend       │ Web (IndexedDB / OPFS)           │');
        buf.writeln(
            '  │ Memory Backend   │ Testing / In-memory only         │');
        buf.writeln(
            '  │ Custom Backend   │ User-implemented                 │');
        buf.writeln('  └─────────────────┴──────────────────────────────────┘');

        // Demonstrate in-memory backend
        buf.writeln('\n--- Memory Backend Demo ---');
        final box = await Rift.openBox<Map>('pluggable_demo');
        await box.clear();
        await box.put('key1', {'backend': 'auto-selected', 'fast': true});
        await box.put('key2', {'backend': 'auto-selected', 'reliable': true});
        buf.writeln('  Opened box with auto-selected backend');
        buf.writeln('  key1: ${box.get('key1')}');
        buf.writeln('  key2: ${box.get('key2')}');
        buf.writeln('  Box path: ${box.path}');

        // Backend preference
        buf.writeln('\n--- Backend Preference ---');
        buf.writeln('  RiftStorageBackendPreference.native:');
        buf.writeln('    → VM on native, OPFS on web');
        buf.writeln('  RiftStorageBackendPreference.indexedDb:');
        buf.writeln('    → Force IndexedDB on web (fallback)');

        // Demonstrate custom backend concept
        buf.writeln('\n--- Custom Backend Concept ---');
        buf.writeln('  To create a custom backend:');
        buf.writeln('  1. Implement StorageBackend abstract class');
        buf.writeln('  2. Implement BackendManagerInterface');
        buf.writeln('  3. Handle read/write/compact operations');
        buf.writeln('  4. Register via conditional import or DI');

        buf.writeln('\n--- Custom Backend Skeleton ---');
        buf.writeln('  class MyCustomBackend implements StorageBackend {');
        buf.writeln('    @override String? get path => _path;');
        buf.writeln('    @override bool get supportsCompaction => true;');
        buf.writeln('    @override Future<void> initialize(...) { }');
        buf.writeln('    @override Future<dynamic> readValue(frame) { }');
        buf.writeln('    @override Future<void> writeFrames(frames) { }');
        buf.writeln('    @override Future<void> compact(frames) { }');
        buf.writeln('    // ... other methods');
        buf.writeln('  }');

        // Conditional imports explanation
        buf.writeln('\n--- Conditional Import Strategy ---');
        buf.writeln("  export 'stub/backend_manager.dart'");
        buf.writeln("    if (dart.library.io) 'vm/backend_manager.dart'");
        buf.writeln(
            "    if (dart.library.js_interop) 'js/backend_manager.dart';");
        buf.writeln(
            '  This pattern selects the correct backend at compile time');

        await box.close();

        buf.writeln('\n✅ Pluggable storage demo complete');

        return buf.toString();
      },
    );
  }
}
