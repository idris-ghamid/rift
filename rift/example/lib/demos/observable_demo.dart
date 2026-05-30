import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class ObservableDemoPage extends StatelessWidget {
  const ObservableDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Observable Store',
      description:
          'Reactive data with RiftObservable, ObservableList, ObservableMap',
      codeExample:
          "final obs = RiftObservable<String>('hello');\nobs.listen((old, val) => print(val));\nobs.set('world');",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Observable Store Demo ===\n');

        // RiftObservable
        final name = RiftObservable<String>('Idris');
        final changeLog = <String>[];
        name.listen((oldVal, newVal) {
          changeLog.add('name: "$oldVal" → "$newVal"');
        });
        buf.writeln('--- RiftObservable<String> ---');
        buf.writeln('  Initial: ${name.value}');
        name.set('Ahmed');
        name.set('Sara');
        name.set('Ahmed'); // no change — won't notify
        buf.writeln('  Changes: $changeLog');
        buf.writeln('  Current: ${name.value}');

        // ObservableList
        buf.writeln('\n--- ObservableList<String> ---');
        final items = ObservableList<String>(['apple', 'banana']);
        final listLog = <String>[];
        items.addChangeListener((change) {
          listLog.add('${change.type}: ${change.element}');
        });
        items.add('cherry');
        items[0] = 'avocado';
        items.remove('banana');
        buf.writeln('  Items: $items');
        buf.writeln('  Changes: $listLog');

        // ObservableMap
        buf.writeln('\n--- ObservableMap<String, int> ---');
        final scores = ObservableMap<String, int>();
        final mapLog = <String>[];
        scores.addChangeListener((change) {
          mapLog.add('${change.type}: ${change.key} = ${change.value}');
        });
        scores['alice'] = 95;
        scores['bob'] = 87;
        scores['alice'] = 100; // update
        scores.remove('bob');
        buf.writeln('  Scores: ${Map<String, int>.from(scores)}');
        buf.writeln('  Changes: $mapLog');

        // ObservableComputation
        buf.writeln('\n--- ObservableComputation ---');
        final firstName = RiftObservable<String>('Idris');
        final lastName = RiftObservable<String>('Ghamid');
        final fullName = ObservableComputation<String>(
          dependencies: [firstName, lastName],
          compute: () => '${firstName.value} ${lastName.value}',
        );
        buf.writeln('  Full name: ${fullName.value}');
        firstName.set('Ahmed');
        buf.writeln('  After firstName→Ahmed: ${fullName.value}');
        lastName.set('Ali');
        buf.writeln('  After lastName→Ali: ${fullName.value}');

        name.dispose();
        items.dispose();
        scores.dispose();
        firstName.dispose();
        lastName.dispose();
        fullName.dispose();

        return buf.toString();
      },
    );
  }
}
