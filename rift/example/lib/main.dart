import 'package:flutter/material.dart';
import 'package:rift_flutter/rift_flutter.dart';
import 'home_page.dart';
import 'systems/theme_system.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Rift.initFlutter('rift_demo');

  // Load theme preferences
  await ThemeSystem().loadThemePreference();

  runApp(const RiftDemoApp());
}

class RiftDemoApp extends StatefulWidget {
  const RiftDemoApp({super.key});

  static void toggleTheme(BuildContext context) {
    context.findAncestorStateOfType<RiftDemoAppState>()?.toggleTheme();
  }

  @override
  State<RiftDemoApp> createState() => RiftDemoAppState();
}

class RiftDemoAppState extends State<RiftDemoApp> {
  final ThemeSystem _themeSystem = ThemeSystem();

  void toggleTheme() {
    setState(() {
      _themeSystem.toggleTheme();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rift Database',
      debugShowCheckedModeBanner: false,
      themeMode: _themeSystem.currentMode,
      theme: _themeSystem.getLightTheme(),
      darkTheme: _themeSystem.getDarkTheme(),
      home: const HomePage(),
    );
  }
}
