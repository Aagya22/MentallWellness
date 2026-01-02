import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:mentalwellness/features/onboarding/presentation/pages/onboardingfirst_screen.dart';
import 'dart:async'; 

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      final isLoggedIn = ref.read(userSessionServiceProvider).isLoggedIn();
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/BottomNavigationScreen');
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingfirstScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset("assets/images/novacane.png"),
      ),
    );
  }
}
