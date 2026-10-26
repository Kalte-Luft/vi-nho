import 'package:flutter/material.dart';

const ink = Color(0xFF263B36);
const green = Color(0xFF286B57);
const lime = Color(0xFFD4EF9D);
ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: green, brightness: brightness);
  return ThemeData(
    fontFamily: 'Roboto',
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF121C19)
        : const Color(0xFFF6F7F2),
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
      bodyColor: dark ? const Color(0xFFEDF3E9) : ink,
      displayColor: dark ? const Color(0xFFEDF3E9) : ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: dark ? const Color(0xFF202D27) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF26352F) : const Color(0xFFF2F5EF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      indicatorColor: dark ? green : lime,
      backgroundColor: dark ? const Color(0xFF18241F) : Colors.white,
    ),
  );
}
