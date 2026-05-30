import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class AggregationDemoPage extends StatelessWidget {
  const AggregationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Aggregation',
      description: 'MongoDB-style aggregation pipeline',
      codeExample:
          "AggregationPipeline()\n  .match((doc) => doc['price'] > 20)\n  .group('category', [AggregationOp('sum', AggregationOpType.sum)])\n  .sort('sum', descending: true)\n  .execute(box);",
      runDemo: () async {
        final box = await Rift.openBox<Map>('agg_demo');
        await box.clear();
        final buf = StringBuffer();
        buf.writeln('=== Aggregation Pipeline Demo ===\n');

        // Insert sales data
        await box.putAll({
          's1': {
            'product': 'Widget',
            'category': 'Tools',
            'price': 25,
            'qty': 10
          },
          's2': {
            'product': 'Gadget',
            'category': 'Electronics',
            'price': 99,
            'qty': 5
          },
          's3': {
            'product': 'Screwdriver',
            'category': 'Tools',
            'price': 15,
            'qty': 20
          },
          's4': {
            'product': 'Phone',
            'category': 'Electronics',
            'price': 499,
            'qty': 2
          },
          's5': {
            'product': 'Hammer',
            'category': 'Tools',
            'price': 30,
            'qty': 8
          },
          's6': {
            'product': 'Tablet',
            'category': 'Electronics',
            'price': 299,
            'qty': 3
          },
        });
        buf.writeln('Inserted 6 sales records\n');

        // Pipeline: group by category, sum price, avg qty
        buf.writeln('--- Group by Category: sum(price), avg(qty), count ---');
        final pipeline1 = AggregationPipeline().group('category', [
          AggregationOp('totalPrice', AggregationOpType.sum,
              inputField: 'price'),
          AggregationOp('avgQty', AggregationOpType.avg, inputField: 'qty'),
          AggregationOp('count', AggregationOpType.count),
          AggregationOp('maxPrice', AggregationOpType.max, inputField: 'price'),
          AggregationOp('minPrice', AggregationOpType.min, inputField: 'price'),
        ]);
        final result1 = await pipeline1.execute(box);
        for (final doc in result1) {
          buf.writeln('  $doc');
        }

        // Pipeline: match + sort + limit
        buf.writeln('\n--- Match price > 20, sort by price desc, limit 3 ---');
        final pipeline2 = AggregationPipeline()
            .match((doc) => (doc['price'] as num?)?.compareTo(20) == 1)
            .sort('price', descending: true)
            .limit(3);
        final result2 = await pipeline2.execute(box);
        for (final doc in result2) {
          buf.writeln('  ${doc['product']}: \$${doc['price']}');
        }

        // Pipeline: project
        buf.writeln('\n--- Project: name + total value ---');
        final pipeline3 = AggregationPipeline()
            .addFields((doc) =>
                {'totalValue': (doc['price'] as num) * (doc['qty'] as num)})
            .project((doc) =>
                {'product': doc['product'], 'totalValue': doc['totalValue']})
            .sort('totalValue', descending: true);
        final result3 = await pipeline3.execute(box);
        for (final doc in result3) {
          buf.writeln('  $doc');
        }

        // Pipeline: count
        buf.writeln('\n--- Count All ---');
        final pipeline4 = AggregationPipeline().count('total');
        final result4 = await pipeline4.execute(box);
        buf.writeln('  $result4');

        await box.close();
        return buf.toString();
      },
    );
  }
}
