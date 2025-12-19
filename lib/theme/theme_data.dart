import 'package:flutter/material.dart';

ThemeData getApplicationTheme() {
  return ThemeData(
    useMaterial3: false,

    fontFamily: 'Inter Regular',

    primarySwatch: Colors.deepOrange,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.lightBlueAccent,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter Bold',
        fontSize: 20,
        color: Colors.black,
      ),
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontFamily: 'Inter Regular',
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter Regular',
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter Bold',
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(
          fontFamily: 'Inter Bold',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: Colors.green.shade900,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(
        fontFamily: 'Inter Regular',
        fontSize: 16,
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Inter Medium',
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFB71C1C),
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.white,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Inter Bold',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      elevation: 8,
    ),
  );
}
