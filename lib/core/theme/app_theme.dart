import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryAccent = Color(0xFF60A5FA); // Original lighter blue
  static const Color secondaryGreen = Color(0xFF10B981);
  static const Color darkText = Color(0xFF1F2937);
  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color surfaceWhite = Colors.white;
  static const Color errorRed = Color(0xFFEF4444);

  // Text Styles
  static TextTheme textTheme = GoogleFonts.poppinsTextTheme().apply(
    bodyColor: darkText,
    displayColor: darkText,
  );

  // Input Decoration
  static InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: Icon(icon, color: primaryBlue.withOpacity(0.6), size: 22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryAccent, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      // Soft shadow effect workaround via Container in usage, but here we keep it clean
    );
  }

  // Button Style
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
  );
  
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      background: lightBackground,
      primary: primaryBlue,
      secondary: primaryAccent,
      surface: surfaceWhite,
    ),
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardTheme(
      color: surfaceWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    )
  );
}
