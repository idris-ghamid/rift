import 'package:test/test.dart';

import '../util/is_browser/is_browser.dart';
import 'integration.dart';

Future _performTest(bool lazy, {required TestType type}) async {
  final rift = await createHive(type: type);
  final amount = isBrowser ? 10 : 100;
  var (_, box) = await openBox(lazy, type: type, rift: rift);

  Future putEntries() async {
    for (var i = 0; i < amount; i++) {
      await box.put('key$i', 'value$i');
    }
  }

  final futures = <Future>[];
  for (var i = 0; i < 10; i++) {
    futures.add(putEntries());
  }
  await Future.wait(futures);

  box = await rift.reopenBox(box);
  for (var i = 0; i < amount; i++) {
    expect(await box.get('key$i'), 'value$i');
  }
  await box.close();
}

void main() {
  riftIntegrationTest((type) {
    group('put many entries simultaneously', () {
      test('normal box', () => _performTest(false, type: type));

      test('lazy box', () => _performTest(true, type: type));
    }, timeout: longTimeout);
  });
}
