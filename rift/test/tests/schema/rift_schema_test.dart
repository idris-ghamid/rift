import 'dart:convert';

import 'package:rift/src/schema/rift_schema.dart';
import 'package:test/test.dart';

void main() {
  group('Hive schema', () {
    test('JSON', () {
      final schema = RiftSchema(
        nextTypeId: 0,
        types: {
          'Test': RiftSchemaType(
            typeId: 0,
            nextIndex: 0,
            fields: {'test': RiftSchemaField(index: 0)},
          ),
        },
      );

      final json = jsonEncode(schema);
      expect(json, isNotEmpty);

      final deserialized = RiftSchema.fromJson(jsonDecode(json));
      expect(deserialized.nextTypeId, schema.nextTypeId);
    });

    test('copyWith', () {
      final type = RiftSchemaType(
        typeId: 0,
        nextIndex: 0,
        fields: {'test': RiftSchemaField(index: 0)},
      );
      expect(type.fields, isNotEmpty);

      final copy = type.copyWith(fields: {});
      expect(copy.fields, isEmpty);
    });
  });
}

