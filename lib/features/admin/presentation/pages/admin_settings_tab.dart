import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:mentalwellness/features/admin/presentation/pages/admin_bottom_navigation_screen.dart';
import 'package:mentalwellness/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:mentalwellness/features/auth/presentation/view_model/auth_viewmodel.dart';
import 'package:permission_handler/permission_handler.dart';

class AdminSettingsTab extends ConsumerStatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  ConsumerState<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends ConsumerState<AdminSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isEditing = false;
  bool _isSaving = false;
  XFile? _pickedImage;
  String? _storedProfilePictureUrl;

  @override
  void initState() {
    super.initState();
    final userSession = ref.read(userSessionServiceProvider);
    _nameCtrl.text = userSession.getCurrentUserFullName() ?? '';
    _emailCtrl.text = userSession.getCurrentUserEmail() ?? '';
    _usernameCtrl.text = userSession.getCurrentUserUsername() ?? '';
    _phoneCtrl.text = userSession.getCurrentUserPhoneNumber() ?? '';
    final pic = userSession.getCurrentUserProfilePicture();
    if (pic != null && pic.isNotEmpty) {
      _storedProfilePictureUrl = pic;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) return true;
    if (status.isDenied) return (await permission.request()).isGranted;
    return false;
  }

  Future<void> _pickFromCamera() async {
    if (!await _requestPermission(Permission.camera)) return;
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _pickFromGallery() async {
    if (!await _requestPermission(Permission.photos)) return;
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) setState(() => _pickedImage = image);
  }

  void _showImagePickerSheet() {
    if (!_isEditing) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_pickedImage != null) return FileImage(File(_pickedImage!.path));
    if (_storedProfilePictureUrl != null &&
        _storedProfilePictureUrl!.isNotEmpty) {
      return NetworkImage(ApiEndpoints.getImageUrl(_storedProfilePictureUrl));
    }
    return null;
  }

  Future<void> _logout() async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    await ref.read(authViewModelProvider.notifier).logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/LoginScreen',
      (route) => false,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(userSessionServiceProvider);
    final userId = session.getCurrentUserId();
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      final authRemoteDatasource = ref.read(authRemoteDatasourceProvider);
      final updateData = {
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
      };
      final file = _pickedImage != null ? File(_pickedImage!.path) : null;
      final updatedUser = await authRemoteDatasource.updateUser(
        userId,
        updateData,
        file,
      );
      if (!mounted) return;
      if (updatedUser != null) {
        setState(() {
          _isEditing = false;
          _pickedImage = null;
          _storedProfilePictureUrl = updatedUser.profilePicture;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userSession = ref.read(userSessionServiceProvider);
    final role = userSession.getCurrentUserRole() ?? 'admin';

    return SafeArea(
      child: AbsorbPointer(
        absorbing: _isSaving,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile Banner ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kAdminPrimary, kAdminSecondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showImagePickerSheet,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: _getProfileImage() != null
                                    ? Image(
                                        image: _getProfileImage()!,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: Colors.white24,
                                        child: Center(
                                          child: Text(
                                            _nameCtrl.text.isNotEmpty
                                                ? _nameCtrl.text
                                                      .substring(0, 1)
                                                      .toUpperCase()
                                                : 'A',
                                            style: const TextStyle(
                                              fontSize: 34,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            if (_isEditing)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: kAdminPrimary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _nameCtrl.text.isNotEmpty
                            ? _nameCtrl.text
                            : 'Administrator',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Edit toggle bar ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profile Information',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _isEditing = !_isEditing),
                        icon: Icon(
                          _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                          size: 16,
                          color: kAdminPrimary,
                        ),
                        label: Text(
                          _isEditing ? 'Cancel' : 'Edit',
                          style: const TextStyle(
                            color: kAdminPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Form fields card ─────────────────────────────────────
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _FormRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Full Name',
                        controller: _nameCtrl,
                        enabled: _isEditing,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const _Divider(),
                      _FormRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        controller: _emailCtrl,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const _Divider(),
                      _FormRow(
                        icon: Icons.alternate_email_rounded,
                        label: 'Username',
                        controller: _usernameCtrl,
                        enabled: _isEditing,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const _Divider(),
                      _FormRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        controller: _phoneCtrl,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),

                // ── Save button ──────────────────────────────────────────
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAdminPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ),

                if (!_isEditing) const SizedBox(height: 24),

                // ── Logout button ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        foregroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: _logout,
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

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

class _FormRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormRow({
    required this.icon,
    required this.label,
    required this.controller,
    required this.enabled,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: kAdminPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              validator: validator,
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: enabled
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: kAdminPrimary),
                ),
                disabledBorder: InputBorder.none,
                errorBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 62, endIndent: 0);
  }
}
