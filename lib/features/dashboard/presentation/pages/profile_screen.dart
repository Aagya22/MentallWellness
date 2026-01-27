import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:permission_handler/permission_handler.dart';

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
      _pickedImage = XFile(pic);
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

    if (status.isDenied) {
      final result = await permission.request();
      return result.isGranted;
    }

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
        content: const Text(
          'Please allow permission from settings to continue.',
        ),
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
    final hasPermission = await _requestPermission(Permission.camera);
    if (!hasPermission) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _pickFromGallery() async {
    final hasPermission = await _requestPermission(
      Platform.isAndroid ? Permission.photos : Permission.photos,
    );
    if (!hasPermission) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _pickedImage = image);
    }
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
              title: const Text('Open Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Open Gallery'),
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

    final userSession = ref.read(userSessionServiceProvider);
    final userId = userSession.getCurrentUserId() ?? 'local_user';

    await userSession.saveUserSession(
      userId: userId,
      email: _emailCtrl.text.trim(),
      fullName: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      profilePicture: _pickedImage?.path,
    );

    setState(() => _isEditing = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _showImagePickerSheet,
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _pickedImage != null
                      ? FileImage(File(_pickedImage!.path))
                      : null,
                  child: _pickedImage == null
                      ? const Icon(Icons.camera_alt, size: 36, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameCtrl,
                enabled: _isEditing,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emailCtrl,
                enabled: _isEditing,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Invalid email' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _usernameCtrl,
                enabled: _isEditing,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneCtrl,
                enabled: _isEditing,
                decoration: const InputDecoration(labelText: 'Phone number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      onPressed: _isEditing ? _saveProfile : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}