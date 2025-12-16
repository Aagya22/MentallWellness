import 'package:flutter/material.dart';

ThemeData getApplicationTheme() {
  return ThemeData(
        primarySwatch: Colors.deepOrange,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
        fontFamily: ' Bold',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.lightBlueAccent,
          titleTextStyle: TextStyle(
            fontFamily: 'PlayfairDisplay Bold',
            fontSize: 20,
            color: Colors.black
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style:ElevatedButton.styleFrom(
            textStyle: const TextStyle(
              fontSize: 16,
              color:Colors.white,
              fontWeight: FontWeight.w500,
              fontFamily: 'PlayfairDisplay Regular'
            ),
            backgroundColor:Color(0xFF694c4a),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            )
          )
        ),     
      inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
        borderRadius: BorderRadius.circular(6),
      ),
      labelStyle: TextStyle(
        fontFamily: 'Playfair Regular',
        fontSize: 16,
        color: Colors.black,
      ),
      hintStyle: TextStyle(
        fontFamily: 'Playfair Regular',
        fontSize: 14,
        color: Colors.grey,
      ),
    ),
   bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFB71C1C),
      elevation: 0,
      selectedItemColor: Colors.transparent,
      unselectedItemColor: Colors.white,
      selectedIconTheme: IconThemeData(size: 28),
      unselectedIconTheme: IconThemeData(size: 28),
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

 
       
        
    