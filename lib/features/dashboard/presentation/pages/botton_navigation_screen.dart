import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/features/schedule/presentation/pages/calendar_screen.dart';
import 'package:mentalwellness/features/dashboard/presentation/pages/home_screen.dart';
import 'package:mentalwellness/features/settings/presentation/pages/settings_screen.dart';
import 'package:mentalwellness/core/services/notifications/local_notification_service_provider.dart';
import 'package:mentalwellness/features/reminder/presentation/view_model/reminder_notifications_viewmodel.dart';

import 'dart:async';

class BottomNavigationScreen extends ConsumerStatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  ConsumerState<BottomNavigationScreen> createState() =>
      _BottomNavigationScreenState();
}

class _BottomNavigationScreenState
    extends ConsumerState<BottomNavigationScreen> {
  int _selectedIndex = 0;
  Timer? _duePoll;

  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    SettingsScreen(),
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

      await ref
          .read(reminderNotificationsViewModelProvider.notifier)
          .fetchHistory();

      ref
          .read(reminderNotificationsViewModelProvider.notifier)
          .checkDueAndNotify();
      _duePoll?.cancel();
      _duePoll = Timer.periodic(const Duration(minutes: 1), (_) {
        ref
            .read(reminderNotificationsViewModelProvider.notifier)
            .checkDueAndNotify();
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
    final isTablet = MediaQuery.sizeOf(context).width >= 900;

    final navBar = BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: isTablet
          ? Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: navBar,
                  ),
                ),
              ),
            )
          : navBar,
    );
  }
}
