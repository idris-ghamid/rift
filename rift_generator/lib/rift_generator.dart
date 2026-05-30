import 'package:build/build.dart';
import 'package:rift_generator/src/builder/schema_migrator_builder.dart';
import 'package:rift_generator/src/generator/adapters_generator.dart';
import 'package:rift_generator/src/builder/registrar_builder.dart';
import 'package:rift_generator/src/builder/registrar_intermediate_builder.dart';
import 'package:rift_generator/src/generator/type_adapter_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Builds Rift TypeAdapters
Builder getTypeAdapterBuilder(BuilderOptions options) =>
    SharedPartBuilder([TypeAdapterGenerator()], 'rift_type_adapter_generator');

/// Builds intermediate data required for the registrar builder
Builder getRegistrarIntermediateBuilder(BuilderOptions options) =>
    RegistrarIntermediateBuilder();

/// Builds the RiftRegistrar extension
Builder getRegistrarBuilder(BuilderOptions options) => RegistrarBuilder();

/// Builds Rift TypeAdapters from the GenerateAdapters annotation
Builder getAdaptersBuilder(BuilderOptions options) =>
    SharedPartBuilder([AdaptersGenerator()], 'rift_adapters_generator');

/// Builds a Rift schema from existing RiftType annotations
Builder getSchemaMigratorBuilder(BuilderOptions options) =>
    RiftSchemaMigratorBuilder();

