import 'package:rift/src/rift_error.dart';

/// Plugin architecture for Rift.
/// Allows the community to build features on top of the library.

/// Abstract base class for Rift plugins.
abstract class RiftPlugin {
  /// Unique identifier for this plugin.
  String get id;

  /// Human-readable name.
  String get name;

  /// Plugin version.
  String get version;

  /// Called when the plugin is registered.
  Future<void> onRegister(RiftPluginContext context);

  /// Called before a box operation.
  void beforeOperation(RiftOperation operation) {}

  /// Called after a box operation.
  void afterOperation(RiftOperation operation, dynamic result) {}

  /// Called when the plugin is unregistered.
  Future<void> onUnregister() async {}
}

/// Represents a Rift database operation.
class RiftOperation {
  /// The name of the box this operation targets.
  final String boxName;

  /// The type of operation ('put', 'get', 'delete', 'clear', 'query', etc.).
  final String type;

  /// The key involved in the operation (null for box-level operations).
  final String? key;

  /// The value involved in the operation (null for reads and deletes).
  final dynamic value;

  /// Additional metadata about the operation.
  final Map<String, dynamic> metadata;

  /// When this operation occurred.
  final DateTime timestamp;

  /// Create a Rift operation.
  RiftOperation({
    required this.boxName,
    required this.type,
    this.key,
    this.value,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'RiftOperation($type, box: $boxName, key: $key, value: $value)';
}

/// Context provided to a plugin when it is registered.
class RiftPluginContext {
  /// Plugin-specific configuration.
  final Map<String, dynamic> config;

  /// Plugin-specific state (persists across operations).
  final Map<String, dynamic> state;

  /// Create a plugin context.
  RiftPluginContext(this.config) : state = {};

  /// Get a config value.
  T? getConfig<T>(String key) => config[key] as T?;

  /// Set a state value.
  void setState(String key, dynamic value) => state[key] = value;

  /// Get a state value.
  T? getState<T>(String key) => state[key] as T?;
}

/// Manages registered plugins and dispatches notifications.
class RiftPluginManager {
  final Map<String, RiftPlugin> _plugins = {};
  final Map<String, RiftPluginContext> _contexts = {};

  /// Register a plugin.
  /// Throws [RiftError] if a plugin with the same ID is already registered.
  Future<void> register(
    RiftPlugin plugin, {
    Map<String, dynamic>? config,
  }) async {
    if (_plugins.containsKey(plugin.id)) {
      throw RiftError('Plugin ${plugin.id} is already registered');
    }
    _plugins[plugin.id] = plugin;
    final context = RiftPluginContext(config ?? {});
    _contexts[plugin.id] = context;
    await plugin.onRegister(context);
  }

  /// Unregister a plugin by its ID.
  Future<void> unregister(String pluginId) async {
    final plugin = _plugins.remove(pluginId);
    if (plugin != null) {
      await plugin.onUnregister();
      _contexts.remove(pluginId);
    }
  }

  /// Notify all plugins before an operation.
  void notifyBefore(RiftOperation operation) {
    for (final plugin in _plugins.values) {
      plugin.beforeOperation(operation);
    }
  }

  /// Notify all plugins after an operation.
  void notifyAfter(RiftOperation operation, dynamic result) {
    for (final plugin in _plugins.values) {
      plugin.afterOperation(operation, result);
    }
  }

  /// Get a registered plugin by ID, optionally cast to type [T].
  T? getPlugin<T extends RiftPlugin>(String id) => _plugins[id] as T?;

  /// Get the context for a plugin.
  RiftPluginContext? getContext(String pluginId) => _contexts[pluginId];

  /// List all registered plugins.
  List<RiftPlugin> get plugins => _plugins.values.toList();

  /// List all registered plugin IDs.
  List<String> get pluginIds => _plugins.keys.toList();

  /// Whether a plugin with the given ID is registered.
  bool isRegistered(String pluginId) => _plugins.containsKey(pluginId);

  /// Number of registered plugins.
  int get pluginCount => _plugins.length;

  /// Unregister all plugins.
  Future<void> unregisterAll() async {
    final ids = _plugins.keys.toList();
    for (final id in ids) {
      await unregister(id);
    }
  }
}
