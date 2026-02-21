import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:mentalwellness/features/dashboard/presentation/pages/calendar_screen.dart';
import 'package:mentalwellness/features/dashboard/presentation/pages/exercise_screen.dart';
import 'package:mentalwellness/features/dashboard/presentation/pages/journal_screen.dart';
import 'package:mentalwellness/features/dashboard/presentation/pages/mood_screen.dart';
import 'package:mentalwellness/features/dashboard/presentation/pages/reminders_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(
                initials: initials,
                profilePictureUrl: profilePictureUrl,
                onTapNotifications: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  );
                },
              ),
              const SizedBox(height: 14),
              _GreetingCard(
                headerDate: headerDate,
                greeting: greeting,
                userName: userName,
              ),
              const SizedBox(height: 18),
              _SectionHeader(
                icon: Icons.blur_circular,
                title: 'Weekly Mood',
                onSeeMore: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const MoodScreen()));
                },
              ),
              const SizedBox(height: 10),
              _EmptySectionCard(
                icon: Icons.sentiment_satisfied_alt_outlined,
                message: 'No mood entries yet',
                ctaText: 'Log mood',
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const MoodScreen()));
                },
              ),
              const SizedBox(height: 18),
              _SectionHeader(
                icon: Icons.notifications_none,
                title: 'Reminders',
                onSeeMore: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              _EmptySectionCard(
                icon: Icons.notifications_active_outlined,
                message: 'No reminders yet',
                ctaText: 'Create reminder',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  );
                },
              ),
              const SizedBox(height: 18),
              _QuickActionsSection(
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
              _SectionHeader(
                icon: Icons.calendar_today_outlined,
                title: 'Events',
                onSeeMore: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CalendarScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              const _EmptyEventsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.initials,
    required this.profilePictureUrl,
    required this.onTapNotifications,
  });

  final String initials;
  final String? profilePictureUrl;
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
                fontFamily: 'PlayfairDisplay Bold',
                fontSize: 16,
                color: Color(0xFF1F2A22),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        _CircleIconButton(
          icon: Icons.notifications_none,
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
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: const Color(0xFF1F2A22)),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({
    required this.headerDate,
    required this.greeting,
    required this.userName,
  });

  final String headerDate;
  final String greeting;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D5A44),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headerDate,
            style: TextStyle(
              fontFamily: 'Inter Medium',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$greeting,\n$userName',
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay Bold',
              fontSize: 30,
              height: 1.05,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({
    required this.icon,
    required this.message,
    required this.ctaText,
    required this.onTap,
  });

  final IconData icon;
  final String message;
  final String ctaText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1ED),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF2D5A44)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Inter Medium',
                      fontSize: 13,
                      color: Color(0xFF1F2A22),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ctaText,
                    style: const TextStyle(
                      fontFamily: 'Inter Medium',
                      fontSize: 12,
                      color: Color(0xFF2D5A44),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF7B8A7E)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.onSeeMore,
  });

  final IconData icon;
  final String title;
  final VoidCallback onSeeMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF3C4D42)),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay Bold',
            fontSize: 18,
            color: Color(0xFF1F2A22),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onSeeMore,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Text(
              'See more',
              style: TextStyle(
                fontFamily: 'Inter Medium',
                fontSize: 13,
                color: Color(0xFF2D5A44),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    required this.onTapJournal,
    required this.onTapExercises,
  });

  final VoidCallback onTapJournal;
  final VoidCallback onTapExercises;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.auto_awesome, size: 18, color: Color(0xFF3C4D42)),
            SizedBox(width: 10),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay Bold',
                fontSize: 18,
                color: Color(0xFF1F2A22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                tag: 'JOURNAL',
                title: 'Journal',
                actionText: 'Write today',
                accentColor: const Color(0xFFF1E3DD),
                trailingAsset: 'assets/images/journal.jpg',
                onTap: onTapJournal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                tag: 'EXERCISES',
                title: 'Exercises',
                actionText: 'Log workout',
                accentColor: const Color(0xFFE4F0EA),
                trailingAsset: 'assets/images/meditate.jpg',
                onTap: onTapExercises,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.tag,
    required this.title,
    required this.actionText,
    required this.accentColor,
    required this.trailingAsset,
    required this.onTap,
  });

  final String tag;
  final String title;
  final String actionText;
  final Color accentColor;
  final String trailingAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 140,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 6,
              bottom: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  trailingAsset,
                  height: 52,
                  width: 52,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 11,
                      color: Color(0xFF2D5A44),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay Bold',
                    fontSize: 18,
                    height: 1.1,
                    color: Color(0xFF1F2A22),
                  ),
                ),
                const Spacer(),
                Text(
                  actionText,
                  style: const TextStyle(
                    fontFamily: 'Inter Medium',
                    fontSize: 12,
                    color: Color(0xFF2D5A44),
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

class _EmptyEventsCard extends StatelessWidget {
  const _EmptyEventsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1ED),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF2D5A44),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No upcoming events',
            style: TextStyle(
              fontFamily: 'Inter Regular',
              fontSize: 13,
              color: Color(0xFF8B978E),
            ),
          ),
        ],
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
