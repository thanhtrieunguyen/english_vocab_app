import 'package:flutter/material.dart';

class AppColors {
  // Light theme colors
  static const Color lightPrimary = Color(0xFF00BCD4);
  static const Color lightSecondary = Color(0xFF6C63FF);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Colors.white;
  static const Color lightOnSurface = Color(0xFF2D3748);
  static const Color lightBorder = Color(0xFFE2E8F0);
  
  // Dark theme colors
  static const Color darkPrimary = Color(0xFF26C6DA);
  static const Color darkSecondary = Color(0xFF7C4DFF);
  static const Color darkBackground = Color(0xFF1A202C);
  static const Color darkSurface = Color(0xFF2D3748);
  static const Color darkOnSurface = Color(0xFFF7FAFC);
  static const Color darkBorder = Color(0xFF4A5568);
}

class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF00BCD4),
      primaryContainer: Color(0xFFE0F7FA),
      secondary: Color(0xFF6C63FF),
      secondaryContainer: Color(0xFFF3F0FF),
      surface: Color(0xFFF8F9FA),
      surfaceContainer: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF2D3748),
      onSurfaceVariant: Color(0xFF4A5568),
      outline: Color(0xFFE2E8F0),
      error: Color(0xFFE53E3E),
    ),
    cardTheme: const CardThemeData(
      elevation: 8,
      shadowColor: Color(0x1A000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF26C6DA),
      primaryContainer: Color(0xFF004D5C),
      secondary: Color(0xFF7C4DFF),
      secondaryContainer: Color(0xFF3F2A7A),
      surface: Color(0xFF1A202C),
      surfaceContainer: Color(0xFF2D3748),
      onPrimary: Color(0xFF1A202C),
      onSecondary: Colors.white,
      onSurface: Color(0xFFF7FAFC),
      onSurfaceVariant: Color(0xFFE2E8F0),
      outline: Color(0xFF4A5568),
      error: Color(0xFFFC8181),
    ),
    cardTheme: const CardThemeData(
      elevation: 8,
      shadowColor: Color(0x4D000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4A5568)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4A5568)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF26C6DA), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFF2D3748),
    ),
  );
}
