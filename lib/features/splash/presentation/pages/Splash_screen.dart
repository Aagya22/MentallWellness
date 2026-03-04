import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:mentalwellness/features/onboarding/presentation/pages/onboardingfirst_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              final isLoggedIn = ref
                  .read(userSessionServiceProvider)
                  .isLoggedIn();
              if (isLoggedIn) {
                final role = ref
                    .read(userSessionServiceProvider)
                    .getCurrentUserRole();
                if (role == 'admin') {
                  Navigator.pushReplacementNamed(
                    context,
                    '/AdminBottomNavigationScreen',
                  );
                } else {
                  Navigator.pushReplacementNamed(
                    context,
                    '/BottomNavigationScreen',
                  );
                }
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingfirstScreen(),
                  ),
                );
              }
            }
          })
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/images/novacane.png"),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _controller.value,
                    minHeight: 6,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
