## 1.0.0 - May 30, 2026

Initial release of rift_flutter — Flutter integration for the Rift database.

### Features
- `Rift.initFlutter()` for automatic storage path initialization
- Built-in `ColorAdapter` for storing Flutter `Color` objects
- Built-in `TimeOfDayAdapter` for storing Flutter `TimeOfDay` objects
- Full compatibility with Rift core library
- Support for Android, iOS, Web, Windows, macOS, and Linux
- Support for Flutter SDK ^3.27.0
- Support for Dart SDK ^3.4.0

### Migration from hive_ce_flutter
- Replace `import 'package:hive_ce_flutter/hive_ce_flutter.dart'` with `import 'package:rift_flutter/rift_flutter.dart'`
- Replace `Hive.initFlutter()` with `Rift.initFlutter()`
- All other API calls remain the same

### Documentation
- Comprehensive README with Flutter integration examples
- Reactive UI patterns with StreamBuilder
- State management integration examples (Riverpod, Bloc)

### Credits
- Built on the foundation of hive_ce_flutter by the community
- Rift by [Idris Ghamid](https://github.com/idris-ghamid) / [IDRISIUM Corp](https://github.com/IDRISIUMCorp)
