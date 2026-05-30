import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home_page.dart';

/// Theme system for managing app-wide theming
class ThemeSystem {
  // Singleton pattern
  static final ThemeSystem _instance = ThemeSystem._internal();
  factory ThemeSystem() => _instance;
  ThemeSystem._internal();

  // Shared preferences key
  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';

  // Current theme mode
  ThemeMode _currentMode = ThemeMode.system;
  ThemeMode get currentMode => _currentMode;

  // Current accent color
  Color _accentColor = const Color(0xFF007AFF);
  Color get accentColor => _accentColor;

  // Primary color palette (Apple Blue with 5 shades)
  static const Color primary50 = Color(0xFFE3F2FF);
  static const Color primary100 = Color(0xFFB3DBFF);
  static const Color primary200 = Color(0xFF80C4FF);
  static const Color primary300 = Color(0xFF4DACFF);
  static const Color primary400 = Color(0xFF269AFF);
  static const Color primary500 = Color(0xFF007AFF); // Main
  static const Color primary600 = Color(0xFF0066D6);
  static const Color primary700 = Color(0xFF0052AD);
  static const Color primary800 = Color(0xFF003D84);
  static const Color primary900 = Color(0xFF00295B);

  // Category colors
  static const Map<FeatureCategory, Color> categoryColors = {
    FeatureCategory.queries: Color(0xFF007AFF), // Blue
    FeatureCategory.data: Color(0xFF5856D6), // Purple
    FeatureCategory.security: Color(0xFFFF3B30), // Red
    FeatureCategory.performance: Color(0xFFFF9500), // Orange
    FeatureCategory.sync: Color(0xFF34C759), // Green
    FeatureCategory.tools: Color(0xFFAF52DE), // Violet
    FeatureCategory.platform: Color(0xFF5AC8FA), // Cyan
  };

  // Semantic colors
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Background colors
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color darkBackground = Color(0xFF000000);

  // Surface colors
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF1C1C1E);

  /// Get category color
  Color getCategoryColor(FeatureCategory category) {
    return categoryColors[category] ?? primary500;
  }

  /// Get light color scheme
  ColorScheme getLightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: _accentColor,
      brightness: Brightness.light,
      primary: _accentColor,
      secondary: primary300,
      surface: lightSurface,
      error: error,
    );
  }

  /// Get dark color scheme
  ColorScheme getDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: _accentColor,
      brightness: Brightness.dark,
      primary: _accentColor,
      secondary: primary300,
      surface: darkSurface,
      error: error,
    );
  }

  /// Get text theme
  TextTheme getTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.bold,
        letterSpacing: -1.5,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Set theme mode
  void setThemeMode(ThemeMode mode) {
    _currentMode = mode;
    saveThemePreference();
  }

  /// Toggle theme (light → dark → system → light)
  void toggleTheme() {
    switch (_currentMode) {
      case ThemeMode.light:
        _currentMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _currentMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        _currentMode = ThemeMode.light;
        break;
    }
    saveThemePreference();
  }

  /// Set accent color
  void setAccentColor(Color color) {
    _accentColor = color;
    saveThemePreference();
  }

  /// Save theme preference to shared preferences
  Future<void> saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, _currentMode.index);
    await prefs.setInt(_accentColorKey, _accentColor.value.toInt());
  }

  /// Load theme preference from shared preferences
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_themeModeKey);
    final colorValue = prefs.getInt(_accentColorKey);

    if (modeIndex != null) {
      _currentMode = ThemeMode.values[modeIndex];
    }

    if (colorValue != null) {
      _accentColor = Color(colorValue);
    }
  }

  /// Get light theme data
  ThemeData getLightTheme() {
    final colorScheme = getLightColorScheme();

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: null,
      textTheme: getTextTheme(),
      scaffoldBackgroundColor: lightBackground,
      cardTheme: CardThemeData(
        elevation: 0,
        color: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.primary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// Get dark theme data
  ThemeData getDarkTheme() {
    final colorScheme = getDarkColorScheme();

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: null,
      textTheme: getTextTheme(),
      scaffoldBackgroundColor: darkBackground,
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.primary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
