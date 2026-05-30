import 'package:flutter/material.dart';
import 'dart:math';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class VectorSearchDemoPage extends StatelessWidget {
  const VectorSearchDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Vector Search',
      description: 'Vector similarity search for AI/embeddings',
      codeExample:
          "final vs = VectorSearch(dimensions: 128, metric: DistanceMetric.cosine);\nvs.index('doc1', embedding);\nfinal results = vs.search(query, k: 10);",
      runDemo: () async {
        final rng = Random(42);
        final vs = VectorSearch(dimensions: 3, metric: DistanceMetric.cosine);
        final buf = StringBuffer();
        buf.writeln('=== Vector Search Demo ===\n');
        buf.writeln('Dimensions: 3, Metric: cosine\n');

        // Index vectors (3D embeddings)
        vs.index('apple', [0.9, 0.1, 0.1]);
        vs.index('banana', [0.8, 0.2, 0.1]);
        vs.index('car', [0.1, 0.1, 0.9]);
        vs.index('cat', [0.1, 0.2, 0.8]);
        vs.index('dog', [0.15, 0.15, 0.85]);
        vs.index('cherry', [0.85, 0.1, 0.15]);
        buf.writeln('Indexed ${vs.size} vectors:');
        buf.writeln('  apple:  [0.9, 0.1, 0.1]  (fruit-like)');
        buf.writeln('  banana: [0.8, 0.2, 0.1]  (fruit-like)');
        buf.writeln('  cherry: [0.85, 0.1, 0.15] (fruit-like)');
        buf.writeln('  car:    [0.1, 0.1, 0.9]  (vehicle/animal-like)');
        buf.writeln('  cat:    [0.1, 0.2, 0.8]  (animal-like)');
        buf.writeln('  dog:    [0.15, 0.15, 0.85] (animal-like)');

        // KNN search
        buf.writeln('\n--- KNN Search: fruit-like [0.85, 0.1, 0.15], k=3 ---');
        final knnResults = vs.search([0.85, 0.1, 0.15], k: 3);
        for (final r in knnResults) {
          buf.writeln('  ${r.key}: distance=${r.distance.toStringAsFixed(4)}');
        }

        // Radius search
        buf.writeln(
            '\n--- Radius Search: near [0.1, 0.15, 0.85], radius=0.3 ---');
        final radiusResults = vs.searchRadius([0.1, 0.15, 0.85], 0.3);
        for (final r in radiusResults) {
          buf.writeln('  ${r.key}: distance=${r.distance.toStringAsFixed(4)}');
        }

        // Euclidean metric
        buf.writeln('\n--- Euclidean Distance ---');
        final vsEuc =
            VectorSearch(dimensions: 3, metric: DistanceMetric.euclidean);
        vsEuc.index('a', [1.0, 0.0, 0.0]);
        vsEuc.index('b', [0.0, 1.0, 0.0]);
        vsEuc.index('c', [0.0, 0.0, 1.0]);
        final eucResults = vsEuc.search([1.0, 0.0, 0.0], k: 3);
        for (final r in eucResults) {
          buf.writeln('  ${r.key}: euclidean=${r.distance.toStringAsFixed(4)}');
        }

        return buf.toString();
      },
    );
  }
}
