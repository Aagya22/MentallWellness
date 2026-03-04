import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:mentalwellness/features/admin/presentation/state/admin_users_state.dart';
import 'package:mentalwellness/features/admin/presentation/view_model/admin_users_viewmodel.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminUsersViewModelProvider.notifier).fetchUsers(page: 1);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.read(userSessionServiceProvider).getCurrentUserRole();
    if (role != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/BottomNavigationScreen');
      });
    }

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Users'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref
                  .read(adminUsersViewModelProvider.notifier)
                  .fetchUsers(
                    page: state.page,
                    limit: state.limit,
                    search: state.search,
                  );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search users',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  ref
                      .read(adminUsersViewModelProvider.notifier)
                      .fetchUsers(page: 1, search: value);
                });
              },
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.status == AdminUsersStatus.loading &&
                    state.users.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.users.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return RefreshIndicator(
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
                    itemCount: state.users.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = state.users[index];
                      final subtitle =
                          '${user.email}\n@${user.username} • ${user.phoneNumber}';

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName.substring(0, 1).toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(user.fullName),
                        subtitle: Text(subtitle),
                        isThreeLine: true,
                        trailing: IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final ok =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Delete user?'),
                                      content: Text('Delete ${user.fullName}?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
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
                                .deleteUser(user.id);

                            if (success && context.mounted) {
                              showMySnackBar(
                                context: context,
                                message: 'User deleted',
                                color: Colors.green,
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (state.totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Page ${state.page} of ${state.totalPages} (Total: ${state.total})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Prev',
                    onPressed: state.page <= 1
                        ? null
                        : () {
                            ref
                                .read(adminUsersViewModelProvider.notifier)
                                .fetchUsers(page: state.page - 1);
                          },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: 'Next',
                    onPressed: state.page >= state.totalPages
                        ? null
                        : () {
                            ref
                                .read(adminUsersViewModelProvider.notifier)
                                .fetchUsers(page: state.page + 1);
                          },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
