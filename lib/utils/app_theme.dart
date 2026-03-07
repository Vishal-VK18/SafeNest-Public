// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ─── Primary palette ────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFFBCAFD0); // Pastel lilac
  static const Color primaryDark   = Color(0xFF8C7FB2); // Deep lilac
  static const Color bgLight       = Color(0xFFF7F6F7); // Soft off-white
  static const Color bgDark        = Color(0xFF18161C); // Near-black

  // ─── Card / surface ─────────────────────────────────────────────────────────
  static const Color softGray      = Color(0xFFF5F5F7);
  static const Color softLilac     = Color(0xFFF3F0F7);
  static const Color lilacAccent   = Color(0xFFF2EFFF);
  static const Color deepLavender  = Color(0xFF6A13EC);
  static const Color lavenderText  = Color(0xFF4A3F92);

  // ─── Status ─────────────────────────────────────────────────────────────────
  static const Color statusGreen  = Color(0xFF7EBC89);
  static const Color successLight = Color(0xFFA8D5BA);
  static const Color warningYellow = Color(0xFFF4E0AF);
  static const Color dangerRed    = Color(0xFFE85C5C);
  static const Color alertOrange  = Color(0xFFFF9800);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
    ),
    scaffoldBackgroundColor: AppColors.bgLight,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF1F3D3D),
      selectionColor: Color(0x33FFC09D),
      selectionHandleColor: Color(0xFFFFC09D),
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(fontSize: 16),
      bodyMedium: GoogleFonts.inter(fontSize: 14),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1C1C1E),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1C1C1E)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 0,
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
  );
}
