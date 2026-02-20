import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color darkBg = Color(0xFF0F0F0F);
  static const Color cardBg = Color(0xFF1A1A1A);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primaryGold,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: primaryGold,
        surface: cardBg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryGold,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: primaryGold,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            titleLarge: const TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: const TextStyle(color: Colors.white),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      primaryColor: primaryGold,
      colorScheme: const ColorScheme.light(
        primary: primaryGold,
        secondary: primaryGold,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryGold,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme)
          .copyWith(
            titleLarge: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: const TextStyle(color: Colors.black87),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryGold),
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGold, width: 1.5),
      ),
    );
  }
}
