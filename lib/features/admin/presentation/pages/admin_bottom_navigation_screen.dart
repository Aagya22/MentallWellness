import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:mentalwellness/features/admin/presentation/pages/admin_dashboard_tab.dart';
import 'package:mentalwellness/features/admin/presentation/pages/admin_settings_tab.dart';
import 'package:mentalwellness/features/admin/presentation/pages/admin_users_tab.dart';
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

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

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
              },
              child: const Icon(Icons.person_add_alt_1_rounded),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(String tabTitle) {
    final session = ref.read(userSessionServiceProvider);
    final adminName = session.getCurrentUserFullName() ?? 'Administrator';
    final adminPic = session.getCurrentUserProfilePicture();
    final initial = adminName.isNotEmpty
        ? adminName.substring(0, 1).toUpperCase()
        : 'A';

    ImageProvider? avatarImage;
    if (adminPic != null && adminPic.isNotEmpty) {
      avatarImage = NetworkImage(ApiEndpoints.getImageUrl(adminPic));
    }

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
                // Profile picture avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    gradient: avatarImage == null
                        ? const LinearGradient(
                            colors: [Color(0xFF818CF8), Color(0xFFA78BFA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: ClipOval(
                    child: avatarImage != null
                        ? Image(image: avatarImage, fit: BoxFit.cover)
                        : Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
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
                if (_selectedIndex == 1)
                  _headerAction(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Refresh',
                    onTap: () {
                      final s = ref.read(adminUsersViewModelProvider);
                      ref
                          .read(adminUsersViewModelProvider.notifier)
                          .fetchUsers(
                            page: s.page,
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
