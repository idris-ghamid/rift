import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class FtsDemoPage extends StatelessWidget {
  const FtsDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Full-Text Search',
      description: 'Full-text search with TF-IDF scoring and stemming',
      codeExample:
          "engine.indexDocument('doc1',\n    {'title': '...', 'body': '...'});\nengine.search(FTSQuery(\n    terms: ['dart'],\n    operator: FTSSearchOperator.and));",
      runDemo: () async {
        final engine = FTSEngine();
        final buf = StringBuffer();
        buf.writeln('=== Full-Text Search Demo ===\n');

        engine.indexDocument('doc1', {
          'title': 'Introduction to Dart Programming',
          'body':
              'Dart is a client-optimized language for fast apps on any platform.',
        });
        engine.indexDocument('doc2', {
          'title': 'Flutter Development Guide',
          'body':
              'Build beautiful UIs with Flutter and Dart for mobile and web.',
        });
        engine.indexDocument('doc3', {
          'title': 'Database Design Patterns',
          'body':
              'Learn about indexing, query optimization, and data modeling.',
        });
        engine.indexDocument('doc4', {
          'title': 'Advanced Dart Techniques',
          'body':
              'Explore isolates, streams, and advanced async programming in Dart.',
        });
        buf.writeln('Indexed ${engine.documentCount} documents');
        buf.writeln(
            'Tokens: ${engine.tokenCount}, Entries: ${engine.entryCount}\n');

        buf.writeln('--- AND search: "dart programming" ---');
        final andResults = engine.search(FTSQuery(
          terms: ['dart', 'programming'],
          operator: FTSSearchOperator.and,
        ));
        for (final r in andResults) {
          buf.writeln('  ${r.key} (score: ${r.score.toStringAsFixed(3)})');
          buf.writeln('    Snippet: ${r.snippet}');
        }

        buf.writeln('\n--- OR search: "flutter database" ---');
        final orResults = engine.search(FTSQuery(
          terms: ['flutter', 'database'],
          operator: FTSSearchOperator.or,
        ));
        for (final r in orResults) {
          buf.writeln('  ${r.key} (score: ${r.score.toStringAsFixed(3)})');
        }

        buf.writeln('\n--- Phrase search: "dart programming" ---');
        final phraseResults = engine.search(FTSQuery(
          terms: ['dart', 'programming'],
          operator: FTSSearchOperator.phrase,
        ));
        for (final r in phraseResults) {
          buf.writeln('  ${r.key} (score: ${r.score.toStringAsFixed(3)})');
        }

        buf.writeln('\n--- AND search: "dart" NOT "flutter" ---');
        final notResults = engine.search(FTSQuery(
          terms: ['dart'],
          notTerms: ['flutter'],
          operator: FTSSearchOperator.and,
        ));
        for (final r in notResults) {
          buf.writeln('  ${r.key} (score: ${r.score.toStringAsFixed(3)})');
        }

        buf.writeln('\n--- FTS Stats ---');
        buf.writeln('  ${engine.getStats()}');

        buf.writeln('\n--- Stemming Examples ---');
        buf.writeln('  "running" → "${engine.stem("running")}"');
        buf.writeln('  "databases" → "${engine.stem("databases")}"');
        buf.writeln('  "optimization" → "${engine.stem("optimization")}"');

        return buf.toString();
      },
    );
  }
}
