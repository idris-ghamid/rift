import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

/// Sample model class for the typed box demo.
class User {
  final String name;
  final int age;
  final String email;

  const User({required this.name, required this.age, required this.email});

  @override
  String toString() => 'User(name: $name, age: $age, email: $email)';
}

class TypedBoxDemoPage extends StatelessWidget {
  const TypedBoxDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Typed Boxes',
      description:
          'Typed boxes with schema enforcement and compile-time type checking',
      codeExample:
          "final codec = ReflectiveCodec<User>(\n  (map) => User(name: map['name'], age: map['age']),\n  {'name': FieldAccessor((u) => u.name)},\n);\nfinal typedBox = TypedBox<User>(rawBox, codec);\nawait typedBox.put('u1', User(name: 'Alice', age: 30));\nfinal user = typedBox.get('u1'); // User instance",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Typed Boxes with Schema Enforcement Demo ===\n');

        // Create a ReflectiveCodec for the User type
        buf.writeln('--- Creating ReflectiveCodec<User> ---');
        final userCodec = ReflectiveCodec<User>(
          (map) => User(
            name: map['name'] as String,
            age: map['age'] as int,
            email: map['email'] as String,
          ),
          {
            'name': FieldAccessor<User>((u) => u.name),
            'age': FieldAccessor<User>((u) => u.age),
            'email': FieldAccessor<User>((u) => u.email),
          },
        );
        buf.writeln('  Codec created with 3 fields: name, age, email');

        // Open a raw box and wrap it in a TypedBox
        buf.writeln('\n--- Opening TypedBox ---');
        final rawBox =
            await Rift.openBox<Map<String, dynamic>>('typed_user_demo');
        await rawBox.clear();
        final typedBox = TypedBox<User>(rawBox, userCodec);
        buf.writeln('  TypedBox<User> wrapping raw box');

        // Store typed data
        buf.writeln('\n--- Storing Typed Data ---');
        await typedBox.put(
            'u1', const User(name: 'Alice', age: 30, email: 'alice@rift.dev'));
        await typedBox.put(
            'u2', const User(name: 'Bob', age: 25, email: 'bob@rift.dev'));
        await typedBox.put(
            'u3', const User(name: 'Carol', age: 35, email: 'carol@rift.dev'));
        buf.writeln('  Stored 3 User objects');
        buf.writeln('  Box length: ${typedBox.length}');

        // Retrieve typed data
        buf.writeln('\n--- Retrieving Typed Data ---');
        final alice = typedBox.get('u1');
        final bob = typedBox.get('u2');
        buf.writeln('  u1: $alice');
        buf.writeln('  u2: $bob');
        buf.writeln('  Type of u1: ${alice.runtimeType}');

        // List all values
        buf.writeln('\n--- All Values ---');
        for (final user in typedBox.values) {
          buf.writeln('  $user');
        }

        // Keys
        buf.writeln('\n--- Keys ---');
        buf.writeln('  ${typedBox.keys.toList()}');

        // ContainsKey
        buf.writeln('\n--- Contains Key ---');
        buf.writeln('  containsKey("u1"): ${typedBox.containsKey("u1")}');
        buf.writeln('  containsKey("u99"): ${typedBox.containsKey("u99")}');

        // PutAll
        buf.writeln('\n--- Batch Put ---');
        await typedBox.putAll({
          'u4': const User(name: 'Dave', age: 40, email: 'dave@rift.dev'),
          'u5': const User(name: 'Eve', age: 22, email: 'eve@rift.dev'),
        });
        buf.writeln('  After putAll: length = ${typedBox.length}');

        // Delete
        buf.writeln('\n--- Delete ---');
        await typedBox.delete('u3');
        buf.writeln('  After delete("u3"): length = ${typedBox.length}');

        // Raw box inspection
        buf.writeln('\n--- Raw Box (Underlying Map Data) ---');
        final rawMap = rawBox.toMap();
        for (final entry in rawMap.entries) {
          buf.writeln('  ${entry.key} → ${entry.value}');
        }

        // CodecRegistry
        buf.writeln('\n--- CodecRegistry ---');
        final registry = CodecRegistry();
        registry.register<User>(userCodec);
        buf.writeln('  Registered User codec');
        buf.writeln('  has<User>: ${registry.has<User>()}');
        buf.writeln('  Registered types: ${registry.registeredTypes.toList()}');

        // Schema enforcement explanation
        buf.writeln('\n--- Schema Enforcement ---');
        buf.writeln('  @RiftType(typeId: N) annotation for code-gen adapters');
        buf.writeln('  @RiftField(index) annotation for field mapping');
        buf.writeln('  ReflectiveCodec for manual schema without code-gen');
        buf.writeln('  TypedBox provides compile-time type safety');
        buf.writeln('  Runtime type checking via codec serialization');

        buf.writeln('\n--- @RiftType Annotation Example ---');
        buf.writeln('  @RiftType(typeId: 0)');
        buf.writeln('  class User {');
        buf.writeln('    @RiftField(0) final String name;');
        buf.writeln('    @RiftField(1) final int age;');
        buf.writeln('  }');

        await rawBox.close();

        buf.writeln('\n✅ Typed box demo complete');

        return buf.toString();
      },
    );
  }
}
