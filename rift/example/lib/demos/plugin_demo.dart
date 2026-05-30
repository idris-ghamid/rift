import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class PluginDemoPage extends StatelessWidget {
  const PluginDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Plugins',
      description: 'Plugin architecture for extending Rift',
      codeExample:
          "class MyPlugin extends RiftPlugin { ... }\nawait pluginManager.register(myPlugin);\npluginManager.notifyBefore(RiftOperation(...));",
      runDemo: () async {
        final pluginManager = RiftPluginManager();
        final buf = StringBuffer();
        buf.writeln('=== Plugin Architecture Demo ===\n');

        // Create a custom plugin
        final statsPlugin = _StatsPlugin();
        buf.writeln('--- Register Stats Plugin ---');
        pluginManager.register(statsPlugin, config: {'logOps': true});
        buf.writeln('  Registered: ${statsPlugin.id}');
        buf.writeln('  Plugin count: ${pluginManager.pluginCount}');

        // Create another plugin
        final timestampPlugin = _TimestampPlugin();
        pluginManager.register(timestampPlugin);
        buf.writeln('  Registered: ${timestampPlugin.id}');
        buf.writeln('  Plugin count: ${pluginManager.pluginCount}');

        // Notify plugins
        buf.writeln('\n--- Notify Before Operation ---');
        pluginManager.notifyBefore(RiftOperation(
          boxName: 'users',
          type: 'put',
          key: 'u1',
          value: {'name': 'Alice'},
        ));

        buf.writeln('\n--- Notify After Operation ---');
        pluginManager.notifyAfter(
            RiftOperation(
              boxName: 'users',
              type: 'put',
              key: 'u1',
              value: {'name': 'Alice'},
            ),
            {'success': true});

        // Check plugin state
        buf.writeln('\n--- Plugin State ---');
        final ctx = pluginManager.getContext(statsPlugin.id);
        buf.writeln(
            '  Stats plugin ops: ${ctx?.getState<int>('opCount') ?? 0}');
        buf.writeln(
            '  Stats plugin puts: ${ctx?.getState<int>('putCount') ?? 0}');

        buf.writeln('\n--- Registered Plugins ---');
        for (final p in pluginManager.plugins) {
          buf.writeln('  ${p.id}: ${p.name} v${p.version}');
        }

        // Unregister
        buf.writeln('\n--- Unregister Timestamp Plugin ---');
        pluginManager.unregister(timestampPlugin.id);
        buf.writeln('  Plugin count: ${pluginManager.pluginCount}');

        buf.writeln('\n✅ Plugin architecture is extensible');

        return buf.toString();
      },
    );
  }
}

class _StatsPlugin extends RiftPlugin {
  @override
  String get id => 'stats_plugin';
  @override
  String get name => 'Statistics Plugin';
  @override
  String get version => '1.0.0';

  @override
  Future<void> onRegister(RiftPluginContext context) async {
    context.setState('opCount', 0);
    context.setState('putCount', 0);
  }

  @override
  void beforeOperation(RiftOperation operation) {
    // Access context through manager (simplified)
  }

  @override
  void afterOperation(RiftOperation operation, dynamic result) {}
}

class _TimestampPlugin extends RiftPlugin {
  @override
  String get id => 'timestamp_plugin';
  @override
  String get name => 'Timestamp Plugin';
  @override
  String get version => '1.0.0';

  @override
  Future<void> onRegister(RiftPluginContext context) async {}

  @override
  void beforeOperation(RiftOperation operation) {
    // Add timestamp to metadata
  }

  @override
  void afterOperation(RiftOperation operation, dynamic result) {}
}
