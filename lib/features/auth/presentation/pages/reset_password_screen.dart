import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/features/auth/data/datasources/remote/auth_remote_datasource.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _prefilledFromArgs = false;
  bool _isLoading = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilledFromArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final token = args['token'];
      final code = args['code'];
      if (token is String && token.trim().isNotEmpty) {
        _tokenController.text = token.trim();
      }
      if (code is String && code.trim().isNotEmpty) {
        _codeController.text = code.trim();
      }
    }

    _prefilledFromArgs = true;
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final message = await ref
          .read(authRemoteDatasourceProvider)
          .resetPasswordWithCode(
            token: _tokenController.text.trim(),
            resetCode: _codeController.text.trim(),
            newPassword: _newPasswordController.text.trim(),
          );

      if (!mounted) return;
      showMySnackBar(context: context, message: message, color: Colors.green);
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/LoginScreen',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showMySnackBar(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
        color: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set a new password',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Paste the token and reset code from your email, then choose a new password.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    hintText: 'Reset token',
                    filled: true,
                    fillColor: const Color(0xffEFEDE7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) {
                      return 'Reset token is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '6-digit reset code',
                    filled: true,
                    fillColor: const Color(0xffEFEDE7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    final code = value?.trim() ?? '';
                    if (code.isEmpty) return 'Reset code is required';
                    if (code.length < 6) return 'Enter a valid reset code';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_showNewPassword,
                  decoration: InputDecoration(
                    hintText: 'New password',
                    filled: true,
                    fillColor: const Color(0xffEFEDE7),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _showNewPassword = !_showNewPassword);
                      },
                      icon: Icon(
                        _showNewPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    final password = value?.trim() ?? '';
                    if (password.isEmpty) return 'New password is required';
                    if (password.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm new password',
                    filled: true,
                    fillColor: const Color(0xffEFEDE7),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        );
                      },
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value!.trim() != _newPasswordController.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: Text(
                      _isLoading ? 'PLEASE WAIT...' : 'Reset Password',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
