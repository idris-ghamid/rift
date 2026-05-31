import 'package:rift_inspector/model/rift_internal.dart';

/// Built in schema types
const baseSchema = <String, RiftSchemaType>{
  'Color': RiftSchemaType(
    typeId: 200,
    nextIndex: 5,
    fields: {
      'a': RiftSchemaField(index: 0),
      'r': RiftSchemaField(index: 1),
      'g': RiftSchemaField(index: 2),
      'b': RiftSchemaField(index: 3),
      'colorSpace': RiftSchemaField(index: 4),
    },
  ),
};
