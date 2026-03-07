import 'package:flutter/material.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.initials,
    required this.profilePictureUrl,
    required this.unreadCount,
    required this.onTapNotifications,
  });

  final String initials;
  final String? profilePictureUrl;
  final int unreadCount;
  final VoidCallback onTapNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF2D5A44),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/nova.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.spa_outlined, color: Colors.white);
                },
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'NOVANA',
              style: TextStyle(
                fontFamily: 'Inter Bold',
                fontSize: 16,
                color: Color(0xFF1F2A22),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        _CircleIconButton(
          icon: unreadCount > 0
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
          badgeCount: unreadCount,
          onTap: onTapNotifications,
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF2D5A44),
          backgroundImage: profilePictureUrl != null
              ? NetworkImage(profilePictureUrl!)
              : null,
          child: profilePictureUrl == null
              ? Text(
                  initials,
                  style: const TextStyle(
                    fontFamily: 'Inter Bold',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F2A22).withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF1F2A22), size: 20),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B2E2E),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
