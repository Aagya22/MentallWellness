import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/core/services/security/biometric_auth_service.dart';
import 'package:mentalwellness/core/services/security/biometric_login_credential_service.dart';
import 'package:mentalwellness/core/services/security/biometric_settings_service.dart';
import 'package:mentalwellness/features/auth/presentation/state/auth_state.dart';
import 'package:mentalwellness/features/auth/presentation/view_model/auth_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  bool _biometricChecking = true;
  bool _biometricSupported = false;
  bool _biometricBusy = false;
  bool _biometricLoginEnabled = false;
  bool _attemptedBiometricLogin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadBiometricStatus();
    });
  }

  Future<void> _loadBiometricStatus() async {
    final settings = ref.read(biometricSettingsServiceProvider);
    final enabled = settings.isBiometricLoginEnabled();
    final supported = enabled
        ? await ref.read(biometricAuthServiceProvider).isBiometricSupported()
        : false;

    if (!mounted) return;
    setState(() {
      _biometricLoginEnabled = enabled;
      _biometricSupported = supported;
      _biometricChecking = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authViewModelProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    }
  }

  Future<void> _loginWithBiometrics() async {
    if (_biometricBusy) return;

    if (_biometricChecking) {
      showMySnackBar(
        context: context,
        message: 'Checking biometric support...',
        color: Colors.red,
      );
      return;
    }

    if (!_biometricLoginEnabled) {
      showMySnackBar(
        context: context,
        message: 'Enable biometric login in Settings first',
        color: Colors.red,
      );
      return;
    }

    if (!_biometricSupported) {
      showMySnackBar(
        context: context,
        message: 'Biometrics not available on this device',
        color: Colors.red,
      );
      return;
    }

    setState(() => _biometricBusy = true);

    try {
      final biometricAuth = ref.read(biometricAuthServiceProvider);
      final ok = await biometricAuth.authenticate(
        reason: 'Login with biometrics',
      );
      if (!mounted) return;

      if (!ok) {
        final message =
            biometricAuth.userFriendlyError ??
            'Biometric authentication failed. Set up biometrics in your device settings and try again.';
        setState(() => _biometricBusy = false);
        showMySnackBar(context: context, message: message, color: Colors.red);
        return;
      }

      final creds = await ref
          .read(biometricLoginCredentialServiceProvider)
          .getCredentials();
      if (!mounted) return;

      if (creds == null) {
        setState(() => _biometricBusy = false);
        showMySnackBar(
          context: context,
          message: 'No saved login found. Login once with email & password.',
          color: Colors.red,
        );
        return;
      }

      _attemptedBiometricLogin = true;
      ref
          .read(authViewModelProvider.notifier)
          .login(email: creds.email, password: creds.password);
    } catch (_) {
      if (!mounted) return;
      setState(() => _biometricBusy = false);
      showMySnackBar(
        context: context,
        message: 'Biometric login failed',
        color: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Listen for auth state changes (side effects)
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (!mounted) return;

      if (_biometricBusy && next.status != AuthStatus.loading) {
        setState(() => _biometricBusy = false);
      }

      if (next.status == AuthStatus.authenticated) {
        _attemptedBiometricLogin = false;
        // Cache credentials securely for biometric login after a successful
        // password-based login.
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        if (email.isNotEmpty && password.isNotEmpty) {
          ref
              .read(biometricLoginCredentialServiceProvider)
              .saveCredentials(email: email, password: password);
        }

        showMySnackBar(
          context: context,
          message: "Login Successful",
          color: Colors.green,
        );
        final role = next.user?.role;
        if (role == 'admin') {
          Navigator.pushReplacementNamed(
            context,
            '/AdminBottomNavigationScreen',
          );
        } else {
          Navigator.pushReplacementNamed(context, '/BottomNavigationScreen');
        }
      } else if (next.status == AuthStatus.error) {
        final fromBiometric = _attemptedBiometricLogin;
        _attemptedBiometricLogin = false;

        if (fromBiometric) {
          showMySnackBar(
            context: context,
            message:
                'Biometric login failed. Please login once with email & password.',
            color: Colors.red,
          );
          ref.read(biometricLoginCredentialServiceProvider).clearCredentials();
          return;
        }

        showMySnackBar(
          context: context,
          message: next.errorMessage ?? "Login failed",
          color: Colors.red,
        );
      }
    });

    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Image.asset("assets/images/novacane.png", height: 145),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Welcome back",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "sign in to access your account",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 18),

                /// EMAIL
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Enter your email",
                    filled: true,
                    fillColor: const Color(0xffEFEDE7),
                    suffixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email is required";
                    }
                    if (!value.contains("@")) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                /// PASSWORD
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: "Password",
                    filled: true,
                    fillColor: const Color(0xffEFEDE7),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) {
                            setState(() {
                              _rememberMe = v!;
                            });
                          },
                        ),
                        const Text(
                          "Remember me",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// LOGIN BUTTON
                SizedBox(
                  width: 160,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: authState.status == AuthStatus.loading
                        ? null
                        : _submitLogin,
                    child: Text(
                      authState.status == AuthStatus.loading
                          ? "PLEASE WAIT..."
                          : "Login",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                if (_biometricLoginEnabled &&
                    !_biometricChecking &&
                    _biometricSupported)
                  SizedBox(
                    width: 220,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed:
                          (authState.status == AuthStatus.loading ||
                              _biometricBusy)
                          ? null
                          : _loginWithBiometrics,
                      icon: const Icon(Icons.fingerprint),
                      label: Text(
                        _biometricBusy
                            ? 'AUTHENTICATING...'
                            : 'Use fingerprint',
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("New member ? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/RegisterScreen');
                      },
                      child: const Text(
                        "Register now",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
