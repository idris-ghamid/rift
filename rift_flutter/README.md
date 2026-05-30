# rift_flutter

[![Pub Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://pub.dev/packages/rift_flutter)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

Flutter integration for [Rift](https://github.com/idris-ghamid/rift) — the next-generation NoSQL database for Flutter & Dart.

## Features

- **Easy Initialization** — `Rift.initFlutter()` sets up the storage path automatically
- **Flutter Adapters** — Built-in `ColorAdapter` and `TimeOfDayAdapter` for storing Flutter types
- **Reactive Widgets** — Use `StreamBuilder` with `box.watch()` for real-time UI updates
- **Zero Configuration** — Works out of the box on Android, iOS, Web, Windows, macOS, and Linux

## Installation

```yaml
dependencies:
  rift_flutter: ^1.0.0
```

## Quick Start

```dart
import 'package:rift_flutter/rift_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Rift.initFlutter();
  runApp(const MyApp());
}
```

## Reactive UI

```dart
StreamBuilder(
  stream: box.watch(),
  builder: (context, snapshot) {
    return ListView.builder(
      itemCount: box.length,
      itemBuilder: (context, index) => ListTile(title: Text(box.getAt(index).toString())),
    );
  },
)
```

## Related Packages

| Package | Description |
|---------|-------------|
| [rift](https://pub.dev/packages/rift) | Core database library |
| [rift_generator](https://pub.dev/packages/rift_generator) | Code generation for typed boxes |
| [rift_inspector](https://pub.dev/packages/rift_inspector) | DevTools inspector UI |

## License

Apache License 2.0

---

## About Author

**Idris Ghamid** is a software engineer and open-source contributor specializing in Flutter, Dart, and mobile development.

### Connect with Idris

- **GitHub**: [idrisghamid](https://github.com/idris-ghamid)
- **LinkedIn**: [Idris Ghamid](https://www.linkedin.com/in/idris-ghamid)
- **Instagram**: [@idris.ghamid](https://www.instagram.com/idris.ghamid)
- **X (Twitter)**: [@IdrisGhamid](https://x.com/IdrisGhamid)

---

**Made with ❤️ by [Idris Ghamid](https://github.com/idris-ghamid)**
