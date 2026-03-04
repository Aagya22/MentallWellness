import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:mentalwellness/features/admin/presentation/pages/admin_bottom_navigation_screen.dart';
import 'package:mentalwellness/features/admin/presentation/state/admin_dashboard_state.dart';
import 'package:mentalwellness/features/admin/presentation/view_model/admin_dashboard_viewmodel.dart';

class AdminDashboardTab extends ConsumerStatefulWidget {
  final VoidCallback onViewUsers;

  const AdminDashboardTab({super.key, required this.onViewUsers});

  @override
  ConsumerState<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends ConsumerState<AdminDashboardTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminDashboardViewModelProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(userSessionServiceProvider);
    final fullName = session.getCurrentUserFullName() ?? 'Admin';
    final email = session.getCurrentUserEmail() ?? '';
    final state = ref.watch(adminDashboardViewModelProvider);

    if (state.status == AdminDashboardStatus.error) {
      return _ErrorView(
        message: state.errorMessage ?? 'Failed to load dashboard',
        onRetry: () =>
            ref.read(adminDashboardViewModelProvider.notifier).load(),
      );
    }

    return RefreshIndicator(
      color: kAdminPrimary,
      onRefresh: () =>
          ref.read(adminDashboardViewModelProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          // ── Hero welcome card ──────────────────────────────────────────
          _WelcomeCard(fullName: fullName, email: email),
          const SizedBox(height: 20),

          // ── Loading shimmer ────────────────────────────────────────────
          if (state.status == AdminDashboardStatus.loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(color: kAdminPrimary),
            ),

          // ── Stats grid ────────────────────────────────────────────────
          _SectionLabel(label: 'Overview'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _StatCard(
                label: 'Total Users',
                value: state.totalUsers,
                icon: Icons.people_alt_rounded,
                accent: const Color(0xFF3B82F6),
                bgAccent: const Color(0xFFEFF6FF),
              ),
              _StatCard(
                label: 'Regular Users',
                value: state.regularUsers,
                icon: Icons.person_rounded,
                accent: const Color(0xFF10B981),
                bgAccent: const Color(0xFFECFDF5),
              ),
              _StatCard(
                label: 'Administrators',
                value: state.totalAdmins,
                icon: Icons.admin_panel_settings_rounded,
                accent: kAdminSecondary,
                bgAccent: const Color(0xFFF5F3FF),
              ),
              _StatCard(
                label: 'New (30 days)',
                value: state.recentUsers30Days,
                icon: Icons.trending_up_rounded,
                accent: const Color(0xFFF59E0B),
                bgAccent: const Color(0xFFFFFBEB),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Recent users section ───────────────────────────────────────
          Row(
            children: [
              _SectionLabel(label: 'Recent Users'),
              const Spacer(),
              GestureDetector(
                onTap: widget.onViewUsers,
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: kAdminPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: kAdminPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (state.recentUsers.isEmpty)
            _EmptyUsers()
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ...List.generate(state.recentUsers.length, (i) {
                    final u = state.recentUsers[i];
                    final isLast = i == state.recentUsers.length - 1;
                    return Column(
                      children: [
                        _RecentUserRow(
                          fullName: u.fullName,
                          email: u.email,
                          role: u.role,
                          createdAt: u.createdAt,
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            indent: 60,
                            color: Colors.grey.shade100,
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  final String fullName;
  final String email;

  const _WelcomeCard({required this.fullName, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kAdminPrimary, kAdminSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x504F46E5),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              fullName.isNotEmpty
                  ? fullName.substring(0, 1).toUpperCase()
                  : 'A',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Administrator',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_user_rounded,
            color: Colors.white54,
            size: 36,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color accent;
  final Color bgAccent;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.bgAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
        letterSpacing: 0.2,
      ),
    );
  }
}

class _RecentUserRow extends StatelessWidget {
  final String fullName;
  final String email;
  final String role;
  final DateTime? createdAt;

  const _RecentUserRow({
    required this.fullName,
    required this.email,
    required this.role,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final initial = fullName.isNotEmpty
        ? fullName.substring(0, 1).toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kAdminPrimary, kAdminSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _RoleBadge(role: role),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFF5F3FF) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAdmin
              ? kAdminSecondary.withValues(alpha: 0.4)
              : const Color(0xFF10B981).withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: isAdmin ? kAdminSecondary : const Color(0xFF059669),
        ),
      ),
    );
  }
}

class _EmptyUsers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            'No users yet',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: kAdminPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
