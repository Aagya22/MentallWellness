import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
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
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      final snapshot = ref.read(adminUsersViewModelProvider);
      _searchController.text = snapshot.search;
      if (snapshot.users.isEmpty) {
        ref
            .read(adminUsersViewModelProvider.notifier)
            .fetchUsers(
              page: 1,
              limit: snapshot.limit,
              search: snapshot.search,
            );
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(adminUsersViewModelProvider.notifier).loadMoreUsers();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
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
                  final snapshot = state;
                  await ref
                      .read(adminUsersViewModelProvider.notifier)
                      .refreshLoadedPages(
                        loadedPages: snapshot.page,
                        limit: snapshot.limit,
                        search: snapshot.search,
                      );
                },
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: state.users.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index >= state.users.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: kAdminPrimary,
                          ),
                        ),
                      );
                    }

                    final user = state.users[index];
                    return _UserCard(
                      fullName: user.fullName,
                      email: user.email,
                      username: user.username,
                      phone: user.phoneNumber,
                      role: user.role,
                      imageUrl: user.imageUrl,
                      onTap: () async {
                        final snapshot = state;
                        await Navigator.pushNamed(
                          context,
                          '/AdminUserDetailScreen',
                          arguments: user.id,
                        );
                        if (!context.mounted) return;
                        await ref
                            .read(adminUsersViewModelProvider.notifier)
                            .refreshLoadedPages(
                              loadedPages: snapshot.page,
                              limit: snapshot.limit,
                              search: snapshot.search,
                            );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
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
  final String? imageUrl;
  final VoidCallback onTap;

  const _UserCard({
    required this.fullName,
    required this.email,
    required this.username,
    required this.phone,
    required this.role,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = fullName.isNotEmpty
        ? fullName.substring(0, 1).toUpperCase()
        : '?';
    final isAdmin = role == 'admin';
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

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
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: hasImage
                        ? null
                        : LinearGradient(
                            colors: isAdmin
                                ? [kAdminPrimary, kAdminSecondary]
                                : [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: hasImage ? const Color(0xFFE2E8F0) : null,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: hasImage
                      ? Image.network(
                          ApiEndpoints.getImageUrl(imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : Text(
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
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
                      const SizedBox(height: 6),
                      Text(
                        'Tap card to view details',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
