import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mentalwellness/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:mentalwellness/features/auth/presentation/view_model/auth_viewmodel.dart';

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

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authViewModelProvider.notifier).logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/LandingScreen');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isEditing ? Icons.close : Icons.edit),
                      onPressed: () => setState(() => _isEditing = !_isEditing),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
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
                ),
                const SizedBox(height: 8),
                if (_isEditing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _showImagePickerSheet,
                        icon: const Icon(Icons.edit),
                        label: const Text('Update Picture'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _deleteProfilePicture,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Delete Picture'),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),
                _field('Full Name', _nameCtrl),
                _field('Email', _emailCtrl),
                _field('Username', _usernameCtrl),
                _field('Phone', _phoneCtrl, keyboard: TextInputType.phone),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  onPressed: _isEditing ? _saveProfile : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _logout,
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
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }
}
