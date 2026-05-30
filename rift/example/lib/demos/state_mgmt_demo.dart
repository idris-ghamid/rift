import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class StateMgmtDemoPage extends StatelessWidget {
  const StateMgmtDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'State Management',
      description: 'State management integration with Riverpod and Bloc',
      codeExample:
          "// Riverpod\nfinal config = RiftBoxProviderConfig<T>(boxName: 'users');\nfinal stream = RiftRiverpodHelper.watchKey<T>(box, 'key');\n\n// Bloc/Cubit\nfinal cubit = RiftBoxCubit<T>(box);\ncubit.stream.listen((state) => print(state));",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== State Management Integration Demo ===\n');

        // RiftBoxProviderConfig
        buf.writeln('--- RiftBoxProviderConfig (Riverpod) ---');
        final config = RiftBoxProviderConfig<Map>(
          boxName: 'state_demo',
          defaultValue: {'theme': 'light'},
          keepAlive: true,
        );
        buf.writeln('  boxName: ${config.boxName}');
        buf.writeln('  defaultValue: ${config.defaultValue}');
        buf.writeln('  keepAlive: ${config.keepAlive}');
        buf.writeln('  Use this config to create Riverpod NotifierProviders');

        // RiftRiverpodHelper
        buf.writeln('\n--- RiftRiverpodHelper (Riverpod) ---');
        final box = await Rift.openBox<Map>('state_demo');
        await box.clear();

        await box.put('settings', {'theme': 'dark', 'lang': 'en'});
        buf.writeln('  boxToState: ${RiftRiverpodHelper.boxToState(box)}');

        buf.writeln('\n  Helper methods:');
        buf.writeln('    watchKey<T>(box, key) → Stream<T>');
        buf.writeln('    watchAll(box) → Stream<Map>');
        buf.writeln(
            '    watchKeyWithDefault<T>(box, key, defaultValue) → Stream<T>');

        // RiftBoxCubit
        buf.writeln('\n--- RiftBoxCubit (Bloc Integration) ---');
        final cubit = RiftBoxCubit<Map>(box);
        final changeEvents = <String>[];
        final cubitSub = cubit.stream.listen((state) {
          changeEvents.add('$state');
        });

        buf.writeln('  Created RiftBoxCubit');
        buf.writeln('  Current state: ${cubit.state}');
        buf.writeln('  State length: ${cubit.length}');
        buf.writeln('  Keys: ${cubit.keys.toList()}');
        buf.writeln(
            '  containsKey("settings"): ${cubit.containsKey("settings")}');

        // Cubit put
        buf.writeln('\n--- Cubit: Put Operation ---');
        await cubit.put('theme', {'mode': 'dark', 'accent': 'teal'});
        buf.writeln('  put("theme", {...}) → state updated');
        buf.writeln('  State: ${cubit.state}');

        // Cubit get
        buf.writeln('\n--- Cubit: Get Operation ---');
        final theme = cubit.get('theme');
        buf.writeln('  get("theme"): $theme');

        // Cubit put more data
        buf.writeln('\n--- Cubit: More Puts ---');
        await cubit.put('user', {'name': 'Alice', 'role': 'admin'});
        await cubit.put('notifications', {'enabled': true, 'sound': false});
        buf.writeln('  Put 2 more entries');
        buf.writeln('  State length: ${cubit.length}');

        // Cubit delete
        buf.writeln('\n--- Cubit: Delete Operation ---');
        await cubit.delete('notifications');
        buf.writeln('  delete("notifications")');
        buf.writeln('  State length: ${cubit.length}');

        // Cubit keys
        buf.writeln('\n--- Cubit: Final State ---');
        buf.writeln('  Keys: ${cubit.keys.toList()}');
        buf.writeln('  Full state: ${cubit.state}');

        buf.writeln('\n  Stream changes captured: ${changeEvents.length}');

        // Integration patterns
        buf.writeln('\n--- Integration Patterns ---');
        buf.writeln('');
        buf.writeln('  Riverpod Pattern:');
        buf.writeln(
            '    final config = RiftBoxProviderConfig<T>(boxName: ...);');
        buf.writeln(
            '    final stream = RiftRiverpodHelper.watchKey(box, key);');
        buf.writeln('    // Use with StreamNotifier / AsyncNotifier');
        buf.writeln('');
        buf.writeln('  Bloc/Cubit Pattern:');
        buf.writeln('    final cubit = RiftBoxCubit<T>(box);');
        buf.writeln('    cubit.stream.listen((state) => ...);');
        buf.writeln('    await cubit.put(key, value);');
        buf.writeln('    await cubit.delete(key);');

        buf.writeln('\n✅ State management demo complete');

        await cubitSub.cancel();
        cubit.dispose();

        return buf.toString();
      },
    );
  }
}
