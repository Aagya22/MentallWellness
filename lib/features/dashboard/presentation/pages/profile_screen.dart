import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';

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
      // we'll treat stored value as a file path for local picks
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

  Future<void> _pickImage() async {
    if (!_isEditing) return; // only allow picking while editing
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      setState(() => _pickedImage = file);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final userSession = ref.read(userSessionServiceProvider);
    final userId = userSession.getCurrentUserId() ?? 'local_user';
    final profilePath = _pickedImage?.path;

    await userSession.saveUserSession(
      userId: userId,
      email: _emailCtrl.text.trim(),
      fullName: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      profilePicture: profilePath,
    );

    setState(() => _isEditing = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
            TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
            TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (newCtrl.text != confirmCtrl.text || newCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password change request submitted')));
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

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
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _pickedImage != null
                        ? FileImage(File(_pickedImage!.path)) as ImageProvider
                        : null,
                    child: _pickedImage == null
                        ? const Icon(Icons.camera_alt, size: 36, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                enabled: _isEditing,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                enabled: _isEditing,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      icon: const Icon(Icons.lock),
                      label: const Text('Change Password'),
                      onPressed: _showChangePasswordDialog,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close dialog
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              navigator.pop(); // Close dialog
                              final userSession = ref.read(userSessionServiceProvider);
                              await userSession.clearSession();
                              navigator.pushReplacementNamed('/LandingScreen');
                            },
                            child: const Text('Logout'),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}