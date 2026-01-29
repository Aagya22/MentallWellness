import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';

class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else {
      return 'Good afternoon';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userSession = ref.watch(userSessionServiceProvider);
    final userName = userSession.getCurrentUserFullName() ?? 'User';
    final profilePicture = userSession.getCurrentUserProfilePicture();
    final greeting = _getGreeting();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.orangeAccent,
              backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                  ? NetworkImage(ApiEndpoints.getImageUrl(profilePicture))
                  : null,
              child: profilePicture == null || profilePicture.isEmpty
                  ? const Icon(Icons.face_2, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              '$greeting, $userName',
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay Regular',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const Icon(Icons.local_fire_department, size: 28, color: Colors.amber),
      ],
    );
  }
}