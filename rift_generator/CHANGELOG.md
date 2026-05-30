## 1.0.0 - May 30, 2026

Initial release of rift_generator — code generation for the Rift database.

### Features
- Auto-generated TypeAdapters from `@RiftType()` and `@RiftField()` annotations
- `GenerateAdapters` annotation for bulk adapter generation
- `RiftRegistrar` extension for one-call adapter registration
- Support for Dart 3 Records, sealed classes, and extension types
- Schema migration generation for evolving data models
- Freezed `@Default` annotation support
- Support for `reservedTypeIds` in `GenerateAdapters`
- Support for `ignoredFields` in adapter specs
- Sets and Iterable field support
- Named imports support
- **Validation Annotations** for code generation (`@RiftValidation`, `@RiftValidationSchema`, `@RiftCrossField`, `RiftValidationRule`)
- Support for Dart SDK ^3.4.0

### Migration from hive_ce_generator
- `@HiveType()` → `@RiftType()`
- `@HiveField()` → `@RiftField()`
- `HiveRegistrar` → `RiftRegistrar`
- All other APIs remain compatible

### Documentation
- Comprehensive README with code generation examples
- Migration guide from hive_ce_generator
- Schema migration examples

### Credits
- Built on the foundation of hive_ce_generator by the community
- Rift by [Idris Ghamid](https://github.com/idris-ghamid) / [IDRISIUM Corp](https://github.com/IDRISIUMCorp)
