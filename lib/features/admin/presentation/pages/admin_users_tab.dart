import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/features/admin/presentation/pages/admin_bottom_navigation_screen.dart';
import 'package:mentalwellness/features/admin/presentation/state/admin_users_state.dart';
import 'package:mentalwellness/features/admin/presentation/view_model/admin_users_viewmodel.dart';


class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminUsersViewModelProvider.notifier).fetchUsers(page: 1),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersViewModelProvider);

    ref.listen<AdminUsersState>(adminUsersViewModelProvider, (prev, next) {
      if (next.status == AdminUsersStatus.error && next.errorMessage != null) {
        showMySnackBar(
          context: context,
          message: next.errorMessage!,
          color: Colors.red,
        );
      }
    });

    return Column(
      children: [

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name or email…',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade400,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(adminUsersViewModelProvider.notifier)
                              .fetchUsers(page: 1, search: '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 4,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  ref
                      .read(adminUsersViewModelProvider.notifier)
                      .fetchUsers(page: 1, search: value);
                });
              },
            ),
          ),
        ),


        if (state.total > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${state.total} user${state.total == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),


        Expanded(
          child: Builder(
            builder: (context) {
              if (state.status == AdminUsersStatus.loading &&
                  state.users.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: kAdminPrimary),
                );
              }

              if (state.users.isEmpty) {
                return _EmptyState(hasSearch: state.search.isNotEmpty);
              }

              return RefreshIndicator(
                color: kAdminPrimary,
                onRefresh: () async {
                  await ref
                      .read(adminUsersViewModelProvider.notifier)
                      .fetchUsers(
                        page: state.page,
                        limit: state.limit,
                        search: state.search,
                      );
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: state.users.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = state.users[index];
                    return _UserCard(
                      fullName: user.fullName,
                      email: user.email,
                      username: user.username,
                      phone: user.phoneNumber,
                      role: user.role,
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          '/AdminUserDetailScreen',
                          arguments: user.id,
                        );
                        if (!context.mounted) return;
                        ref
                            .read(adminUsersViewModelProvider.notifier)
                            .fetchUsers(
                              page: state.page,
                              limit: state.limit,
                              search: state.search,
                            );
                      },
                      onEdit: () async {
                        await Navigator.pushNamed(
                          context,
                          '/AdminUserEditScreen',
                          arguments: user.id,
                        );
                        if (!context.mounted) return;
                        ref
                            .read(adminUsersViewModelProvider.notifier)
                            .fetchUsers(
                              page: state.page,
                              limit: state.limit,
                              search: state.search,
                            );
                      },
                      onDelete: () async {
                        final ok =
                            await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text(
                                  'Delete user?',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                content: Text(
                                  'This will permanently remove ${user.fullName}.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (!ok) return;
                        final success = await ref
                            .read(adminUsersViewModelProvider.notifier)
                            .deleteUser(user.id);
                        if (success && context.mounted) {
                          showMySnackBar(
                            context: context,
                            message: 'User deleted',
                            color: Colors.green,
                          );
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),

        if (state.totalPages > 1) _Pagination(state: state),
      ],
    );
  }
}


class _UserCard extends StatelessWidget {
  final String fullName;
  final String email;
  final String username;
  final String phone;
  final String role;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.fullName,
    required this.email,
    required this.username,
    required this.phone,
    required this.role,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initial = fullName.isNotEmpty
        ? fullName.substring(0, 1).toUpperCase()
        : '?';
    final isAdmin = role == 'admin';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAdmin
                      ? [kAdminPrimary, kAdminSecondary]
                      : [const Color(0xFF10B981), const Color(0xFF059669)],
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
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
     
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _RoleBadge(role: role),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@$username${phone.isNotEmpty ? ' · $phone' : ''}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
     
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBtn(
                  icon: Icons.edit_rounded,
                  color: kAdminPrimary,
                  bgColor: const Color(0xFFEEF2FF),
                  onTap: onEdit,
                  tooltip: 'Edit',
                ),
                const SizedBox(height: 6),
                _IconBtn(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red.shade600,
                  bgColor: const Color(0xFFFEF2F2),
                  onTap: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFF5F3FF) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAdmin
              ? kAdminSecondary.withValues(alpha: 0.35)
              : const Color(0xFF10B981).withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isAdmin ? kAdminSecondary : const Color(0xFF059669),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;

  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch ? Icons.search_off_rounded : Icons.people_outline,
              size: 52,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch ? 'No users match your search' : 'No users found',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pagination extends ConsumerWidget {
  final AdminUsersState state;

  const _Pagination({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PaginationBtn(
            label: '← Prev',
            enabled: state.page > 1,
            onTap: () => ref
                .read(adminUsersViewModelProvider.notifier)
                .fetchUsers(page: state.page - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '${state.page} / ${state.totalPages}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
          ),
          _PaginationBtn(
            label: 'Next →',
            enabled: state.page < state.totalPages,
            onTap: () => ref
                .read(adminUsersViewModelProvider.notifier)
                .fetchUsers(page: state.page + 1),
          ),
        ],
      ),
    );
  }
}

class _PaginationBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationBtn({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.35,
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: enabled ? kAdminPrimary : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: enabled ? Colors.white : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}
