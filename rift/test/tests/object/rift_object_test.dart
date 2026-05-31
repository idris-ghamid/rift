import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common.dart';
import '../mocks.dart';

void main() {
  group('RiftObject', () {
    group('.init()', () {
      test('adds key and box to RiftObject', () {
        final obj = TestRiftObject();
        final box = MockBox();

        obj.init('someKey', box);

        expect(obj.key, 'someKey');
        expect(obj.box, box);
      });

      test('does nothing if old key and box are equal to new key and box', () {
        final obj = TestRiftObject();
        final box = MockBox();

        obj.init('someKey', box);
        obj.init('someKey', box);

        expect(obj.key, 'someKey');
        expect(obj.box, box);
      });

      test('throws exception if object is already in a different box', () {
        final obj = TestRiftObject();
        final box1 = MockBox();
        final box2 = MockBox();

        obj.init('someKey', box1);
        expect(
          () => obj.init('someKey', box2),
          throwsRiftError(['two different boxes']),
        );
      });

      test('throws exception if object has already different key', () {
        final obj = TestRiftObject();
        final box = MockBox();

        obj.init('key1', box);
        expect(
          () => obj.init('key2', box),
          throwsRiftError(['two different keys']),
        );
      });
    });

    group('.dispose()', () {
      test('removes key and box', () {
        final obj = TestRiftObject();
        final box = MockBox();

        obj.init('key', box);
        obj.dispose();

        expect(obj.key, null);
        expect(obj.box, null);
      });

      test('notifies remote RiftLists', () {
        final obj = TestRiftObject();
        final box = MockBox();
        obj.init('key', box);

        final list = MockRiftList();
        obj.linkRiftList(list);
        obj.dispose();

        verify(list.invalidate);
      });
    });

    test('.linkRiftList()', () {
      final box = MockBox();
      final obj = TestRiftObject();
      obj.init('key', box);
      final RiftList = MockRiftList();

      obj.linkRiftList(RiftList);
      expect(obj.debugRiftLists, {RiftList: 1});
      obj.linkRiftList(RiftList);
      expect(obj.debugRiftLists, {RiftList: 2});
    });

    test('.unlinkRiftList()', () {
      final box = MockBox();
      final obj = TestRiftObject();
      obj.init('key', box);
      final RiftList = MockRiftList();

      obj.linkRiftList(RiftList);
      obj.linkRiftList(RiftList);
      expect(obj.debugRiftLists, {RiftList: 2});

      obj.unlinkRiftList(RiftList);
      expect(obj.debugRiftLists, {RiftList: 1});
      obj.unlinkRiftList(RiftList);
      expect(obj.debugRiftLists, {});
    });

    group('.save()', () {
      test('updates object in box', () {
        final obj = TestRiftObject();
        final box = MockBox();
        returnFutureVoid(when(() => box.put('key', obj)));

        obj.init('key', box);
        verifyZeroInteractions(box);

        obj.save();
        verify(() => box.put('key', obj));
      });

      test('throws RiftError if object is not in a box', () async {
        final obj = TestRiftObject();
        await expectLater(obj.save, throwsRiftError(['not in a box']));
      });
    });

    group('.delete()', () {
      test('removes object from box', () {
        final obj = TestRiftObject();
        final box = MockBox();
        returnFutureVoid(when(() => box.delete('key')));

        obj.init('key', box);
        verifyZeroInteractions(box);

        obj.delete();
        verify(() => box.delete('key'));
      });

      test('throws RiftError if object is not in a box', () async {
        final obj = TestRiftObject();
        await expectLater(obj.delete, throwsRiftError(['not in a box']));
      });
    });

    group('.isInBox', () {
      test('returns false if box is not set', () {
        final obj = TestRiftObject();
        expect(obj.isInBox, false);
      });

      test('returns true if object is in normal box', () {
        final obj = TestRiftObject();
        final box = MockBox();
        obj.init('key', box);

        expect(obj.isInBox, true);
      });

      test(
        'returns the result ob box.containsKey() if object is in lazy box',
        () {
          final obj = TestRiftObject();
          final box = MockBox(lazy: true);
          obj.init('key', box);

          when(() => box.containsKey('key')).thenReturn(true);
          expect(obj.isInBox, true);

          when(() => box.containsKey('key')).thenReturn(false);
          expect(obj.isInBox, false);
        },
      );
    });
  });
}
