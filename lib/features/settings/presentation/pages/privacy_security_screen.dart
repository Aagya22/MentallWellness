import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/services/security/biometric_auth_service.dart';
import 'package:mentalwellness/core/services/security/biometric_login_credential_service.dart';
import 'package:mentalwellness/core/services/security/biometric_settings_service.dart';
import 'package:mentalwellness/features/journal/domain/usecases/clear_journal_passcode_usecase.dart';
import 'package:mentalwellness/features/journal/domain/usecases/get_journal_passcode_status_usecase.dart';
import 'package:mentalwellness/features/journal/domain/usecases/set_journal_passcode_usecase.dart';

class PrivacySecurityScreen extends ConsumerStatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  ConsumerState<PrivacySecurityScreen> createState() =>
      _PrivacySecurityScreenState();
}

enum _JournalPasscodeMode { none, enable, change, disable }

class _PrivacySecurityScreenState extends ConsumerState<PrivacySecurityScreen> {
  static const _bg = Color(0xFFF4F1EA);
  static const _text = Color(0xFF1F2A22);
  static const _accent = Color(0xFF2D5A44);
  static const _border = Color(0xFFEAF1ED);

  final _passcodeCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = true;
  bool _enabled = false;
  bool _saving = false;
  _JournalPasscodeMode _mode = _JournalPasscodeMode.none;
  String? _actionError;

