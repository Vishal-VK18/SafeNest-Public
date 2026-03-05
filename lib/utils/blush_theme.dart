// lib/utils/blush_theme.dart
// Shared design tokens for the Blush UI redesign.
// Import this file in any screen that needs the new Blush / Peach visual system.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
class BlushColors {
  BlushColors._();

  static const peach      = Color(0xFFFFC09D); // Primary peach
  static const blush      = Color(0xFFFFCACB); // Blush pink
  static const cream      = Color(0xFFFFFDFB); // Off-white cream
  static const darkText   = Color(0xFF181818); // Near-black text
  static const slateText  = Color(0xFF334155); // Slate-800 equivalent
  static const slateLight = Color(0xFF94A3B8); // Slate-400 equivalent
  static const white      = Color(0xFFFFFFFF);

  // Semi-transparent card backings
  static const cardBg     = Color(0x66FFFFFF); // rgba(255,255,255,0.40)
  static const cardBgHigh = Color(0xB3FFFFFF); // rgba(255,255,255,0.70)

  // Status
  static const green  = Color(0xFF4CAF50);
  static const red    = Color(0xFFE53935);
  static const amber  = Color(0xFFFFC107);
}

// ─── Gradients ────────────────────────────────────────────────────────────────
class BlushGradients {
  BlushGradients._();

  /// Full-page foggy peach→blush gradient (used as Scaffold background).
  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BlushColors.peach, BlushColors.blush],
  );

  /// Cream overlay on top of background gradient.
  static const fogOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xCCFFFDFB), Color(0x99FFFDFB)],
  );

  /// Main metric card gradient.
  static const mainCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x99FFC09D), Color(0x99FFCACB)],
  );

  /// Peach-blush action button gradient.
  static const actionButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [BlushColors.peach, BlushColors.blush],
  );
}

// ─── Decorations ──────────────────────────────────────────────────────────────
class BlushDecorations {
  BlushDecorations._();

  /// Standard glass card.
  static BoxDecoration glassCard({
    double borderRadius = 24,
    Color? color,
  }) =>
      BoxDecoration(
        color: color ?? BlushColors.cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0x80FFFFFF), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 24,
            offset: Offset(0, 4),
          )
        ],
      );

  /// Solid white card with soft shadow.
  static BoxDecoration whiteCard({double borderRadius = 24}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          )
        ],
      );

  /// Pill / badge decoration.
  static BoxDecoration pill({Color? color}) => BoxDecoration(
        color: color ?? BlushColors.cardBgHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x80FFFFFF)),
      );
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
class BlushText {
  BlushText._();

  static TextStyle screenTitle({Color color = BlushColors.darkText}) =>
      GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.3,
      );

  static TextStyle headline({Color color = BlushColors.darkText}) =>
      GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle sectionTitle({Color color = BlushColors.darkText}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle body({Color? color}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color ?? BlushColors.slateText,
        height: 1.5,
      );

  static TextStyle caption({Color? color}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color ?? BlushColors.slateLight,
        letterSpacing: 0.5,
      );

  static TextStyle label({Color? color}) =>
      GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: color ?? BlushColors.slateLight,
        letterSpacing: 1.5,
      );

  static TextStyle bigNumber({Color color = BlushColors.darkText}) =>
      GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: -2,
      );
}
