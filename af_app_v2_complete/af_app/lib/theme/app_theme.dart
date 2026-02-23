import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Light palette ──────────────────────────────────────────
  static const Color primary        = Color(0xFF2563EB);
  static const Color secondary      = Color(0xFF10B981);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color danger         = Color(0xFFEF4444);
  static const Color surface        = Color(0xFFF8FAFC);
  static const Color card           = Color(0xFFFFFFFF);
  static const Color textPrimary    = Color(0xFF1E293B);
  static const Color textSecondary  = Color(0xFF64748B);
  static const Color border         = Color(0xFFE2E8F0);

  // ── Dark palette ───────────────────────────────────────────
  static const Color darkSurface       = Color(0xFF0F172A);
  static const Color darkCard          = Color(0xFF1E293B);
  static const Color darkTextPrimary   = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder        = Color(0xFF334155);

  // ── Risk / AF colours (same in both modes) ─────────────────
  static const Color riskLow      = Color(0xFF10B981);
  static const Color riskModerate = Color(0xFFF59E0B);
  static const Color riskHigh     = Color(0xFFEF4444);
  static const Color afNormal     = Color(0xFF10B981);
  static const Color afPossible   = Color(0xFFEF4444);
  static const Color afInconclusive = Color(0xFFF59E0B);

  // ── Text theme helper ──────────────────────────────────────
  static TextTheme _textTheme(Color primary, Color secondary, double scale) {
    double s(double base) => base * scale;
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge:   GoogleFonts.inter(fontSize: s(32), fontWeight: FontWeight.w700, color: primary),
      displayMedium:  GoogleFonts.inter(fontSize: s(26), fontWeight: FontWeight.w700, color: primary),
      headlineMedium: GoogleFonts.inter(fontSize: s(20), fontWeight: FontWeight.w600, color: primary),
      titleLarge:     GoogleFonts.inter(fontSize: s(17), fontWeight: FontWeight.w600, color: primary),
      titleMedium:    GoogleFonts.inter(fontSize: s(15), fontWeight: FontWeight.w500, color: primary),
      bodyLarge:      GoogleFonts.inter(fontSize: s(15), fontWeight: FontWeight.w400, color: primary),
      bodyMedium:     GoogleFonts.inter(fontSize: s(13), fontWeight: FontWeight.w400, color: secondary),
      labelLarge:     GoogleFonts.inter(fontSize: s(13), fontWeight: FontWeight.w600, color: primary),
    );
  }

  // ── Light theme ────────────────────────────────────────────
  static ThemeData lightTheme({double fontScale = 1.0}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
          seedColor: primary, brightness: Brightness.light, surface: surface),
      scaffoldBackgroundColor: surface,
      textTheme: _textTheme(textPrimary, textSecondary, fontScale),
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 18 * fontScale, fontWeight: FontWeight.w600,
            color: textPrimary),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: card, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary, foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
              fontSize: 15 * fontScale, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
              fontSize: 15 * fontScale, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2)),
        labelStyle: GoogleFonts.inter(color: textSecondary,
            fontSize: 14 * fontScale),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  // ── Dark theme ─────────────────────────────────────────────
  static ThemeData darkTheme({double fontScale = 1.0}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
          seedColor: primary, brightness: Brightness.dark,
          surface: darkSurface),
      scaffoldBackgroundColor: darkSurface,
      textTheme: _textTheme(darkTextPrimary, darkTextSecondary, fontScale),
      appBarTheme: AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 18 * fontScale, fontWeight: FontWeight.w600,
            color: darkTextPrimary),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkCard, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary, foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
              fontSize: 15 * fontScale, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
              fontSize: 15 * fontScale, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2)),
        labelStyle: GoogleFonts.inter(color: darkTextSecondary,
            fontSize: 14 * fontScale),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: primary,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  // kept for legacy references in existing widgets
  static ThemeData get theme => lightTheme();
}
