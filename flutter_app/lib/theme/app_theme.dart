import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DuoChat brand palette.
/// Primary gradient: electric violet -> cyan (the "lightning" accent).
/// Dark theme is the premium default; light theme is offered as an option.
class DuoColors {
  static const Color violet = Color(0xFF7C5CFF);
  static const Color violetDeep = Color(0xFF5B3DF0);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color bgDark = Color(0xFF0B0E14);
  static const Color surfaceDark = Color(0xFF131722);
  static const Color surfaceDark2 = Color(0xFF1A1F2E);
  static const Color borderDark = Color(0xFF232838);
  static const Color bubbleSent = Color(0xFF3A2E82);
  static const Color bubbleReceived = Color(0xFF1A1F2E);
  static const Color textPrimaryDark = Color(0xFFE7E9F3);
  static const Color textDimDark = Color(0xFF8B91A7);
  static const Color online = Color(0xFF22C55E);
  static const Color blueTick = Color(0xFF34B7F1);

  static const Color bgLight = Color(0xFFF7F7FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF14161F);
  static const Color textDimLight = Color(0xFF6B7280);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [violet, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0B0E14), Color(0xFF1A1040), Color(0xFF0B0E14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: DuoColors.textPrimaryDark,
      displayColor: DuoColors.textPrimaryDark,
    );

    return base.copyWith(
      scaffoldBackgroundColor: DuoColors.bgDark,
      primaryColor: DuoColors.violet,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: DuoColors.violet,
        secondary: DuoColors.cyan,
        surface: DuoColors.surfaceDark,
        background: DuoColors.bgDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DuoColors.bgDark,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        color: DuoColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DuoColors.surfaceDark2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: DuoColors.textDimDark),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DuoColors.violet,
        foregroundColor: Colors.white,
      ),
      dividerColor: DuoColors.borderDark,
    );
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: DuoColors.textPrimaryLight,
      displayColor: DuoColors.textPrimaryLight,
    );
    return base.copyWith(
      scaffoldBackgroundColor: DuoColors.bgLight,
      primaryColor: DuoColors.violet,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: DuoColors.violet,
        secondary: DuoColors.cyan,
        surface: DuoColors.surfaceLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DuoColors.bgLight,
        elevation: 0,
        centerTitle: false,
        foregroundColor: DuoColors.textPrimaryLight,
      ),
    );
  }
}
