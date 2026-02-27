import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/features/admin/presentation/pages/admin_bottom_navigation_screen.dart';
import 'package:mentalwellness/features/admin/presentation/state/admin_user_crud_state.dart';
import 'package:mentalwellness/features/admin/presentation/view_model/admin_user_crud_viewmodel.dart';
import 'package:permission_handler/permission_handler.dart';

class AdminUserCreateScreen extends ConsumerStatefulWidget {
  const AdminUserCreateScreen({super.key});

  @override
  ConsumerState<AdminUserCreateScreen> createState() =>
      _AdminUserCreateScreenState();
}

class _AdminUserCreateScreenState extends ConsumerState<AdminUserCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;
    if (password != confirm) {
      showMySnackBar(
        context: context,
        message: 'Passwords do not match',
        color: Colors.red,
      );
      return;
    }

    final ok = await ref
        .read(adminUserCrudViewModelProvider.notifier)
        .createUser(
          fullName: _fullNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          password: password,
          confirmPassword: confirm,
          image: _pickedImage != null ? File(_pickedImage!.path) : null,
        );

    if (!mounted) return;
    final message = ref.read(adminUserCrudViewModelProvider).message;
    if (ok) {
      showMySnackBar(
        context: context,
        message: message ?? 'User created',
        color: Colors.green,
      );
      Navigator.pop(context, true);
    } else {
      showMySnackBar(
        context: context,
        message: message ?? 'Failed to create user',
        color: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUserCrudViewModelProvider);
    final isLoading = state.status == AdminUserCrudStatus.loading;

    return Scaffold(
      backgroundColor: kAdminBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kAdminPrimary, kAdminSecondary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Create User',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: isLoading,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── Avatar picker header ─────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kAdminPrimary, kAdminSecondary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Center(
                    child: GestureDetector(
                      onTap: _showImagePickerSheet,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF818CF8), Color(0xFFA78BFA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ClipOval(
                              child: _pickedImage != null
                                  ? Image.file(
                                      File(_pickedImage!.path),
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 44,
                                    ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 15,
                              color: kAdminPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
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
                          _FieldTile(
                            icon: Icons.person_outline_rounded,
                            label: 'Full Name',
                            controller: _fullNameCtrl,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const _TileDivider(),
                          _FieldTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const _TileDivider(),
                          _FieldTile(
                            icon: Icons.alternate_email_rounded,
                            label: 'Username',
                            controller: _usernameCtrl,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const _TileDivider(),
                          _FieldTile(
                            icon: Icons.phone_outlined,
                            label: 'Phone Number',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                          ),
                          const _TileDivider(),
                          _FieldTile(
                            icon: Icons.lock_outline_rounded,
                            label: 'Password',
                            controller: _passwordCtrl,
                            obscureText: true,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          const _TileDivider(),
                          _FieldTile(
                            icon: Icons.lock_reset_rounded,
                            label: 'Confirm Password',
                            controller: _confirmPasswordCtrl,
                            obscureText: true,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
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
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create User',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
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



class _FieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  const _FieldTile({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
              keyboardType: keyboardType,
              obscureText: obscureText,
              validator: validator,
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: kAdminPrimary),
                ),
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

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 62, endIndent: 0);
}
