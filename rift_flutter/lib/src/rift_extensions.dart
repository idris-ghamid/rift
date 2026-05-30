import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:rift_flutter/adapters.dart';
import 'package:rift_flutter/src/wrapper/path_provider.dart';
import 'package:rift_flutter/src/wrapper/path.dart' as path_helper;

/// Flutter extensions for Rift.
extension RiftX on RiftInterface {
  /// Initializes Rift with the path from [getApplicationDocumentsDirectory].
  ///
  /// You can provide a [subDir] where the boxes should be stored.
  ///
  /// Also registers the flutter type adapters
  /// - [colorAdapterTypeId] - The type id for the color adapter (default: 200)
  /// - [timeOfDayAdapterTypeId] - The type id for the time of day adapter (default: 201)
  Future<void> initFlutter([
    String? subDir,
    RiftStorageBackendPreference backendPreference =
        RiftStorageBackendPreference.native,
    int? colorAdapterTypeId,
    int? timeOfDayAdapterTypeId,
  ]) async {
    WidgetsFlutterBinding.ensureInitialized();

    String? path;
    if (!kIsWeb) {
      final appDir = await getApplicationDocumentsDirectory();
      path = path_helper.join(appDir.path, subDir);
    }

    init(
      path,
      backendPreference: backendPreference,
    );

    final colorAdapter = ColorAdapter(typeId: colorAdapterTypeId);
    if (!isAdapterRegistered(colorAdapter.typeId)) {
      registerAdapter(colorAdapter);
    }

    final timeOfDayAdapter = TimeOfDayAdapter(typeId: timeOfDayAdapterTypeId);
    if (!isAdapterRegistered(timeOfDayAdapter.typeId)) {
      registerAdapter(timeOfDayAdapter);
    }
  }
}
