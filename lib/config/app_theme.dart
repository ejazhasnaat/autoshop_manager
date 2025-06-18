// lib/config/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Make sure google_fonts is in pubspec.yaml

class AppTheme {
  // Define a static light theme
  static ThemeData lightTheme() {
    final ColorScheme lightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blueAccent, // Your primary brand color
      brightness: Brightness.light,
      primary: Colors.blueAccent,
      onPrimary: Colors.white,
      secondary: Colors.teal,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.grey.shade900,
      background: Colors.grey.shade50,
      onBackground: Colors.grey.shade900,
      error: Colors.red.shade700,
      onError: Colors.white,
    );

    return ThemeData(
      colorScheme: lightColorScheme,
      useMaterial3: true, // Enable Material 3 features
      fontFamily: GoogleFonts.poppins().fontFamily, // Modern sans-serif font

      appBarTheme: AppBarTheme(
        backgroundColor:
            lightColorScheme.surface, // Match surface for clean look
        foregroundColor: lightColorScheme.onSurface,
        elevation: 0, // No shadow
        centerTitle: false, // Left-align title for modern feel
        titleTextStyle: GoogleFonts.poppins(
          textStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: lightColorScheme.onSurface,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1, // Subtle shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ), // Rounded corners
        surfaceTintColor: Colors.white, // No tint by default
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // Rounded text fields
          borderSide: BorderSide.none, // No border line initially
        ),
        filled: true,
        fillColor: lightColorScheme.surfaceVariant.withOpacity(
          0.3,
        ), // Light fill color
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(
          color: lightColorScheme.onSurface.withOpacity(0.7),
        ),
        hintStyle: TextStyle(
          color: lightColorScheme.onSurface.withOpacity(0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: lightColorScheme.outline.withOpacity(0.5),
          ), // Light border when enabled
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: lightColorScheme.primary,
            width: 2.0,
          ), // Primary color border when focused
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.error, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.error, width: 2.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          elevation: 2, // Subtle shadow
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightColorScheme.primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightColorScheme.primary,
          side: BorderSide(color: lightColorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
      // Add more theme properties as needed (e.g., dialogTheme, bottomAppBarTheme)
    );
  }

  // You can define a dark theme here as well if needed
  // static ThemeData darkTheme() { ... }
}
