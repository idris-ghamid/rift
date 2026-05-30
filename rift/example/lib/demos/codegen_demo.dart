import 'package:flutter/material.dart';
import '../widgets/demo_page.dart';

class CodegenDemoPage extends StatelessWidget {
  const CodegenDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Code Generator',
      description:
          'Smart code generator for auto-generating TypeAdapters with Dart 3 support',
      codeExample:
          "@RiftType(typeId: 0)\nclass User {\n  @RiftField(0) final String name;\n  @RiftField(1) final int age;\n}\n// dart run build_runner build",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Smart Code Generator with Dart 3 ===\n');

        buf.writeln('The rift_generator package auto-generates TypeAdapters');
        buf.writeln(
            'so you don\'t have to write serialization code by hand.\n');

        buf.writeln('--- Step 1: Add Annotations ---');
        buf.writeln(
            'Annotate your Dart classes with @RiftType and @RiftField:');
        buf.writeln('');
        buf.writeln('  @RiftType(typeId: 0)');
        buf.writeln('  class User {');
        buf.writeln('    @RiftField(0)');
        buf.writeln('    final String name;');
        buf.writeln('');
        buf.writeln('    @RiftField(1)');
        buf.writeln('    final int age;');
        buf.writeln('');
        buf.writeln('    @RiftField(2, defaultValue: \'\')');
        buf.writeln('    final String email;');
        buf.writeln('');
        buf.writeln(
            '    User({required this.name, required this.age, this.email = \'\'});');
        buf.writeln('  }');
        buf.writeln('');

        buf.writeln('--- Step 2: Add build.yaml Configuration ---');
        buf.writeln('  targets:');
        buf.writeln('    \$default:');
        buf.writeln('      builders:');
        buf.writeln('        rift_generator|rift_generator:');
        buf.writeln('          enabled: true');
        buf.writeln('');

        buf.writeln('--- Step 3: Run Code Generation ---');
        buf.writeln('  dart run build_runner build');
        buf.writeln('');
        buf.writeln('  Or watch for changes:');
        buf.writeln('  dart run build_runner watch');
        buf.writeln('');

        buf.writeln('--- Step 4: Generated Code (Example) ---');
        buf.writeln('The generator produces a UserAdapter class:');
        buf.writeln('');
        buf.writeln('  class UserAdapter extends TypeAdapter<User> {');
        buf.writeln('    @override');
        buf.writeln('    final int typeId = 0;');
        buf.writeln('');
        buf.writeln('    @override');
        buf.writeln('    User read(BinaryReader reader) {');
        buf.writeln('      final numOfFields = reader.readByte();');
        buf.writeln('      final fields = <int, dynamic>{');
        buf.writeln('        for (int i = 0; i < numOfFields; i++)');
        buf.writeln('          fields[reader.readByte()] = reader.read();');
        buf.writeln('      };');
        buf.writeln('      return User(');
        buf.writeln('        name: fields[0] as String,');
        buf.writeln('        age: fields[1] as int,');
        buf.writeln('        email: fields[2] as String,');
        buf.writeln('      );');
        buf.writeln('    }');
        buf.writeln('');
        buf.writeln('    @override');
        buf.writeln('    void write(BinaryWriter writer, User obj) {');
        buf.writeln('      writer');
        buf.writeln('        ..writeByte(3)');
        buf.writeln('        ..writeByte(0)..write(obj.name)');
        buf.writeln('        ..writeByte(1)..write(obj.age)');
        buf.writeln('        ..writeByte(2)..write(obj.email);');
        buf.writeln('    }');
        buf.writeln('  }');
        buf.writeln('');

        buf.writeln('--- Step 5: Register & Use ---');
        buf.writeln('  Rift.registerAdapter(UserAdapter());');
        buf.writeln('  await box.put("user", User(name: "Alice", age: 30));');
        buf.writeln('  final user = box.get("user") as User;');
        buf.writeln('');

        buf.writeln('--- @RiftType Annotation Options ---');
        buf.writeln('  @RiftType(typeId: 0)');
        buf.writeln('    typeId: Required. Unique integer ID for the type.');
        buf.writeln('    adapterName: Optional custom name for the adapter.');
        buf.writeln('');

        buf.writeln('--- @RiftField Annotation Options ---');
        buf.writeln('  @RiftField(index, defaultValue: ...)');
        buf.writeln('    index: Required. Zero-based field index.');
        buf.writeln('    defaultValue: Optional. Used when field is missing');
        buf.writeln('      during deserialization (schema evolution).');
        buf.writeln('');

        buf.writeln('--- GenerateAdapters (Alternative) ---');
        buf.writeln('  @GenerateAdapters([AdapterSpec<User>()])');
        buf.writeln('  library my_adapters;');
        buf.writeln('');
        buf.writeln('  Or with options:');
        buf.writeln('  @GenerateAdapters(');
        buf.writeln(
            '    [AdapterSpec<User>(ignoredFields: {\'computedField\'})],');
        buf.writeln('    firstTypeId: 100,');
        buf.writeln('    reservedTypeIds: {0, 1, 2},');
        buf.writeln('  )');
        buf.writeln('  library my_adapters;');
        buf.writeln('');

        buf.writeln('--- Tips ---');
        buf.writeln('  Use unique typeId per class (0-223 are safe)');
        buf.writeln(
            '  Never reuse field indices - add new fields with new indices');
        buf.writeln('  defaultValue helps with backward compatibility');
        buf.writeln('  Dart 3 records can use RecordAdapter instead');

        return buf.toString();
      },
    );
  }
}
