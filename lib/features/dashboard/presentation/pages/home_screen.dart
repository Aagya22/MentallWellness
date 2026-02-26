import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:mentalwellness/features/dashboard/presentation/widgets/home_events_section.dart';
import 'package:mentalwellness/features/dashboard/presentation/widgets/home_greeting_card.dart';
import 'package:mentalwellness/features/dashboard/presentation/widgets/home_quick_actions_section.dart';
import 'package:mentalwellness/features/dashboard/presentation/widgets/home_reminders_section.dart';
import 'package:mentalwellness/features/dashboard/presentation/widgets/home_section_header.dart';
import 'package:mentalwellness/features/dashboard/presentation/widgets/home_top_bar.dart';
import 'package:mentalwellness/features/dashboard/presentation/widgets/home_weekly_mood_section.dart';
import 'package:mentalwellness/features/schedule/presentation/pages/calendar_screen.dart';
import 'package:mentalwellness/features/schedule/presentation/state/schedule_state.dart';
import 'package:mentalwellness/features/schedule/presentation/view_model/schedule_viewmodel.dart';
import 'package:mentalwellness/features/exercise/presentation/pages/exercise_screen.dart';
import 'package:mentalwellness/features/journal/presentation/pages/journal_screen.dart';
import 'package:mentalwellness/features/mood/presentation/pages/mood_screen.dart';
import 'package:mentalwellness/features/mood/presentation/state/mood_state.dart';
import 'package:mentalwellness/features/mood/presentation/view_model/mood_viewmodel.dart';
import 'package:mentalwellness/features/reminder/presentation/pages/reminders_screen.dart';
import 'package:mentalwellness/features/reminder/presentation/state/reminder_notifications_state.dart';
import 'package:mentalwellness/features/reminder/presentation/state/reminder_state.dart';
import 'package:mentalwellness/features/reminder/presentation/view_model/reminder_notifications_viewmodel.dart';
import 'package:mentalwellness/features/reminder/presentation/view_model/reminder_viewmodel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(moodViewModelProvider.notifier).refresh();
      ref.read(reminderViewModelProvider.notifier).fetchReminders();
      ref
          .read(reminderNotificationsViewModelProvider.notifier)
          .fetchHistory(limit: 20);

      final now = DateTime.now();
      ref
          .read(scheduleViewModelProvider.notifier)
          .fetchForRange(from: now, to: now.add(const Duration(days: 14)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final userSession = ref.watch(userSessionServiceProvider);
    final userName = userSession.getCurrentUserFullName() ?? 'User';
    final initials = _initialsFromName(userName);
    final profilePicture = userSession.getCurrentUserProfilePicture();
    final profilePictureUrl =
        (profilePicture != null && profilePicture.isNotEmpty)
        ? ApiEndpoints.getImageUrl(profilePicture)
        : null;

    final now = DateTime.now();
    final greeting = _timeGreeting(now);
    final headerDate = DateFormat('EEEE, MMM d').format(now).toUpperCase();

    final moodState = ref.watch(moodViewModelProvider);
    final reminderState = ref.watch(reminderViewModelProvider);
    final reminderNotificationsState = ref.watch(
      reminderNotificationsViewModelProvider,
    );
    final scheduleState = ref.watch(scheduleViewModelProvider);

    final moodIsLoading =
        moodState.status == MoodStatus.loading ||
        moodState.status == MoodStatus.initial;
    final remindersIsLoading =
        reminderState.status == ReminderStatus.loading ||
        reminderState.status == ReminderStatus.initial ||
        reminderNotificationsState.status ==
            ReminderNotificationsStatus.loading ||
        reminderNotificationsState.status ==
            ReminderNotificationsStatus.initial;
    final eventsIsLoading =
        scheduleState.status == ScheduleStatus.loading ||
        scheduleState.status == ScheduleStatus.initial;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeTopBar(
                initials: initials,
                profilePictureUrl: profilePictureUrl,
                onTapNotifications: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  );
                },
              ),
              const SizedBox(height: 14),
              HomeGreetingCard(
                headerDate: headerDate,
                greeting: greeting,
                userName: userName,
                onTapLogMood: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const MoodScreen()));
                },
              ),
              const SizedBox(height: 18),
              HomeSectionHeader(
                title: 'Weekly Mood',
                onSeeMore: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const MoodScreen()));
                },
              ),
              const SizedBox(height: 10),
              HomeWeeklyMoodSection(
                overview: moodState.overview,
                isLoading: moodIsLoading,
                onTapLogMood: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const MoodScreen()));
                },
              ),
              const SizedBox(height: 18),
              HomeSectionHeader(
                title: 'Reminders',
                onSeeMore: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              HomeRemindersSection(
                isLoading: remindersIsLoading,
                reminders: reminderState.reminders,
                notifications: reminderNotificationsState.notifications,
                onTapReminders: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  );
                },
              ),
              const SizedBox(height: 18),
              HomeQuickActionsSection(
                onTapJournal: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JournalScreen()),
                  );
                },
                onTapExercises: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ExerciseScreen()),
                  );
                },
              ),
              const SizedBox(height: 18),
              HomeSectionHeader(
                title: 'Events',
                onSeeMore: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CalendarScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              HomeEventsSection(
                isLoading: eventsIsLoading,
                schedules: scheduleState.schedules,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _timeGreeting(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String _initialsFromName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'U';
  final first = parts.first.substring(0, 1).toUpperCase();
  final second = parts.length > 1 ? parts[1].substring(0, 1).toUpperCase() : '';
  return '$first$second';
}
