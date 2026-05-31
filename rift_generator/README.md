# rift_generator

[![Pub Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://pub.dev/packages/rift_generator)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

Code generator for [Rift](https://github.com/idris-ghamid/rift) — automatically generates TypeAdapters to store any Dart class.

[lib WebSite](https://rift-lib.vercel.app/)

## Features

- **Auto-generated TypeAdapters** — No manual serialization code
- **Dart 3 Support** — Records, sealed classes, extension types
- **Schema Migration** — Built-in migration for evolving data models
- **Freezed Support** — Works seamlessly with `@freezed` classes
- **`GenerateAdapters` Annotation** — One annotation to generate all adapters
- **HiveRegistrar** — Register all adapters in one call

## Installation

```yaml
dependencies:
  rift: ^1.0.0

dev_dependencies:
  rift_generator: ^1.0.0
  build_runner: ^2.4.0
```

## Usage

### 1. Annotate your class

```dart
import 'package:rift/rift.dart';

part 'user.g.dart';

@RiftType()
class User {
  @RiftField(0)
  String name;

  @RiftField(1)
  int age;

  @RiftField(2, defaultValue: '')
  String email;

  User({required this.name, required this.age, this.email = ''});
}
```

### 2. Run the generator

```bash
dart run build_runner build
```

### 3. Register adapters

```dart
// Auto-generated registrar
final registrar = RiftRegistrar();
registrar.registerAllAdapters();

// Or manually
Hive.registerAdapter(UserAdapter());
```

## GenerateAdapters Annotation

```dart
@GenerateAdapters([AdapterSpec<User>(fields: {0: 'name', 1: 'age'})])
class App {}
```

## Migration from hive_ce_generator
- Replace `import 'package:hive_ce_generator/hive_ce_generator.dart'` with Rift equivalents
- `@HiveType()` → `@RiftType()`
- `@HiveField()` → `@RiftField()`
- All generated code is compatible with Rift core

## Related Packages

| Package | Description |
|---------|-------------|
| [rift](https://pub.dev/packages/rift) | Core database library |
| [rift_flutter](https://pub.dev/packages/rift_flutter) | Flutter integration |
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
