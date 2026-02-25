import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/features/schedule/presentation/pages/calendar_screen.dart';
import 'package:mentalwellness/features/dashboard/presentation/pages/home_screen.dart';
import 'package:mentalwellness/features/dashboard/presentation/pages/profile_screen.dart';
import 'package:mentalwellness/core/services/notifications/local_notification_service_provider.dart';
import 'package:mentalwellness/features/reminder/presentation/view_model/reminder_notifications_viewmodel.dart';

import 'dart:async';

class BottomNavigationScreen extends ConsumerStatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  ConsumerState<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends ConsumerState<BottomNavigationScreen> {
  int _selectedIndex = 0;
  Timer? _duePoll;

  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(localNotificationServiceProvider).init();
      // Fetch history once so any newly backfilled items can be surfaced as OS notifications.
      await ref.read(reminderNotificationsViewModelProvider.notifier).fetchHistory();
      // Check due reminders periodically while app is in foreground.
      ref.read(reminderNotificationsViewModelProvider.notifier).checkDueAndNotify();
      _duePoll?.cancel();
      _duePoll = Timer.periodic(const Duration(minutes: 1), (_) {
        ref.read(reminderNotificationsViewModelProvider.notifier).checkDueAndNotify();
      });
    });
  }

  @override
  void dispose() {
    _duePoll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
         
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
