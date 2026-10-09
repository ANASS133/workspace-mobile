import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';

class AppTheme {
  // Brand Dark Colors
  static const Color darkBackground = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF111726);
  static const Color darkSurfaceElevated = Color(0xFF182238);
  static const Color darkSurfaceBorder = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Brand Light Colors (Clean, Premium, High-Contrast Zinc/Slate)
  static const Color lightBackground = Color(0xFFF8FAFC);      // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);         // Pure White
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9); // Slate 100
  static const Color lightSurfaceBorder = Color(0xFFE2E8F0);   // Slate 200
  static const Color lightTextPrimary = Color(0xFF0F172A);     // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569);   // Slate 600
  static const Color lightTextMuted = Color(0xFF94A3B8);       // Slate 400

  // Theme Controller & State
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  static bool get isDark => themeModeNotifier.value == ThemeMode.dark;

  // Dynamic Adaptive Color Getters
  static Color get background => isDark ? darkBackground : lightBackground;
  static Color get surface => isDark ? darkSurface : lightSurface;
  static Color get surfaceElevated => isDark ? darkSurfaceElevated : lightSurfaceElevated;
  static Color get surfaceBorder => isDark ? darkSurfaceBorder : lightSurfaceBorder;
  static Color get textPrimary => isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => isDark ? darkTextSecondary : lightTextSecondary;
  static Color get textMuted => isDark ? darkTextMuted : lightTextMuted;
  static Color get infoSky => isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

  // Vibrant Brand Category Colors (Matched to workspace-dashboard styles.css)
  static const Color dinColor = Color(0xFF06B6D4);     // Din: Cyan (.c-din)
  static const Color langColor = Color(0xFFF59E0B);    // Languages: Amber (.c-lang)
  static const Color cyberColor = Color(0xFF10B981);   // Cybersécurité: Emerald (.c-cyber)
  static const Color trainColor = Color(0xFFEF4444);   // Training: Red (.c-train)
  static const Color workColor = Color(0xFF8B5CF6);    // Lkhedma: Purple (.c-work)
  static const Color projColor = Color(0xFFEC4899);    // My Projects: Pink (.c-proj)

  // Status & Priority Colors (Matched to today.css)
  static const Color priorityHigh = Color(0xFFF43F5E); // High / Non-Negotiable (Rose Red)
  static const Color priorityMed = Color(0xFFF59E0B);  // Medium / Important (Amber)
  static const Color priorityLow = Color(0xFF818CF8);  // Low / Bonus (Indigo)

  static const Color flameOrange = Color(0xFFFF5722);
  static const Color successGreen = Color(0xFF10B981);

  // Theme Switching Handlers
  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
    try {
      StorageService.instance.saveThemeMode(mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: mode == ThemeMode.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: mode == ThemeMode.dark ? darkSurface : lightSurface,
      systemNavigationBarIconBrightness: mode == ThemeMode.dark ? Brightness.light : Brightness.dark,
    ));
  }

  static void toggleTheme() {
    setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  // --- DARK THEME SPECIFICATION ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: flameOrange,
      colorScheme: const ColorScheme.dark(
        primary: flameOrange,
        secondary: trainColor,
        surface: darkSurface,
        error: priorityHigh,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkSurfaceBorder, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: flameOrange,
        unselectedItemColor: darkTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkSurfaceBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: darkSurfaceBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkSurfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkSurfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: flameOrange, width: 1.5),
        ),
        hintStyle: const TextStyle(color: darkTextMuted, fontSize: 14),
      ),
    );
  }

  // --- LIGHT THEME SPECIFICATION ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: flameOrange,
      colorScheme: const ColorScheme.light(
        primary: flameOrange,
        secondary: trainColor,
        surface: lightSurface,
        error: priorityHigh,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightSurfaceBorder, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: flameOrange,
        unselectedItemColor: lightTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightSurfaceBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: lightSurfaceBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightSurfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightSurfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: flameOrange, width: 1.5),
        ),
        hintStyle: const TextStyle(color: lightTextMuted, fontSize: 14),
      ),
    );
  }
}
