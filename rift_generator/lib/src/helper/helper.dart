import 'dart:io';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:rift/rift.dart';
import 'package:rift_generator/src/model/rift_schema.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as path;
import 'package:meta/meta.dart';
import 'package:yaml_writer/yaml_writer.dart';

final _RiftFieldChecker =
    const TypeChecker.typeNamed(RiftField, inPackage: 'rift');
final _freezedDefaultChecker = const TypeChecker.fromUrl(
  'package:freezed_annotation/freezed_annotation.dart#Default',
);

@immutable
class RiftFieldInfo {
  const RiftFieldInfo(this.index, this.defaultValue);

  final int index;

  final DartObject? defaultValue;
}

RiftFieldInfo? getRiftFieldAnn(Element? element) {
  if (element == null) return null;
  final obj = _RiftFieldChecker.firstAnnotationOfExact(element);
  if (obj == null) return null;

  return RiftFieldInfo(
    obj.getField('index')!.toIntValue()!,
    obj.getField('defaultValue'),
  );
}

/// Get the string representation of the freezed default value
DartObject? getFreezedDefault(Element? element) {
  if (element == null) return null;
  final obj = _freezedDefaultChecker.firstAnnotationOfExact(element);
  if (obj == null) return null;

  // Get the source code of the default value
  return obj.getField('defaultValue');
}

/// Get a classes default constructor or throw
ConstructorElement getConstructor(InterfaceElement cls) {
  final constr = cls.constructors.firstWhereOrNull((it) => it.name == 'new');
  if (constr == null) {
    throw 'Provide an unnamed constructor.';
  }
  return constr;
}

/// Returns [element] as [InterfaceElement] if it is a class or enum
InterfaceElement getClass(Element element) {
  if (element.kind != ElementKind.CLASS && element.kind != ElementKind.ENUM) {
    throw 'Only classes or enums are allowed to be annotated with @RiftType.';
  }

  return element as InterfaceElement;
}

/// Generate a default adapter name from the type name
String generateAdapterName(String typeName) {
  var adapterName =
      '${typeName}Adapter'.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '');
  if (adapterName.startsWith('_')) {
    adapterName = adapterName.substring(1);
  }
  if (adapterName.startsWith(r'$')) {
    adapterName = adapterName.substring(1);
  }
  return adapterName;
}

/// Read the adapter name from the annotation
String? readAdapterName(ConstantReader annotation) {
  final adapterNameField = annotation.read('adapterName');
  return adapterNameField.isNull ? null : adapterNameField.stringValue;
}

/// Read the typeId from the annotation
int readTypeId(ConstantReader annotation) {
  if (annotation.read('typeId').isNull) {
    throw 'You have to provide a non-null typeId.';
  }

  return annotation.read('typeId').intValue;
}

/// Convenience extension for [BuildStep]
extension BuildStepExtension on BuildStep {
  /// Create an [AssetId] for the given [path] relative to the input package
  AssetId asset(String path) => AssetId(inputId.package, path);

  /// Write [content] to asset [id] ignoring output restrictions
  ///
  /// This exists to bypass the following restrictions:
  /// - `$lib$` inputs can only have fixed output locations
  /// - Any files output through `buildStep.writeAsString` will be deleted
  ///   before the build starts
  void forceWriteAsString(AssetId id, String content) {
    File(path.joinAll(id.pathSegments))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }
}

/// Write a [RiftSchema] to a string
String writeSchema(RiftSchema schema) {
  final yaml = YamlWriter().write(schema.toJson());
  return '''
${RiftSchema.comment}
$yaml''';
}
