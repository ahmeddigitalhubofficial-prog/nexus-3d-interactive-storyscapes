import 'package:flutter/material.dart';

class AppTheme {
  // --- Common Fonts ---
  // Using standard system fonts that support both Arabic and English,
  // styling them with specific letterSpacing, weights, and heights for premium feel.
  
  static ThemeData getTheme(String themeName) {
    switch (themeName) {
      case 'horror':
        return _horrorTheme;
      case 'comedy':
        return _comedyTheme;
      case 'historical':
        return _historicalTheme;
      case 'menu':
      default:
        return _menuTheme;
    }
  }

  // 1. Menu Theme: Sleek Glassmorphism Dark Blue
  static final ThemeData _menuTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF00E5FF), // Neon cyan
    scaffoldBackgroundColor: const Color(0xFF0B1220), // Midnight blue
    cardColor: const Color(0xFF162235),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00E5FF),
      secondary: Color(0xFF7C4DFF), // Purple
      surface: Color(0xFF162235),
      error: Colors.redAccent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
      titleLarge: TextStyle(color: Color(0xFF00E5FF), fontSize: 22, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00E5FF),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: const Color(0xFF00E5FF).withValues(alpha: 0.5),
        elevation: 8,
      ),
    ),
  );

  // 2. Horror Theme: Deep Black & Blood Red
  static final ThemeData _horrorTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFD32F2F), // Blood red
    scaffoldBackgroundColor: const Color(0xFF070707), // Coal black
    cardColor: const Color(0xFF141414),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFD32F2F),
      secondary: Color(0xFF5C0606),
      surface: Color(0xFF141414),
      error: Color(0xFFFF1744),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white70, fontSize: 17, height: 1.6, fontFamily: 'serif'),
      bodyMedium: TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'serif'),
      titleLarge: TextStyle(color: Color(0xFFD32F2F), fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'serif'),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5C0606),
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        shadowColor: const Color(0xFFD32F2F).withValues(alpha: 0.3),
        elevation: 10,
      ),
    ),
  );

  // 3. Comedy Theme: Warm, Playful, Colorful
  static final ThemeData _comedyTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFFFF9100), // Playful orange
    scaffoldBackgroundColor: const Color(0xFFFFFDE7), // Soft yellow cream
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFF9100),
      secondary: Color(0xFF4CAF50), // Green
      surface: Colors.white,
      error: Colors.redAccent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFFFF9100)),
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFFF9100)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF424242), fontSize: 16, height: 1.5, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: Color(0xFF757575), fontSize: 14),
      titleLarge: TextStyle(color: Color(0xFFFF9100), fontSize: 24, fontWeight: FontWeight.w900),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF9100),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        shadowColor: const Color(0xFFFF9100).withValues(alpha: 0.4),
        elevation: 6,
      ),
    ),
  );

  // 4. Historical Theme: Ancient Papyrus & Bronze Gold
  static final ThemeData _historicalTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFFFC107), // Gold/Amber
    scaffoldBackgroundColor: const Color(0xFF1E1710), // Clay/Soil dark brown
    cardColor: const Color(0xFF2C2219),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFC107),
      secondary: Color(0xFFCD7F32), // Bronze
      surface: Color(0xFF2C2219),
      error: Colors.redAccent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFC107)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF5E6D3), fontSize: 16, height: 1.6, fontFamily: 'serif'), // Pale sand
      bodyMedium: TextStyle(color: Color(0xFFC0A58F), fontSize: 14, fontFamily: 'serif'),
      titleLarge: TextStyle(color: Color(0xFFFFC107), fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'serif'),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2C2219),
        foregroundColor: const Color(0xFFFFC107),
        side: const BorderSide(color: Color(0xFFFFC107), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        shadowColor: const Color(0xFFFFC107).withValues(alpha: 0.2),
        elevation: 6,
      ),
    ),
  );
}
