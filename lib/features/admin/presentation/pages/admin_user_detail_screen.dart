import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/features/admin/presentation/pages/admin_bottom_navigation_screen.dart';
import 'package:mentalwellness/features/admin/presentation/state/admin_user_crud_state.dart';
import 'package:mentalwellness/features/admin/presentation/view_model/admin_user_crud_viewmodel.dart';
import 'package:mentalwellness/features/admin/presentation/view_model/admin_users_viewmodel.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key});

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    final userId = arg is String ? arg : null;
    if (userId != null && userId != _userId) {
      _userId = userId;
      Future.microtask(() {
        ref.read(adminUserCrudViewModelProvider.notifier).fetchUserById(userId);
      });
    }
  }

  Future<void> _deleteUser() async {
    final userId = _userId;
    final user = ref.read(adminUserCrudViewModelProvider).user;
    if (userId == null || userId.isEmpty) return;

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete user?'),
              content: Text('Delete ${user?.fullName ?? 'this user'}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!ok) return;

    final success = await ref
        .read(adminUsersViewModelProvider.notifier)
        .deleteUser(userId);

    if (!mounted) return;
    if (success) {
      showMySnackBar(
        context: context,
        message: 'User deleted',
        color: Colors.green,
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUserCrudViewModelProvider);
    final user = state.user;

    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return const Scaffold(
        body: SafeArea(child: Center(child: Text('Missing user id'))),
      );
    }

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
              'User Detail',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () async {
                  await Navigator.pushNamed(
                    context,
                    '/AdminUserEditScreen',
                    arguments: userId,
                  );
                  if (!mounted) return;
                  ref
                      .read(adminUserCrudViewModelProvider.notifier)
                      .fetchUserById(userId);
                },
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: _deleteUser,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (state.status == AdminUserCrudStatus.loading && user == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == AdminUserCrudStatus.error && user == null) {
              return Center(
                child: Text(state.message ?? 'Failed to load user'),
              );
            }
            if (user == null) {
              return const Center(child: Text('User not found'));
            }

            final isAdmin = user.role.toLowerCase() == 'admin';
            final initials = user.fullName.isNotEmpty
                ? user.fullName.substring(0, 1).toUpperCase()
                : '?';
            final avatar = user.imageUrl != null && user.imageUrl!.isNotEmpty
                ? NetworkImage(ApiEndpoints.getImageUrl(user.imageUrl))
                : null;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // ── Profile banner ──────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kAdminPrimary, kAdminSecondary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            gradient: avatar == null
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF818CF8),
                                      Color(0xFFA78BFA),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                          ),
                          child: ClipOval(
                            child: avatar != null
                                ? Image(image: avatar, fit: BoxFit.cover)
                                : Center(
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.fullName,
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
                            user.role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isAdmin
                                  ? const Color(0xFFDDD6FE)
                                  : const Color(0xFFBBF7D0),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Info card ───────────────────────────────────────
                  Padding(
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
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email,
                          ),
                          const Divider(height: 1, indent: 62),
                          _InfoRow(
                            icon: Icons.alternate_email_rounded,
                            label: 'Username',
                            value: '@${user.username}',
                          ),
                          const Divider(height: 1, indent: 62),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: user.phoneNumber.isNotEmpty
                                ? user.phoneNumber
                                : '—',
                          ),
                          const Divider(height: 1, indent: 62),
                          _InfoRow(
                            icon: Icons.shield_outlined,
                            label: 'Role',
                            value: user.role,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? const Color(0xFFEDE9FE)
                                    : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isAdmin
                                      ? kAdminSecondary
                                      : const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Action buttons ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kAdminPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text(
                                'Edit',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              onPressed: () async {
                                await Navigator.pushNamed(
                                  context,
                                  '/AdminUserEditScreen',
                                  arguments: userId,
                                );
                                if (!mounted) return;
                                ref
                                    .read(
                                      adminUserCrudViewModelProvider.notifier,
                                    )
                                    .fetchUserById(userId);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFEF2F2),
                                foregroundColor: const Color(0xFFDC2626),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Delete',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              onPressed: _deleteUser,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
