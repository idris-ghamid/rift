import 'package:flutter/material.dart';
import 'package:rift_flutter/rift_flutter.dart';

const counterBox = 'counter';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final box = await Hive.openBox(counterBox);
  if (box.isEmpty) {
    await box.add(0);
  }
  runApp(const MaterialApp(home: RiftCounterApp()));
}

class RiftCounterApp extends StatelessWidget {
  const RiftCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    final box = Hive.box(counterBox);

    return Scaffold(
      appBar: AppBar(title: const Text('Rift Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, box, widget) {
                return Text(
                  box.getAt(0).toString(),
                  style: textTheme.headlineMedium,
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => box.putAt(0, box.getAt(0) + 1),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
