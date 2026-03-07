import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/features/auth/data/datasources/remote/auth_remote_datasource.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key, this.isAdminTheme = false});

  final bool isAdminTheme;

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _currentVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _saving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Color get _bg =>
      widget.isAdminTheme ? const Color(0xFFF1F5F9) : const Color(0xFFF4F1EA);

  Color get _text => const Color(0xFF1F2A22);

  Color get _accent =>
      widget.isAdminTheme ? const Color(0xFF4F46E5) : const Color(0xFF2D5A44);

  List<Color> get _heroColors => widget.isAdminTheme
      ? const [Color(0xFF4F46E5), Color(0xFF7C3AED)]
      : const [Color(0xFF2D5A44), Color(0xFF4E7A64)];

  String _normalizeError(Object e) {
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '').trim();
    }
    return raw;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.trim().isEmpty) {
      _showSnack('Enter your current password', isError: true);
      return;
    }
    if (current.length < 8) {
      _showSnack(
        'Current password must be at least 8 characters',
        isError: true,
      );
      return;
    }
    if (next.length < 8) {
      _showSnack('New password must be at least 8 characters', isError: true);
      return;
    }
    if (next == current) {
      _showSnack(
        'New password must be different from current password',
        isError: true,
      );
      return;
    }
    if (next != confirm) {
      _showSnack(
        'New password and confirm password do not match',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final message = await ref
          .read(authRemoteDatasourceProvider)
          .changePassword(
            currentPassword: current,
            newPassword: next,
            confirmNewPassword: confirm,
          );
      if (!mounted) return;
      _showSnack(message);
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack(_normalizeError(e), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: _text),
        title: Text(
          'Change Password',
          style: TextStyle(
            fontFamily: 'Inter Bold',
            fontSize: 18,
            color: _text,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _heroColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x291F2A22),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep your account secure',
                  style: TextStyle(
                    fontFamily: 'Inter Bold',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Enter your current password and set a new one. Use at least 8 characters.',
                  style: TextStyle(
                    fontFamily: 'Inter Regular',
                    fontSize: 12,
                    color: Color(0xFFEAF1ED),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDCE7E1)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _currentCtrl,
                  obscureText: !_currentVisible,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _currentVisible = !_currentVisible),
                      icon: Icon(
                        _currentVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newCtrl,
                  obscureText: !_newVisible,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    hintText: 'At least 8 characters',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _newVisible = !_newVisible),
                      icon: Icon(
                        _newVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: !_confirmVisible,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _confirmVisible = !_confirmVisible),
                      icon: Icon(
                        _confirmVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCE7E1)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFB8C5BD),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(_saving ? Icons.sync : Icons.check_circle_outline),
                label: Text(_saving ? 'Updating...' : 'Update password'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
