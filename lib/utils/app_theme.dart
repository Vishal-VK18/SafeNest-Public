// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ─── SafeNest Primary palette ──────────────────────────────────────────────
  static const Color primary       = Color(0xFFFFC09D); // Primary Peach
  static const Color blush         = Color(0xFFFFCACB); // Blush Pink
  static const Color accent        = Color(0xFFE9A48E); // Accent Peach
  static const Color creamBg       = Color(0xFFFFF8F5); // Cream Background
  
  static const Color primaryText   = Color(0xFF181818); // Primary Text
  static const Color secondaryText = Color(0xFF6B6B6B); // Secondary Text
  static const Color bgLight       = Color(0xFFFFFDFB); // Soft off-white
  static const Color bgDark        = Color(0xFF18161C); // Near-black

  // Legacy aliases for stability
  static const Color primaryDark   = Color(0xFFE9A48E); // Map to Accent Peach
  static const Color softGray      = Color(0xFFF8EEE9); // Map to Creamy Gray
  static const Color softLilac     = Color(0xFFF8EEE9); // Map to Creamy Gray
  static const Color lilacAccent   = Color(0xFFFFF8F5); // Map to Cream Background
  static const Color lavenderText  = Color(0xFFE9A48E); // Map to Accent Peach


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
      onPrimary: Colors.white,
      secondary: AppColors.blush,
      surface: AppColors.creamBg,
      onSurface: AppColors.primaryText,
    ),
    scaffoldBackgroundColor: AppColors.bgLight,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primaryText,
      selectionColor: Color(0x33FFC09D),
      selectionHandleColor: AppColors.primary,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primaryText),
      headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primaryText),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppColors.primaryText),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppColors.primaryText),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.secondaryText,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
      ),
      iconTheme: const IconThemeData(color: AppColors.primaryText),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.creamBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      margin: EdgeInsets.zero,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.white,
      headerBackgroundColor: AppColors.primary,
      headerForegroundColor: AppColors.primaryText,
      surfaceTintColor: Colors.transparent,
      dayStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
      weekdayStyle: GoogleFonts.inter(
        color: AppColors.secondaryText,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return AppColors.blush;
        return null;
      }),
      dayForegroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return AppColors.accent;
        return AppColors.primaryText;
      }),
      todayBackgroundColor: MaterialStateProperty.all(Colors.transparent),
      todayForegroundColor: MaterialStateProperty.all(AppColors.accent),
      yearStyle: GoogleFonts.inter(),
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
    timePickerTheme: TimePickerThemeData(
      backgroundColor: Colors.white,
      hourMinuteColor: const Color(0xFFF6E6E0),
      hourMinuteTextColor: AppColors.primaryText,
      hourMinuteTextStyle: GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      ),
      dialBackgroundColor: const Color(0xFFF8EEE9),
      dialHandColor: AppColors.accent,
      dialTextColor: MaterialStateColor.resolveWith((states) =>
          states.contains(MaterialState.selected)
              ? Colors.white
              : AppColors.primaryText),
      dayPeriodColor: MaterialStateColor.resolveWith((states) =>
          states.contains(MaterialState.selected)
              ? AppColors.accent
              : const Color(0xFFF8EEE9)),
      dayPeriodTextColor: MaterialStateColor.resolveWith((states) =>
          states.contains(MaterialState.selected)
              ? Colors.white
              : AppColors.primaryText),
      dayPeriodBorderSide: BorderSide.none,
      dayPeriodShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      entryModeIconColor: AppColors.accent,
      helpTextStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.secondaryText,
      ),
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.secondaryText,
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    ),
  );
}
