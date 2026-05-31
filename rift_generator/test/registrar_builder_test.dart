import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('registrar_builder', () {
    test('outputs to lib folder by default', () {
      expectGeneration(
        input: {
          ...pubspec(),
          'lib/nested/type.dart': '''
import 'package:rift/rift.dart';
part 'type.g.dart';

@RiftType(typeId: 0)
class Type {}
''',
        },
        output: {
          'lib/hive_registrar.g.dart': fileExists,
        },
      );
    });

    test('does not output with no types', () {
      expectGeneration(
        input: {
          ...pubspec(),
          'lib/rift_adapters.dart': '''
import 'package:rift/rift.dart';
part 'rift_adapters.g.dart';

@GenerateAdapters([])
void _() {}
''',
        },
        output: {
          'lib/hive_registrar.g.dart': fileDoesNotExist,
        },
      );
    });

    test('outputs next to GenerateAdapters annotation', () {
      expectGeneration(
        input: {
          ...pubspec(),
          'lib/hive/rift_adapters.dart': '''
import 'package:rift/rift.dart';
part 'rift_adapters.g.dart';

@GenerateAdapters([AdapterSpec<Type>()])
class Type {}
''',
        },
        output: {
          'lib/hive/hive_registrar.g.dart': fileExists,
        },
      );
    });

    test('fails with multiple GenerateAdapters in same file', () {
      expectGeneration(
        input: {
          ...pubspec(),
          'lib/rift_adapters.dart': '''
import 'package:rift/rift.dart';
part 'rift_adapters.g.dart';

@GenerateAdapters([AdapterSpec<Type>()])
class Type {}

@GenerateAdapters([AdapterSpec<Type2>()])
class Type2 {}
''',
        },
        throws:
            'Multiple GenerateAdapters annotations found in file: package:rift_generator_test/rift_adapters.dart',
      );
    });

    test('fails with multiple GenerateAdapters on same element', () {
      expectGeneration(
        input: {
          ...pubspec(),
          'lib/rift_adapters.dart': '''
import 'package:rift/rift.dart';
part 'rift_adapters.g.dart';

@GenerateAdapters([AdapterSpec<Type>()])
@GenerateAdapters([AdapterSpec<Type2>()])
class Type {}

class Type2 {}
''',
        },
        throws:
            'Multiple GenerateAdapters annotations found in file: package:rift_generator_test/rift_adapters.dart',
      );
    });

    test('fails with multiple GenerateAdapters files', () {
      expectGeneration(
        input: {
          ...pubspec(),
          'lib/rift_adapters.dart': '''
import 'package:rift/rift.dart';
part 'rift_adapters.g.dart';

@GenerateAdapters([AdapterSpec<Type>()])
class Type {}
''',
          'lib/hive_adapters_2.dart': '''
import 'package:rift/rift.dart';
part 'hive_adapters_2.g.dart';

@GenerateAdapters([AdapterSpec<Type2>()])
class Type2 {}
''',
        },
        throws: '''
GenerateAdapters annotation found in more than one file:
- package:rift_generator_test/rift_adapters.dart
- package:rift_generator_test/hive_adapters_2.dart''',
      );
    });
  });
}
