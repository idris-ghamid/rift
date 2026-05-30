import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class MiddlewareDemoPage extends StatelessWidget {
  const MiddlewareDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Middleware',
      description: 'Logging and validation middleware hooks',
      codeExample:
          "Rift.use(LoggingMiddleware(\n    level: LogLevel.debug));\nRift.use(ValidationMiddleware(\n    schemas: [...]));",
      runDemo: () async {
        final box = await Rift.openBox<Map>('middleware_demo');
        await box.clear();
        final buf = StringBuffer();
        buf.writeln('=== Middleware Demo ===\n');

        final logMessages = <String>[];
        final logging = LoggingMiddleware(
          level: LogLevel.debug,
          includeValues: true,
          includeTimestamps: false,
          logger: (msg) => logMessages.add(msg),
        );
        buf.writeln('Added LoggingMiddleware (debug level)');

        final validationErrors = <String>[];
        final validation = ValidationMiddleware(
          schemas: [
            ValidationSchema(
              boxName: 'middleware_demo',
              rules: [
                const ValidationRule(
                    field: 'name', required: true, type: String),
                const ValidationRule(field: 'age', type: int, min: 0, max: 150),
                ValidationRule(
                    field: 'email',
                    validator: (v) {
                      if (v is! String || !v.contains('@'))
                        return 'Invalid email';
                      return null;
                    }),
              ],
            ),
          ],
          onError: (boxName, key, error) =>
              validationErrors.add('$key: $error'),
        );
        buf.writeln('Added ValidationMiddleware');

        final chain = MiddlewareChain();
        chain.add(validation);
        chain.add(logging);

        buf.writeln('\n--- Valid Put ---');
        final validData = {
          'name': 'Alice',
          'age': 30,
          'email': 'alice@example.com'
        };
        final allowed1 =
            await chain.runBeforePut('middleware_demo', 'user1', validData);
        buf.writeln('  Allowed: $allowed1');
        if (allowed1) {
          await box.put('user1', validData);
          await chain.runAfterPut('middleware_demo', 'user1', validData);
          buf.writeln('  Stored: ${box.get('user1')}');
        }

        buf.writeln('\n--- Invalid Put (missing name, age=200) ---');
        final invalidData = {'age': 200, 'email': 'not-an-email'};
        final allowed2 =
            await chain.runBeforePut('middleware_demo', 'user2', invalidData);
        buf.writeln('  Allowed: $allowed2');
        if (!allowed2) {
          buf.writeln('  Validation errors: $validationErrors');
        }

        buf.writeln('\n--- Log Messages ---');
        for (final msg in logMessages) {
          buf.writeln('  $msg');
        }

        buf.writeln('\n--- Chain Info ---');
        buf.writeln('  Middleware count: ${chain.length}');
        buf.writeln(
            '  Middleware: ${chain.middlewares.map((m) => m.name).toList()}');

        await box.close();
        return buf.toString();
      },
    );
  }
}
