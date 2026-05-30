// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rift_schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RiftSchema _$RiftSchemaFromJson(Map<String, dynamic> json) => RiftSchema(
  nextTypeId: (json['nextTypeId'] as num).toInt(),
  types: (json['types'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, RiftSchemaType.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$RiftSchemaToJson(RiftSchema instance) =>
    <String, dynamic>{
      'nextTypeId': instance.nextTypeId,
      'types': instance.types,
    };

RiftSchemaType _$RiftSchemaTypeFromJson(Map<String, dynamic> json) =>
    RiftSchemaType(
      typeId: (json['typeId'] as num).toInt(),
      nextIndex: (json['nextIndex'] as num).toInt(),
      fields: (json['fields'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, RiftSchemaField.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$RiftSchemaTypeToJson(RiftSchemaType instance) =>
    <String, dynamic>{
      'typeId': instance.typeId,
      'nextIndex': instance.nextIndex,
      'fields': instance.fields,
    };

RiftSchemaField _$RiftSchemaFieldFromJson(Map<String, dynamic> json) =>
    RiftSchemaField(index: (json['index'] as num).toInt());

Map<String, dynamic> _$RiftSchemaFieldToJson(RiftSchemaField instance) =>
    <String, dynamic>{'index': instance.index};
