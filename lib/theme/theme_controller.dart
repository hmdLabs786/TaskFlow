import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeController extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _themeKey = 'theme_mode';
  late Box _box;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final savedTheme = _box.get(_themeKey, defaultValue: 'light');
    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  static const Color primaryColor = Color(0xFF1A73E8);

  ThemeData get lightTheme {
    const surface = Color(0xFFFFFFFF);
    const background = Color(0xFFF8F9FA);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: primaryColor,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: Color(0xFF202124),
        surfaceContainerHighest: Color(0xFFF1F3F4),
        onSurfaceVariant: Color(0xFF5F6368),
        error: Color(0xFFD93025),
        onError: Colors.white,
        outline: Color(0xFFDADCE0),
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF202124),
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        iconTheme: IconThemeData(color: Color(0xFF5F6368)),
      ),
      cardTheme: const CardTheme(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: const Color(0xFF323232),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    const surface = Color(0xFF2D2D2D);
    const background = Color(0xFF1F1F1F);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF8AB4F8),
        onPrimary: Color(0xFF1F1F1F),
        secondary: Color(0xFF8AB4F8),
        onSecondary: Color(0xFF1F1F1F),
        surface: surface,
        onSurface: Color(0xFFE8EAED),
        surfaceContainerHighest: Color(0xFF3C4043),
        onSurfaceVariant: Color(0xFF9AA0A6),
        outline: Color(0xFF5F6368),
        error: Color(0xFFF28B82),
        onError: Color(0xFF1F1F1F),
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFE8EAED),
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        iconTheme: IconThemeData(color: Color(0xFF9AA0A6)),
      ),
      cardTheme: const CardTheme(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF5F6368)),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF5F6368)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8AB4F8), width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF5F6368),
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _box.put(_themeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }
}
