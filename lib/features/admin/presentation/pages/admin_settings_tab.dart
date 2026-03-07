import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/features/admin/presentation/pages/admin_bottom_navigation_screen.dart';
import 'package:mentalwellness/features/admin/presentation/pages/admin_profile_settings_screen.dart';
import 'package:mentalwellness/features/auth/presentation/view_model/auth_viewmodel.dart';
import 'package:mentalwellness/features/settings/presentation/pages/change_password_screen.dart';

class AdminSettingsTab extends ConsumerWidget {
  const AdminSettingsTab({super.key});

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
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/LoginScreen',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kAdminPrimary, kAdminSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x334F46E5),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Manage your profile details and account password from here.',
                style: TextStyle(
                  color: Color(0xFFEDE9FE),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AdminOptionCard(
          icon: Icons.person_outline_rounded,
          title: 'Profile Settings',
          subtitle: 'View and edit your profile information.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminProfileSettingsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _AdminOptionCard(
          icon: Icons.lock_reset_rounded,
          title: 'Change Password',
          subtitle: 'Update your account password securely.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ChangePasswordScreen(isAdminTheme: true),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: () => _confirmLogout(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFEF2F2),
            foregroundColor: const Color(0xFFDC2626),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFFECACA)),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _AdminOptionCard extends StatelessWidget {
  const _AdminOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

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
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(icon, color: kAdminPrimary, size: 21)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: kAdminPrimary),
          ],
        ),
      ),
    );
  }
}
