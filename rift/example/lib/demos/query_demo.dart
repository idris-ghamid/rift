import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class QueryDemoPage extends StatelessWidget {
  const QueryDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Query Builder',
      description:
          'The query builder lets you filter, sort, and paginate data easily',
      codeExample:
          "box.query()\n  .where('age', greaterThan: 25)\n  .sortBy('name')\n  .limit(10)\n  .findAll();",
      runDemo: () async {
        final box = await Rift.openBox<Map>('query_demo');
        await box.clear();
        await box.putAll({
          'u1': {'name': 'Alice', 'age': 30, 'city': 'Cairo'},
          'u2': {'name': 'Bob', 'age': 22, 'city': 'Riyadh'},
          'u3': {'name': 'Charlie', 'age': 35, 'city': 'Cairo'},
          'u4': {'name': 'Diana', 'age': 19, 'city': 'Dubai'},
          'u5': {'name': 'Eve', 'age': 28, 'city': 'Riyadh'},
          'u6': {'name': 'Frank', 'age': 45, 'city': 'Cairo'},
        });

        final buf = StringBuffer();
        buf.writeln('=== Query Builder Demo ===\n');

        buf.writeln('--- All users age > 25, sorted by name ---');
        final adults = await box
            .query()
            .where('age', greaterThan: 25)
            .sortBy('name')
            .findAll();
        for (final u in adults) {
          buf.writeln('  $u');
        }

        buf.writeln('\n--- Users in Cairo, sorted by age desc ---');
        final cairo = await box
            .query()
            .where('city', equalTo: 'Cairo')
            .sortByDesc('age')
            .findAll();
        for (final u in cairo) {
          buf.writeln('  $u');
        }

        buf.writeln('\n--- First 2 users, offset 1 ---');
        final paged =
            await box.query().sortBy('name').offset(1).limit(2).findAll();
        for (final u in paged) {
          buf.writeln('  $u');
        }

        buf.writeln('\n--- Count of users age >= 28 ---');
        final cnt =
            await box.query().where('age', greaterThanOrEqual: 28).count();
        buf.writeln('  Count: $cnt');

        buf.writeln('\n--- Names starting with "A" ---');
        final startsA =
            await box.query().where('name', startsWith: 'A').findAll();
        for (final u in startsA) {
          buf.writeln('  $u');
        }

        await box.close();
        return buf.toString();
      },
    );
  }
}
