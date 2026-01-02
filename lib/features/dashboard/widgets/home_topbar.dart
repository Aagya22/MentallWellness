import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final greeting = _getGreeting();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.orangeAccent,
              child: const Icon(Icons.face_2, color: Colors.black),
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
