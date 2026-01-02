import 'package:flutter/material.dart';
import 'package:mentalwellness/features/landing/presentation/pages/Landing_screen.dart';
import 'package:mentalwellness/features/auth/presentation/pages/Login_screen.dart';
import 'package:mentalwellness/features/auth/presentation/pages/Register_screen.dart';
import 'package:mentalwellness/features/splash/presentation/pages/Splash_screen.dart';
import 'package:mentalwellness/features/dashboard/presentation/pages/botton_navigation_screen.dart';
import 'package:mentalwellness/features/onboarding/presentation/pages/onboarding2nd_screen.dart';
import 'package:mentalwellness/features/onboarding/presentation/pages/onboarding3rd_screen.dart';
import 'package:mentalwellness/features/onboarding/presentation/pages/onboardingfirst_screen.dart';
import 'package:mentalwellness/app/theme/theme_data.dart';

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
        '/BottomNavigationScreen':(context)=>const BottomNavigationScreen(),

      }
    );
  }
}