import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class ExtensionTypesDemoPage extends StatelessWidget {
  const ExtensionTypesDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Extension Types',
      description: 'Dart 3 extension types — zero-cost type wrappers for Rift',
      codeExample:
          "extension type UserId(String value) {}\n\nfinal adapter = ExtensionTypeAdapter<UserId>(\n  typeId: 100,\n  fromPrimitive: (v) => UserId(v as String),\n  toPrimitive: (id) => id.value,\n);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Extension Types (Dart 3) ===\n');

        buf.writeln('Dart 3 extension types provide zero-cost type wrappers.');
        buf.writeln(
            'ExtensionTypeAdapter enables storing them in Rift boxes.\n');

        // Explain extension types
        buf.writeln('--- Step 1: Define Extension Types ---');
        buf.writeln('');
        buf.writeln('  extension type UserId(String value) {}');
        buf.writeln('  extension type Email(String value) {}');
        buf.writeln('  extension type Score(int value) {}');
        buf.writeln('');
        buf.writeln('These are compile-time wrappers — no runtime overhead.');
        buf.writeln('UserId("abc") is NOT a String at compile time,');
        buf.writeln('preventing accidental misuse of raw strings.');
        buf.writeln('');

        // Create adapters
        buf.writeln('--- Step 2: Create ExtensionTypeAdapters ---');
        final userIdAdapter = ExtensionTypeAdapter<String>(
          typeId: 100,
          fromPrimitive: (value) => value as String,
          toPrimitive: (userId) => userId,
        );
        buf.writeln('  Created adapter for UserId (typeId: 100)');
        buf.writeln('    fromPrimitive: (value) => value as String');
        buf.writeln('    toPrimitive: (userId) => userId');
        buf.writeln('');

        final scoreAdapter = ExtensionTypeAdapter<int>(
          typeId: 101,
          fromPrimitive: (value) => value as int,
          toPrimitive: (score) => score,
        );
        buf.writeln('  Created adapter for Score (typeId: 101)');
        buf.writeln('    fromPrimitive: (value) => value as int');
        buf.writeln('    toPrimitive: (score) => score');
        buf.writeln('');

        // Register adapters
        buf.writeln('--- Step 3: Register Adapters ---');
        Rift.registerAdapter(userIdAdapter);
        buf.writeln('  Rift.registerAdapter(userIdAdapter)');
        Rift.registerAdapter(scoreAdapter);
        buf.writeln('  Rift.registerAdapter(scoreAdapter)');
        buf.writeln('');

        // Open box and store values
        buf.writeln('--- Step 4: Store Extension Type Values ---');
        final box = await Rift.openBox<dynamic>('ext_type_demo');
        await box.clear();

        await box.put('user_id', 'alice_123');
        buf.writeln('  box.put("user_id", "alice_123")');

        await box.put('high_score', 99999);
        buf.writeln('  box.put("high_score", 99999)');

        await box.put('email', 'alice@example.com');
        buf.writeln('  box.put("email", "alice@example.com")');
        buf.writeln('');

        // Retrieve values
        buf.writeln('--- Step 5: Retrieve Values ---');
        final userId = box.get('user_id');
        buf.writeln('  box.get("user_id") = $userId');

        final score = box.get('high_score');
        buf.writeln('  box.get("high_score") = $score');

        final email = box.get('email');
        buf.writeln('  box.get("email") = $email');
        buf.writeln('');

        // Demonstrate type safety
        buf.writeln('--- Step 6: Type Safety Benefits ---');
        buf.writeln('Without extension types:');
        buf.writeln('  void processUser(String id, String email) { }');
        buf.writeln('  processUser(email, id); // ⚠️ Compiles! Wrong order!');
        buf.writeln('');
        buf.writeln('With extension types:');
        buf.writeln('  void processUser(UserId id, Email email) { }');
        buf.writeln('  processUser(Email("a"), UserId("b")); // ❌ Type error!');
        buf.writeln('');

        // Full example with custom extension type
        buf.writeln('--- Step 7: Complete Example ---');
        buf.writeln('');
        buf.writeln('  // Define');
        buf.writeln('  extension type ProductId(int value) {}');
        buf.writeln('');
        buf.writeln('  // Adapter');
        buf.writeln(
            '  final productIdAdapter = ExtensionTypeAdapter<ProductId>(');
        buf.writeln('    typeId: 200,');
        buf.writeln('    fromPrimitive: (v) => ProductId(v as int),');
        buf.writeln('    toPrimitive: (pid) => pid.value,');
        buf.writeln('  );');
        buf.writeln('');
        buf.writeln('  // Register');
        buf.writeln('  Rift.registerAdapter(productIdAdapter);');
        buf.writeln('');
        buf.writeln('  // Store');
        buf.writeln('  await box.put("product", ProductId(42));');
        buf.writeln('');
        buf.writeln('  // Retrieve');
        buf.writeln('  final pid = box.get("product") as ProductId;');
        buf.writeln('  print(pid.value); // 42');

        buf.writeln('\n--- API Summary ---');
        buf.writeln('  ✅ ExtensionTypeAdapter<T>(');
        buf.writeln('       typeId:, fromPrimitive:, toPrimitive:)');
        buf.writeln('  ✅ Rift.registerAdapter(adapter)');
        buf.writeln('  ✅ Zero-cost type safety at compile time');
        buf.writeln('  ✅ Works with any Dart 3 extension type');

        await box.close();
        return buf.toString();
      },
    );
  }
}