  bool _biometricChecking = true;
  bool _biometricSupported = false;
  bool _biometricBusy = false;
  bool _biometricLoginEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadStatus();
      _loadBiometricSettings();
    });
  }

  @override
  void dispose() {
    _passcodeCtrl.dispose();
    _confirmCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _resetFields() {
    _passcodeCtrl.clear();
    _confirmCtrl.clear();
    _passwordCtrl.clear();
  }

  void _setError(String? message) {
    setState(() => _actionError = message);
  }

  void _showSnack(String message, {Color? background}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
    );
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _actionError = null;
    });

    final usecase = ref.read(getJournalPasscodeStatusUsecaseProvider);
    final res = await usecase();

    if (!mounted) return;

    res.fold(
      (f) {
        _showSnack(
          f.message.isNotEmpty
              ? f.message
              : 'Failed to load journal passcode status',
          background: Colors.red,
        );
        setState(() {
          _enabled = false;
          _mode = _JournalPasscodeMode.enable;
          _loading = false;
        });
      },
      (enabled) {
        setState(() {
          _enabled = enabled;
          _mode = enabled
              ? _JournalPasscodeMode.none
              : _JournalPasscodeMode.enable;
          _loading = false;
        });
      },
    );
  }

  Future<void> _loadBiometricSettings() async {
    final settings = ref.read(biometricSettingsServiceProvider);
    setState(() {
      _biometricChecking = true;
      _biometricLoginEnabled = settings.isBiometricLoginEnabled();
    });

    final supported = await ref
        .read(biometricAuthServiceProvider)
        .isBiometricSupported();
    if (!mounted) return;

    setState(() {
      _biometricSupported = supported;
      _biometricChecking = false;
    });

    if (supported) return;

    if (_biometricLoginEnabled) {
      await settings.setBiometricLoginEnabled(false);
      await ref
          .read(biometricLoginCredentialServiceProvider)
          .clearCredentials();
    }

    if (!mounted) return;
    setState(() {
      _biometricLoginEnabled = false;
    });
  }

  Future<void> _toggleBiometricLogin(bool next) async {
    if (_biometricBusy) return;

    final settings = ref.read(biometricSettingsServiceProvider);

    if (!next) {
      setState(() => _biometricBusy = true);
      await settings.setBiometricLoginEnabled(false);
      await ref
          .read(biometricLoginCredentialServiceProvider)
          .clearCredentials();
      if (!mounted) return;
      setState(() {
        _biometricLoginEnabled = false;
        _biometricBusy = false;
      });
      return;
    }

    if (_biometricChecking || !_biometricSupported) {
      _showSnack(
        'Biometrics not available on this device',
        background: Colors.red,
      );
      return;
    }

    setState(() => _biometricBusy = true);
    final biometricAuth = ref.read(biometricAuthServiceProvider);
    final ok = await biometricAuth.authenticate(
      reason: 'Enable biometric login',
    );
    if (!mounted) return;

    if (!ok) {
      setState(() => _biometricBusy = false);
      final message =
          biometricAuth.userFriendlyError ??
          'Biometric authentication failed. Set up biometrics in your device settings and try again.';
      _showSnack(message, background: Colors.red);
      return;
    }

    await settings.setBiometricLoginEnabled(true);
    if (!mounted) return;
    setState(() {
      _biometricLoginEnabled = true;
      _biometricBusy = false;
    });
    _showSnack('Biometric login enabled', background: Colors.green);
  }

  bool _isValidPasscode(String value) {
    return RegExp(r'^\d{4,8}$').hasMatch(value);
  }

  Future<void> _onSetPasscode({required bool isUpdate}) async {
    final passcode = _passcodeCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (!_isValidPasscode(passcode)) {
      _setError('Passcode must be 4–8 digits');
      return;
    }
    if (passcode != confirm) {
      _setError('Passcodes do not match');
      return;
    }
    if (password.trim().isEmpty) {
      _setError('Enter your account password to continue');
      return;
    }

    setState(() {
      _saving = true;
      _actionError = null;
    });

    final usecase = ref.read(setJournalPasscodeUsecaseProvider);
    final res = await usecase(passcode: passcode, password: password);

    if (!mounted) return;

    await res.fold(
      (f) async {
        _setError(f.message);
        _showSnack(f.message, background: Colors.red);
      },
      (_) async {
        _resetFields();

        _showSnack(
          isUpdate ? 'Journal passcode updated' : 'Journal passcode enabled',
          background: Colors.green,
        );
        await _loadStatus();
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);
  }

  Future<void> _onDisablePasscode() async {
    final password = _passwordCtrl.text;
    if (password.trim().isEmpty) {
      _setError('Enter your account password to continue');
      return;
    }

    setState(() {
      _saving = true;
      _actionError = null;
    });

    final usecase = ref.read(clearJournalPasscodeUsecaseProvider);
    final res = await usecase(password: password);

    if (!mounted) return;

    await res.fold(
      (f) async {
        _setError(f.message);
        _showSnack(f.message, background: Colors.red);
      },
      (_) async {
        _resetFields();
        _showSnack('Journal passcode disabled', background: Colors.green);
        await _loadStatus();
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);
  }

  void _toggleMode(_JournalPasscodeMode mode) {
    setState(() {
      _actionError = null;
      if (_mode == mode) {
        _mode = _enabled
            ? _JournalPasscodeMode.none
            : _JournalPasscodeMode.enable;
      } else {
        _mode = mode;
      }
      _resetFields();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _text),
        title: const Text(
          'Privacy & Security',
          style: TextStyle(
            fontFamily: 'Inter Bold',
            fontSize: 18,
            color: _text,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1ED),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.lock_outline, color: _accent),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Journal Passcode',
                            style: TextStyle(
                              fontFamily: 'Inter Bold',
                              fontSize: 14,
                              color: _text,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Add an extra lock before journal entries can be viewed.',
                            style: TextStyle(
                              fontFamily: 'Inter Regular',
                              fontSize: 12,
                              color: Color(0xFF6C7A71),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _enabled ? Icons.lock : Icons.lock_open,
                        color: _enabled
                            ? _accent
                            : _accent.withValues(alpha: 191),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _loading
                                  ? 'Status: Loading...'
                                  : _enabled
                                  ? 'Enabled'
                                  : 'Disabled',
                              style: const TextStyle(
                                fontFamily: 'Inter Bold',
                                fontSize: 13,
                                color: _text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _enabled
                                  ? 'Journal access requires your passcode.'
                                  : 'No passcode required.',
                              style: TextStyle(
                                fontFamily: 'Inter Regular',
                                fontSize: 12,
                                color: _text.withValues(alpha: 153),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_enabled)
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: (_saving || _loading)
                                  ? null
                                  : () => _toggleMode(
                                      _JournalPasscodeMode.change,
                                    ),
                              child: const Text('Change'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: (_saving || _loading)
                                  ? null
                                  : () => _toggleMode(
                                      _JournalPasscodeMode.disable,
                                    ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: const Text('Disable'),
                            ),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: (_saving || _loading)
                              ? null
                              : () => _toggleMode(_JournalPasscodeMode.enable),
                          icon: const Icon(Icons.key, size: 16),
                          label: const Text('Enable'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_mode == _JournalPasscodeMode.enable ||
                    _mode == _JournalPasscodeMode.change) ...[
                  const SizedBox(height: 14),
                  Text(
                    _mode == _JournalPasscodeMode.enable
                        ? 'Enable journal passcode'
                        : 'Change journal passcode',
                    style: const TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 13,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passcodeCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    enabled: !_saving,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Passcode',
                      hintText: '4–8 digits',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _confirmCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    enabled: !_saving,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Confirm passcode',
                      hintText: 'Re-enter passcode',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Account password',
                      hintText: 'Required to continue',
                    ),
                  ),
                  if (_actionError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _actionError!,
                      style: const TextStyle(
                        fontFamily: 'Inter Regular',
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving
                              ? null
                              : () => _onSetPasscode(isUpdate: _enabled),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _mode == _JournalPasscodeMode.enable
                                      ? 'Enable'
                                      : 'Update',
                                ),
                        ),
                      ),
                      if (_enabled) ...[
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  setState(() {
                                    _mode = _JournalPasscodeMode.none;
                                    _actionError = null;
                                    _resetFields();
                                  });
                                },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ],
                if (_mode == _JournalPasscodeMode.disable) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        'Disable journal passcode',
                        style: TextStyle(
                          fontFamily: 'Inter Bold',
                          fontSize: 13,
                          color: _text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Disabling removes the extra lock. You’ll only need your normal login to access the journal.',
                    style: TextStyle(
                      fontFamily: 'Inter Regular',
                      fontSize: 12,
                      color: _text.withValues(alpha: 166),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Account password',
                      hintText: 'Required to continue',
                    ),
                  ),
                  if (_actionError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _actionError!,
                      style: const TextStyle(
                        fontFamily: 'Inter Regular',
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : _onDisablePasscode,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Disable'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () {
                                setState(() {
                                  _mode = _JournalPasscodeMode.none;
                                  _actionError = null;
                                  _resetFields();
                                });
                              },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'You’ll be asked for this passcode when opening your journal. If you forget it, you can disable it with your account password.',
                  style: TextStyle(
                    fontFamily: 'Inter Regular',
                    fontSize: 12,
                    color: _text.withValues(alpha: 153),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1ED),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.fingerprint, color: _accent),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Biometrics',
                            style: TextStyle(
                              fontFamily: 'Inter Bold',
                              fontSize: 14,
                              color: _text,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Use fingerprint/Face ID for quick access.',
                            style: TextStyle(
                              fontFamily: 'Inter Regular',
                              fontSize: 12,
                              color: Color(0xFF6C7A71),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.login, size: 18, color: _accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Biometric login',
                              style: TextStyle(
                                fontFamily: 'Inter Bold',
                                fontSize: 13,
                                color: _text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Require biometrics to open the app when you\'re logged in.',
                              style: TextStyle(
                                fontFamily: 'Inter Regular',
                                fontSize: 12,
                                color: _text.withValues(alpha: 153),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _biometricLoginEnabled,
                        onChanged:
                            (_biometricBusy ||
                                _biometricChecking ||
                                !_biometricSupported)
                            ? null
                            : _toggleBiometricLogin,
                        activeThumbColor: _accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (!_biometricChecking && !_biometricSupported) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Biometrics are not available on this device.',
                    style: TextStyle(
                      fontFamily: 'Inter Regular',
                      fontSize: 12,
                      color: _text.withValues(alpha: 153),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
