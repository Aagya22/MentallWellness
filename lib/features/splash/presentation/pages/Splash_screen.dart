import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/services/security/biometric_auth_service.dart';
import 'package:mentalwellness/core/services/security/biometric_settings_service.dart';
import 'package:mentalwellness/core/services/security/journal_passcode_cache_service.dart';
import 'package:mentalwellness/core/services/storage/journal_access_token_service.dart';
import 'package:mentalwellness/core/services/storage/token_service.dart';
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

  Future<void> _clearLocalSession() async {
    final session = ref.read(userSessionServiceProvider);
    final tokenService = ref.read(tokenServiceProvider);
    final journalAccessTokenService = ref.read(journalAccessTokenServiceProvider);
    final passcodeCache = ref.read(journalPasscodeCacheServiceProvider);

    await Future.wait([
      session.clearSession(),
      tokenService.removeToken(),
      journalAccessTokenService.removeToken(),
      passcodeCache.clearPasscode(),
    ]);
  }

  Future<void> _navigateAfterSplash() async {
    try {
      await ref.read(journalPasscodeCacheServiceProvider).clearPasscode();
    } catch (_) {
    }

    final session = ref.read(userSessionServiceProvider);
    final isLoggedIn = session.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      final settings = ref.read(biometricSettingsServiceProvider);
      final requireBiometric = settings.isBiometricLoginEnabled();

      if (requireBiometric) {
        final biometricAuth = ref.read(biometricAuthServiceProvider);
        final supported = await biometricAuth.isBiometricSupported();
        if (!supported) {
          await settings.setBiometricLoginEnabled(false);
        } else {
          final ok = await biometricAuth.authenticate(
            reason: 'Authenticate to continue',
          );
          if (!ok) {
            await _clearLocalSession();
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/LoginScreen');
            return;
          }
        }
      }

      if (!mounted) return;
      final role = session.getCurrentUserRole();
      if (role == 'admin') {
        Navigator.pushReplacementNamed(
          context,
          '/AdminBottomNavigationScreen',
        );
      } else {
        Navigator.pushReplacementNamed(context, '/BottomNavigationScreen');
      }
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const OnboardingfirstScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              Future.microtask(_navigateAfterSplash);
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
