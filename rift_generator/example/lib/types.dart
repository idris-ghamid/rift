import 'package:rift/rift.dart';
import 'package:example/named_import.dart' as named;
import 'package:meta/meta.dart';

part 'types.g.dart';

@RiftType(typeId: 1)
@immutable
class Class1 {
  const Class1(this.nested, [this.enum1]);

  @RiftField(
    0,
    defaultValue: Class2(4, 'param', <int, Map<String, List<Class1>>>{
      5: <String, List<Class1>>{
        'magic': <Class1>[
          Class1(Class2(5, 'sad')),
          Class1(Class2(5, 'sad'), Enum1.emumValue1),
        ],
      },
      67: <String, List<Class1>>{
        'hold': <Class1>[Class1(Class2(42, 'meaning of life'))],
      },
    }),
  )
  final Class2 nested;

  final Enum1? enum1;
}

@RiftType(typeId: 2)
@immutable
class Class2 {
  const Class2(this.param1, this.param2, [this.what]);

  @RiftField(0, defaultValue: 0)
  final int param1;

  @RiftField(1)
  final String param2;

  @RiftField(6)
  final Map<int, Map<String, List<Class1>>>? what;
}

@RiftType(typeId: 3)
enum Enum1 {
  @RiftField(0)
  emumValue1,

  @RiftField(1, defaultValue: true)
  emumValue2,

  @RiftField(2)
  emumValue3,
}

@RiftType(typeId: 4)
class EmptyClass {
  EmptyClass();
}

@RiftType(typeId: 5)
@immutable
class IterableClass {
  const IterableClass(this.list, this.set, this.nestedList, this.nestedSet);

  @RiftField(0)
  final List<String> list;

  @RiftField(1)
  final Set<String> set;

  @RiftField(2)
  final List<Set<String>> nestedList;

  @RiftField(3)
  final Set<List<String>> nestedSet;
}

@RiftType(typeId: 6)
@immutable
class ConstructorDefaults {
  ConstructorDefaults({this.a = 42, this.b = '42', this.c = true, DateTime? d})
    : d = d ?? DateTime.timestamp();

  @RiftField(0)
  final int a;

  @RiftField(1, defaultValue: '6 * 7')
  final String b;

  @RiftField(2)
  final bool c;

  @RiftField(3)
  final DateTime d;
}

@RiftType(typeId: 7)
@immutable
class NullableTypes {
  const NullableTypes({this.a, this.b, this.c});

  @RiftField(0)
  final int? a;

  @RiftField(1)
  final String? b;

  @RiftField(2)
  final bool? c;
}

@RiftType(typeId: 8)
@immutable
class NamedImports {
  const NamedImports(
    this.namedImportType,
    this.namedImportTypeList,
    this.namedImportTypeNullable,
    this.namedImportTypeMap,
  );

  @RiftField(0)
  final named.NamedImportType namedImportType;

  @RiftField(1)
  final List<named.NamedImportType> namedImportTypeList;

  @RiftField(2)
  final named.NamedImportType? namedImportTypeNullable;

  @RiftField(3)
  final Map<named.NamedImportType, named.NamedImportType> namedImportTypeMap;
}
