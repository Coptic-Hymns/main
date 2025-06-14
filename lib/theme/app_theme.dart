import 'package:flutter/material.dart';

class AppTheme {
  // Coptic Orthodox Church colors
  static const Color primaryColor = Color(0xFF8B0000); // Deep Red
  static const Color secondaryColor = Color(0xFFD4AF37); // Gold
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color textColor = Color(0xFF333333); // Dark Gray
  static const Color accentColor = Color(0xFF4A90E2); // Blue

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
        background: backgroundColor,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: textColor,
        onSurface: textColor,
        onBackground: textColor,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryColor.withAlpha(26),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withAlpha(128)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
