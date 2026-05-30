import 'package:rift/rift.dart';
import 'package:rift/src/backend/storage_backend.dart';

import 'package:rift/src/backend/js/native/backend_manager.dart' as native;

/// Opens IndexedDB databases
abstract class BackendManager {
  BackendManager._();

  // dummy implementation as the WebWorker branch is not stable yet
  /// TODO: Document this!
  static BackendManagerInterface select([
    RiftStorageBackendPreference? backendPreference,
    bool walEnabled = true,
  ]) {
    switch (backendPreference) {
      default:
        return native.BackendManager();
    }
  }
}
