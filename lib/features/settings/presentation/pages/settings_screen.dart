import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:mentalwellness/features/auth/presentation/view_model/auth_viewmodel.dart';
import 'package:mentalwellness/features/dashboard/presentation/pages/profile_screen.dart';
import 'package:mentalwellness/features/settings/presentation/pages/privacy_security_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _bg = Color(0xFFF4F1EA);
  static const _text = Color(0xFF1F2A22);
  static const _accent = Color(0xFF2D5A44);
  static const _border = Color(0xFFEAF1ED);

  ImageProvider? _getProfileImage(UserSessionService session) {
    final pic = session.getCurrentUserProfilePicture();
    if (pic == null || pic.isEmpty) return null;
    final url = ApiEndpoints.getImageUrl(pic);
    if (url.isEmpty) return null;
    return NetworkImage(url);
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    await ref.read(authViewModelProvider.notifier).logout();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/LandingScreen');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.read(userSessionServiceProvider);
    final nameRaw = session.getCurrentUserFullName();
    final name = (nameRaw == null || nameRaw.trim().isEmpty)
        ? 'User'
        : nameRaw.trim();
    final profileImage = _getProfileImage(session);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _text),
        title: const Text(
          'Settings',
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFEAF1ED),
                  backgroundImage: profileImage,
                  child: profileImage == null
                      ? const Icon(Icons.person, color: _accent)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 16,
                      color: _text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsOptionCard(
            icon: Icons.person_outline,
            title: 'Profile Settings',
            subtitle:
                'Update your name, avatar, email and personal information.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _SettingsOptionCard(
            icon: Icons.shield_outlined,
            title: 'Privacy & Security',
            subtitle: 'Manage your journal passcode and account security.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
              );
            },
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'Inter Bold',
                color: Colors.red,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsOptionCard extends StatelessWidget {
  const _SettingsOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const _text = Color(0xFF1F2A22);
  static const _accent = Color(0xFF2D5A44);
  static const _border = Color(0xFFEAF1ED);

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1ED),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(icon, color: _accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 14,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter Regular',
                      fontSize: 12,
                      color: _text.withValues(alpha: 166),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: _accent),
          ],
        ),
      ),
    );
  }
}
