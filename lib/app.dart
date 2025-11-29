import 'package:flutter/material.dart';
import 'package:mentalwellness/screens/Landing_screen.dart';
import 'package:mentalwellness/screens/Login_screen.dart';
import 'package:mentalwellness/screens/Splash_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/LoginScreen',
      routes:{
        '/SplashScreen': (context) => const SplashScreen(),
        '/LandingScreen':(context)=> const LandingScreen(),
        '/LoginScreen':(context)=>const LoginScreen()


      }
    );
  }
}