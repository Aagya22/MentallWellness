import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:mentalwellness/features/admin/presentation/pages/admin_dashboard_tab.dart';
import 'package:mentalwellness/features/admin/presentation/pages/admin_notification_center_screen.dart';
import 'package:mentalwellness/features/admin/presentation/pages/admin_settings_tab.dart';
import 'package:mentalwellness/features/admin/presentation/pages/admin_users_tab.dart';
import 'package:mentalwellness/features/admin/presentation/view_model/admin_notifications_viewmodel.dart';
import 'package:mentalwellness/features/admin/presentation/view_model/admin_users_viewmodel.dart';

const kAdminPrimary = Color(0xFF4F46E5);
const kAdminSecondary = Color(0xFF7C3AED);
const kAdminBg = Color(0xFFF1F5F9);

class AdminBottomNavigationScreen extends ConsumerStatefulWidget {
  const AdminBottomNavigationScreen({super.key});

  @override
  ConsumerState<AdminBottomNavigationScreen> createState() =>
      _AdminBottomNavigationScreenState();
}

class _AdminBottomNavigationScreenState
    extends ConsumerState<AdminBottomNavigationScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(adminNotificationsViewModelProvider.notifier)
          .fetchNotifications(limit: 50);
    });
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Future<void> _openAdminNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminNotificationCenterScreen()),
    );

    if (!mounted) return;

    await ref
        .read(adminNotificationsViewModelProvider.notifier)
        .fetchNotifications(limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(userSessionServiceProvider);
    final role = session.getCurrentUserRole();

    if (role != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/BottomNavigationScreen');
      });
    }

    final tabs = <Widget>[
      AdminDashboardTab(onViewUsers: () => _onItemTapped(1)),
      const AdminUsersTab(),
      const AdminSettingsTab(),
    ];

    String title;
    if (_selectedIndex == 0) {
      title = 'Dashboard';
    } else if (_selectedIndex == 1) {
      title = 'Users';
    } else {
      title = 'Settings';
    }

    return Scaffold(
      backgroundColor: kAdminBg,
      appBar: _buildAppBar(title),
      body: IndexedStack(index: _selectedIndex, children: tabs),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              tooltip: 'Add User',
              backgroundColor: kAdminPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () async {
                await Navigator.pushNamed(context, '/AdminUserCreateScreen');
                if (!mounted) return;
                ref
                    .read(adminUsersViewModelProvider.notifier)
                    .fetchUsers(page: 1);
                ref
                    .read(adminNotificationsViewModelProvider.notifier)
                    .fetchNotifications(limit: 50);
              },
              child: const Icon(Icons.person_add_alt_1_rounded),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(String tabTitle) {
    final session = ref.read(userSessionServiceProvider);
    final notificationsState = ref.watch(adminNotificationsViewModelProvider);
    final unreadCount = notificationsState.unreadCount;

    final adminName = session.getCurrentUserFullName() ?? 'Administrator';

    return PreferredSize(
      preferredSize: const Size.fromHeight(90),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kAdminPrimary, kAdminSecondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x404F46E5),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD8E3DD),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    child: Center(
                      child: Transform.scale(
                        scale: 1.3,
                        child: Image.asset(
                          'assets/images/novacane.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.spa_outlined,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tabTitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _notificationAction(
                  unreadCount: unreadCount,
                  onTap: _openAdminNotifications,
                ),
                if (_selectedIndex == 1) const SizedBox(width: 8),
                if (_selectedIndex == 1)
                  _headerAction(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Refresh',
                    onTap: () {
                      final s = ref.read(adminUsersViewModelProvider);
                      ref
                          .read(adminUsersViewModelProvider.notifier)
                          .refreshLoadedPages(
                            loadedPages: s.page,
                            limit: s.limit,
                            search: s.search,
                          );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _notificationAction({
    required int unreadCount,
    required VoidCallback onTap,
  }) {
    final label = unreadCount > 99 ? '99+' : unreadCount.toString();

    return Tooltip(
      message: 'Notifications',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 20,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -7,
                  top: -7,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      _NavItem(Icons.dashboard_rounded, 'Dashboard'),
      _NavItem(Icons.people_rounded, 'Users'),
      _NavItem(Icons.settings_rounded, 'Settings'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = _selectedIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onItemTapped(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? kAdminPrimary.withValues(alpha: 0.09)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i].icon,
                          color: selected
                              ? kAdminPrimary
                              : Colors.grey.shade400,
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? kAdminPrimary
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
