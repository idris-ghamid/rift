import 'dart:ui' as flutter;

import 'package:rift_flutter/rift_flutter.dart' as rift;

/// A wrapper around [flutter.IsolateNameServer] for [IsolatedHive]
class IsolateNameServer extends rift.IsolateNameServer {
  /// Constructor
  const IsolateNameServer();

  @override
  dynamic lookupPortByName(String name) =>
      flutter.IsolateNameServer.lookupPortByName(name);

  @override
  bool registerPortWithName(dynamic port, String name) =>
      flutter.IsolateNameServer.registerPortWithName(port, name);

  @override
  bool removePortNameMapping(String name) =>
      flutter.IsolateNameServer.removePortNameMapping(name);
}
