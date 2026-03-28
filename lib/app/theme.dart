import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TOMS Design Tokens — matches reference design
class TomsColors {
  // Primary palette (HSL-based)
  static const Color primary = Color(0xFF1A3A5F);        // hsl(213, 55%, 24%)
  static const Color primaryLight = Color(0xFF2A5A8F);   // hsl(213, 65%, 35%)
  static const Color primarySoft = Color(0xFF3874B0);    // hsl(220, 70%, 45%)

  // Semantic
  static const Color success = Color(0xFF2E7D32);        // hsl(128, 54%, 33%)
  static const Color successLight = Color(0xFF388E3C);
  static const Color accent = Color(0xFFFF7A00);         // hsl(28, 100%, 50%)
  static const Color destructive = Color(0xFFE53935);    // hsl(4, 82%, 56%)

  // Surfaces
  static const Color background = Color(0xFFF5F6F8);    // hsl(210, 20%, 98%)
  static const Color card = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFF0F1F5);     // hsl(216, 20%, 96%)

  // Text
  static const Color foreground = Color(0xFF1F3454);     // hsl(213, 37%, 24%)
  static const Color mutedForeground = Color(0xFF6B7B8D); // hsl(215, 14%, 50%)
  static const Color mutedLight = Color(0xFF9AA5B1);

  // Borders
  static const Color border = Color(0xFFDDE1E8);         // hsl(214, 18%, 90%)
  static const Color borderLight = Color(0xFFE8EBF0);

  // Sidebar
  static const Color sidebarBg = Color(0xFF1A3A5F);
  static const Color sidebarAccent = Color(0xFF254B75);  // hsl(213, 50%, 30%)
  static const Color sidebarBorder = Color(0xFF2D5A87);  // hsl(213, 45%, 32%)
  static const Color sidebarMuted = Color(0xFF5A7FA5);   // hsl(213, 30%, 45%)
  static const Color sidebarFg = Color(0xFFCFD8E3);      // hsl(213, 20%, 90%)

  // Gradients
  static const LinearGradient policeGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1A3A5F), Color(0xFF2A5A8F), Color(0xFF3874B0)],
  );
  static const LinearGradient driverGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D48), Color(0xFF388E6E)],
  );
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFFF7A00), Color(0xFFFF9B33)],
  );
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFE53935), Color(0xFFEF6C57)],
  );
}

class TomsTheme {
  static ThemeData get lightTheme {
    final baseText = GoogleFonts.ibmPlexSansTextTheme();
    final displayFont = GoogleFonts.spaceGroteskTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: TomsColors.background,
      colorScheme: const ColorScheme.light(
        primary: TomsColors.primary,
        onPrimary: Colors.white,
        secondary: TomsColors.secondary,
        error: TomsColors.destructive,
        surface: TomsColors.card,
        onSurface: TomsColors.foreground,
      ),
      textTheme: baseText.copyWith(
        displayLarge: displayFont.displayLarge?.copyWith(color: TomsColors.foreground, fontWeight: FontWeight.w700),
        displayMedium: displayFont.displayMedium?.copyWith(color: TomsColors.foreground, fontWeight: FontWeight.w700),
        displaySmall: displayFont.displaySmall?.copyWith(color: TomsColors.foreground, fontWeight: FontWeight.w700),
        headlineLarge: displayFont.headlineLarge?.copyWith(color: TomsColors.foreground, fontWeight: FontWeight.w700),
        headlineMedium: displayFont.headlineMedium?.copyWith(color: TomsColors.foreground, fontWeight: FontWeight.w600),
        headlineSmall: displayFont.headlineSmall?.copyWith(color: TomsColors.foreground, fontWeight: FontWeight.w600),
        titleLarge: displayFont.titleLarge?.copyWith(color: TomsColors.foreground, fontWeight: FontWeight.w700),
        titleMedium: baseText.titleMedium?.copyWith(color: TomsColors.foreground, fontWeight: FontWeight.w600),
        titleSmall: baseText.titleSmall?.copyWith(color: TomsColors.foreground, fontWeight: FontWeight.w600),
        bodyLarge: baseText.bodyLarge?.copyWith(color: TomsColors.foreground),
        bodyMedium: baseText.bodyMedium?.copyWith(color: TomsColors.foreground),
        bodySmall: baseText.bodySmall?.copyWith(color: TomsColors.mutedForeground),
        labelLarge: baseText.labelLarge?.copyWith(color: TomsColors.foreground, fontWeight: FontWeight.w600),
        labelMedium: baseText.labelMedium?.copyWith(color: TomsColors.mutedForeground, fontWeight: FontWeight.w500),
        labelSmall: baseText.labelSmall?.copyWith(color: TomsColors.mutedForeground, fontWeight: FontWeight.w500, letterSpacing: 1.2),
      ),
      cardTheme: CardThemeData(
        color: TomsColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: TomsColors.border.withValues(alpha: 0.6)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TomsColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TomsColors.foreground,
          side: const BorderSide(color: TomsColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TomsColors.secondary.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TomsColors.border.withValues(alpha: 0.5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TomsColors.border.withValues(alpha: 0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TomsColors.primary, width: 1.5)),
        labelStyle: baseText.bodySmall?.copyWith(color: TomsColors.mutedForeground),
        hintStyle: baseText.bodyMedium?.copyWith(color: TomsColors.mutedLight),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: TomsColors.border, thickness: 1),
    );
  }
}
