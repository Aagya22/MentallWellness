import 'package:flutter/material.dart';
import 'package:mentalwellness/screens/Landing_screen.dart';
import 'package:mentalwellness/screens/Login_screen.dart';
import 'package:mentalwellness/screens/Register_screen.dart';
import 'package:mentalwellness/screens/Splash_screen.dart';
import 'package:mentalwellness/screens/botton_navigation_screen.dart';
import 'package:mentalwellness/screens/dashboard_screen.dart';
import 'package:mentalwellness/screens/onboarding2nd_screen.dart';
import 'package:mentalwellness/screens/onboarding3rd_screen.dart';
import 'package:mentalwellness/screens/onboardingfirst_screen.dart';
import 'package:mentalwellness/theme/theme_data.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme:getApplicationTheme(
      ),
      initialRoute: '/SplashScreen',
      routes:{
        '/SplashScreen': (context) => const SplashScreen(),
        '/OnboardingfirstScreen': (context) => const OnboardingfirstScreen(),
        '/Onboarding2ndScreen':(context)=>const Onboarding2ndScreen(),
        '/Onboarding3rdScreen':(context)=>const Onboarding3rdScreen(),
        '/LandingScreen':(context)=> const LandingScreen(),
        '/LoginScreen':(context)=>const LoginScreen(),
        '/RegisterScreen':(context)=>const RegisterScreen(),
        '/DashboardScreen':(context)=>const DashboardScreen(),
        '/BottomNavigationScreen':(context)=>const BottomNavigationScreen(),

      }
    );
  }
}