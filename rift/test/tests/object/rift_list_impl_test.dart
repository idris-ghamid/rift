import 'dart:typed_data';

import 'package:rift/src/rift_impl.dart';
import 'package:rift/src/object/rift_list_impl.dart';
import 'package:rift/src/object/rift_object.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../integration/integration.dart';
import '../common.dart';
import '../mocks.dart';

RiftObject _getRiftObject(String key, MockBox box) {
  final RiftObject = TestRiftObject();
  RiftObject.init(key, box);
  when(
    () => box.get(
      key,
      defaultValue: captureAny(that: isNotNull, named: 'defaultValue'),
    ),
  ).thenReturn(RiftObject);
  when(() => box.get(key)).thenReturn(RiftObject);
  return RiftObject;
}

MockBox _mockBox() {
  final box = MockBox();
  // The RiftListImpl constructor sets the boxName property to box.name,
  // therefore we need to return an valid String on sound null safety.
  when(() => box.name).thenReturn('testBox');
  return box;
}

void main() {
  group('RiftListImpl', () {
    test('RiftListImpl()', () {
      final box = _mockBox();

      final item1 = _getRiftObject('item1', box);
      final item2 = _getRiftObject('item2', box);
      final list = RiftListImpl(box, objects: [item1, item2, item1]);

      expect(item1.debugRiftLists, {list: 2});
      expect(item2.debugRiftLists, {list: 1});
    });

    test('RiftListImpl.lazy()', () {
      final list = RiftListImpl.lazy('testBox', ['key1', 'key2']);
      expect(list.boxName, 'testBox');
      expect(list.keys, ['key1', 'key2']);
    });

    group('.box', () {
      test('throws RiftError if box is not open', () async {
        final rift = await createHive(type: TestType.normal);
        final RiftList = RiftListImpl.lazy('someBox', [])
          ..debugRift = rift.rift as RiftImpl;
        expect(
          () => RiftList.box,
          throwsRiftError(['you have to open the box']),
        );
      });

      test('returns the box', () async {
        final rift = await createHive(type: TestType.normal);
        final box = await rift.openBox<int>('someBox', bytes: Uint8List(0));
        final RiftList = RiftListImpl.lazy('someBox', [])
          ..debugRift = rift.rift as RiftImpl;
        expect(RiftList.box, box.box);
      });
    });

    group('.delegate', () {
      test('throws exception if RiftList is disposed', () {
        final list = RiftListImpl.lazy('box', []);
        list.dispose();
        expect(() => list.delegate, throwsRiftError(['already been disposed']));
      });

      test('removes correct elements if invalidated', () {
        final box = _mockBox();
        final item1 = _getRiftObject('item1', box);
        final item2 = _getRiftObject('item2', box);
        final list = RiftListImpl(box, objects: [item1, item2, item1]);

        item1.debugRiftLists.clear();
        expect(list.delegate, [item1, item2, item1]);
        list.invalidate();
        expect(list.delegate, [item2]);
      });

      test('creates delegate and links RiftList if delegate == null', () {
        final hive = MockRiftImpl();
        final box = _mockBox();
        when(() => box.containsKey('item1')).thenReturn(true);
        when(() => box.containsKey('item2')).thenReturn(true);
        when(() => box.containsKey('none')).thenReturn(false);
        when(() => hive.getBoxWithoutCheckInternal('box')).thenReturn(box);

        final item1 = _getRiftObject('item1', box);
        final item2 = _getRiftObject('item2', box);

        final list = RiftListImpl.lazy('box', [
          'item1',
          'none',
          'item2',
          'item1',
        ])..debugRift = hive;
        expect(list.delegate, [item1, item2, item1]);
        expect(item1.debugRiftLists, {list: 2});
        expect(item2.debugRiftLists, {list: 1});
      });
    });

    group('.dispose()', () {
      test('unlinks remote RiftObjects if delegate exists', () {
        final box = _mockBox();
        final item1 = _getRiftObject('item1', box);
        final item2 = _getRiftObject('item2', box);

        final list = RiftListImpl(box, objects: [item1, item2, item1]);
        list.dispose();

        expect(item1.debugRiftLists, {});
        expect(item2.debugRiftLists, {});
      });
    });

    test('set length', () {
      final box = _mockBox();
      final item1 = _getRiftObject('item1', box);
      final item2 = _getRiftObject('item2', box);

      final list = RiftListImpl(box, objects: [item1, item2]);
      list.length = 1;

      expect(item2.debugRiftLists, {});
      expect(list, [item1]);
    });

    group('operator []=', () {
      test('sets key at index', () {
        final box = _mockBox();
        final oldItem = _getRiftObject('old', box);
        final newItem = _getRiftObject('new', box);

        final list = RiftListImpl(box, objects: [oldItem]);
        list[0] = newItem;

        expect(oldItem.debugRiftLists, {});
        expect(newItem.debugRiftLists, {list: 1});
        expect(list, [newItem]);
      });

      test('throws RiftError if RiftObject is not valid', () {
        final box = _mockBox();
        final oldItem = _getRiftObject('old', box);
        final newItem = _getRiftObject('new', MockBox());

        final list = RiftListImpl(box, objects: [oldItem]);
        expect(() => list[0] = newItem, throwsRiftError());
      });
    });

    group('.add()', () {
      test('adds key', () {
        final box = _mockBox();
        final item1 = _getRiftObject('item1', box);
        final item2 = _getRiftObject('item2', box);

        final list = RiftListImpl(box, objects: [item1]);
        list.add(item2);

        expect(item2.debugRiftLists, {list: 1});
        expect(list, [item1, item2]);
      });

      test('throws RiftError if RiftObject is not valid', () {
        final box = _mockBox();
        final item = _getRiftObject('item', MockBox());
        final list = RiftListImpl(box);
        expect(
          () => list.add(item),
          throwsRiftError(['needs to be in the box']),
        );
      });
    });

    group('.addAll()', () {
      test('adds keys', () {
        final box = _mockBox();
        final item1 = _getRiftObject('item1', box);
        final item2 = _getRiftObject('item2', box);

        final list = RiftListImpl(box, objects: [item1]);
        list.addAll([item2, item2]);

        expect(item2.debugRiftLists, {list: 2});
        expect(list, [item1, item2, item2]);
      });

      test('throws RiftError if RiftObject is not valid', () {
        final box = _mockBox();
        final item = _getRiftObject('item', MockBox());

        final list = RiftListImpl(box);
        expect(
          () => list.addAll([item]),
          throwsRiftError(['needs to be in the box']),
        );
      });
    });
  });
}




