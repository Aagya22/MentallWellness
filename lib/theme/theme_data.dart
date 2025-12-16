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
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.pink,
      elevation: 0,
       type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.black54,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Playfair Regular',
        fontSize: 14, 
        fontWeight: FontWeight.w600,
    //     bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    //   elevation: 0,
    //   type: BottomNavigationBarType.fixed,

    //   selectedItemColor: Color.fromARGB(255, 245, 232, 114),
    //   unselectedItemColor: Color.fromARGB(255, 255, 255, 255),

    //   selectedIconTheme: IconThemeData(size: 32),
    //   unselectedIconTheme: IconThemeData(size: 28),

    //   selectedLabelStyle: TextStyle(
    //     fontSize: 15,
    //     fontWeight: FontWeight.w600,
    //     letterSpacing: 0.2,
    //   ),
    //   unselectedLabelStyle: TextStyle(
    //     fontSize: 12,
    //     fontWeight: FontWeight.w500,
    //   ),

    //   showSelectedLabels: true,
    //   showUnselectedLabels: true,
    // ),
      ),
    ),
  );
}
       
        
    