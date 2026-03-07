import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mentalwellness/features/auth/data/datasources/remote/auth_remote_datasource.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool _isEditing = false;
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
    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
      return false;
    }
    return false;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Enable permission from settings to continue'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final userSession = ref.read(userSessionServiceProvider);
      final authRemoteDatasource = ref.read(authRemoteDatasourceProvider);
      final userId = userSession.getCurrentUserId();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID not found. Please login again.'),
          ),
        );
        return;
      }
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
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
      if (mounted) Navigator.pop(context);
      if (updatedUser != null) {
        if (updatedUser.profilePicture != null &&
            updatedUser.profilePicture!.isNotEmpty) {
          setState(() {
            _storedProfilePictureUrl = updatedUser.profilePicture;
            _pickedImage = null;
          });
        }
        setState(() => _isEditing = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProfilePicture() async {
    try {
      final userSession = ref.read(userSessionServiceProvider);
      final authRemoteDatasource = ref.read(authRemoteDatasourceProvider);
      final userId = userSession.getCurrentUserId();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID not found. Please login again.'),
          ),
        );
        return;
      }
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final updateData = {
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'imageUrl': '',
      };
      final updatedUser = await authRemoteDatasource.updateUser(
        userId,
        updateData,
        null,
      );
      if (mounted) Navigator.pop(context);
      if (updatedUser != null) {
        await userSession.deleteProfilePicture();
        setState(() {
          _pickedImage = null;
          _storedProfilePictureUrl = null;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete profile picture'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting profile picture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ImageProvider? _getProfileImage() {
    if (_pickedImage != null) return FileImage(File(_pickedImage!.path));
    if (_storedProfilePictureUrl != null &&
        _storedProfilePictureUrl!.isNotEmpty) {
      final fullImageUrl = ApiEndpoints.getImageUrl(_storedProfilePictureUrl);
      return NetworkImage(fullImageUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _nameCtrl.text.trim().isEmpty
        ? 'Your profile'
        : _nameCtrl.text.trim();
    final displayEmail = _emailCtrl.text.trim().isEmpty
        ? 'Update your email in edit mode'
        : _emailCtrl.text.trim();
    final hasProfilePicture =
        _pickedImage != null ||
        (_storedProfilePictureUrl != null &&
            _storedProfilePictureUrl!.isNotEmpty);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2A22)),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Profile settings',
          style: TextStyle(
            fontFamily: 'Inter Bold',
            fontSize: 18,
            color: Color(0xFF1F2A22),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton.icon(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded),
              label: Text(_isEditing ? 'Cancel' : 'Edit'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2D5A44),
                textStyle: const TextStyle(
                  fontFamily: 'Inter Bold',
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFDCE7E1)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1F2A22).withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isEditing ? _showImagePickerSheet : null,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 56,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: _getProfileImage(),
                              child:
                                  _pickedImage == null &&
                                      (_storedProfilePictureUrl == null ||
                                          _storedProfilePictureUrl!.isEmpty)
                                  ? const Icon(
                                      Icons.camera_alt,
                                      size: 36,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            if (_isEditing && _pickedImage != null)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.red,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    onPressed: () =>
                                        setState(() => _pickedImage = null),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter Bold',
                          fontSize: 20,
                          color: Color(0xFF1F2A22),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayEmail,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter Regular',
                          fontSize: 13,
                          color: Color(0xFF5D6A62),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showImagePickerSheet,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2D5A44),
                            side: const BorderSide(color: Color(0xFFBCD0C4)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Update picture'),
                        ),
                        OutlinedButton.icon(
                          onPressed: hasProfilePicture
                              ? _deleteProfilePicture
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8B2E2E),
                            side: const BorderSide(color: Color(0xFFD8BDBD)),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete picture'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                const Text(
                  'Account details',
                  style: TextStyle(
                    fontFamily: 'Inter Bold',
                    fontSize: 16,
                    color: Color(0xFF1F2A22),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDCE7E1)),
                  ),
                  child: Column(
                    children: [
                      _field('Full Name', _nameCtrl),
                      _field('Email', _emailCtrl),
                      _field('Username', _usernameCtrl),
                      _field(
                        'Phone',
                        _phoneCtrl,
                        keyboard: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      _isEditing ? Icons.save_outlined : Icons.lock_outline,
                    ),
                    label: Text(
                      _isEditing ? 'Save changes' : 'Enable edit mode to save',
                    ),
                    onPressed: _isEditing ? _saveProfile : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5A44),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFB8C5BD),
                      disabledForegroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        enabled: _isEditing,
        keyboardType: keyboard,
        style: const TextStyle(
          fontFamily: 'Inter Medium',
          fontSize: 14,
          color: Color(0xFF1F2A22),
        ),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: _isEditing ? Colors.white : const Color(0xFFF3F7F4),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          labelStyle: const TextStyle(
            fontFamily: 'Inter Medium',
            color: Color(0xFF5D6A62),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD3E0D8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD3E0D8)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE1EAE5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D5A44), width: 1.3),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }
}
