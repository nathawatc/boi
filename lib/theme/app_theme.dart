import 'package:flutter/material.dart';

class AppTheme {
  static const Color gradientStart = Color(0xFF65D2FE); // Light Sky Blue
  static const Color gradientEnd = Color(0xFF80E185);   // Light Green

  // Backwards compatibility for existing code using Green as primary
  static const Color primaryGreen = gradientEnd;
  static const Color primaryBlue = gradientStart;
  static const Color primarySky = gradientStart;

  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF64D2FF), // Vibrant Blue
      Color(0xFF80E1B8), // Smooth Aqua/Mint transition
      Color(0xFF80E185), // Final Soft Green
    ],
    stops: [0.0, 0.85, 1.0],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: gradientStart,
      scaffoldBackgroundColor: const Color(0xFFF9FBF9),
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: gradientStart,
        primary: gradientStart,
        secondary: gradientEnd,
        surface: Colors.white,
        onPrimary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gradientStart,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: gradientStart,
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: gradientStart,
        brightness: Brightness.dark,
        primary: gradientStart,
        secondary: gradientEnd,
        surface: const Color(0xFF1E1E1E),
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gradientStart,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: gradientStart,
        textColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2C2C2C),
      ),
    );
  }
}
