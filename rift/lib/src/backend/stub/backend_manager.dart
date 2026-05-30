import 'dart:async';

import 'package:rift/rift.dart';
import 'package:rift/src/backend/storage_backend.dart';

/// Not part of public API
class BackendManager implements BackendManagerInterface {
  /// TODO: Document this!
  static BackendManager select([
    RiftStorageBackendPreference? backendPreference,
    bool walEnabled = true,
  ]) => BackendManager();

  @override
  Future<StorageBackend> open(
    String name,
    String? path,
    bool crashRecovery,
    RiftCipher? cipher,
    int? keyCrc,
    String? collection,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteBox(String name, String? path, String? collection) {
    throw UnimplementedError();
  }

  @override
  Future<bool> boxExists(String name, String? path, String? collection) {
    throw UnimplementedError();
  }
}
