import 'package:rift/rift.dart' hide MockBox;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import '../common.dart';
import '../mocks.dart';

RiftList _getTestList(MockBox box) {
  when(() => box.name).thenReturn('testBox');
  final obj1 = TestRiftObject();
  obj1.init('key1', box);
  final obj2 = TestRiftObject();
  obj2.init('key2', box);
  final obj3 = TestRiftObject();
  obj3.init('key3', box);

  return RiftList(box, objects: [obj1, obj2, obj3]);
}

void main() {
  group('HiveCollectionMixin', () {
    test('.keys', () {
      final box = MockBox();
      final riftList = _getTestList(box);

      expect(riftList.keys, ['key1', 'key2', 'key3']);
    });

    test('.deleteAllFromHive()', () {
      final keys = ['key1', 'key2', 'key3'];
      final box = MockBox();
      final riftList = _getTestList(box);
      returnFutureVoid(
        when(
          () => box.deleteAll(
            keys.map((e) => e), // Turn the List into an regular Iterable
          ),
        ),
      );

      riftList.deleteAllFromHive();
      verify(() => box.deleteAll(keys));
    });

    test('.deleteFirstFromHive()', () {
      final box = MockBox();
      final riftList = _getTestList(box);
      returnFutureVoid(when(() => box.delete('key1')));

      riftList.deleteFirstFromHive();
      verify(() => box.delete('key1'));
    });

    test('.deleteLastFromHive()', () {
      final box = MockBox();
      final riftList = _getTestList(box);
      returnFutureVoid(when(() => box.delete('key3')));

      riftList.deleteLastFromHive();
      verify(() => box.delete('key3'));
    });

    test('.deleteFromHive()', () {
      final box = MockBox();
      final riftList = _getTestList(box);
      returnFutureVoid(when(() => box.delete('key2')));

      riftList.deleteFromHive(1);
      verify(() => box.delete('key2'));
    });

    test('.toMap()', () {
      final box = MockBox();
      when(() => box.name).thenReturn('testBox');
      final obj1 = TestRiftObject();
      obj1.init('key1', box);
      final obj2 = TestRiftObject();
      obj2.init('key2', box);

      final riftList = RiftList(box, objects: [obj1, obj2]);

      expect(riftList.toMap(), {'key1': obj1, 'key2': obj2});
    });
  });
}
