import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/features/exercise/presentation/pages/guided/body_stretch_session_page.dart';
import 'package:mentalwellness/features/exercise/presentation/pages/guided/box_breathing_session_page.dart';
import 'package:mentalwellness/features/exercise/presentation/pages/guided/gratitude_pause_session_page.dart';
import 'package:mentalwellness/features/exercise/presentation/pages/guided/grounding_54321_session_page.dart';
import 'package:mentalwellness/features/exercise/presentation/pages/guided/guided_exercise_meta.dart';
import 'package:mentalwellness/features/exercise/presentation/state/exercise_state.dart';
import 'package:mentalwellness/features/exercise/presentation/view_model/exercise_viewmodel.dart';

class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({super.key});

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _guidedHistoryLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_guidedHistoryLoadedOnce) {
        _guidedHistoryLoadedOnce = true;
        ref.read(exerciseViewModelProvider.notifier).getGuidedHistory();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openGuidedSession(GuidedExerciseMeta meta) async {
    Widget page;
    switch (meta.id) {
      case 'box-breathing':
        page = const BoxBreathingSessionPage();
        break;
      case 'grounding-54321':
        page = const Grounding54321SessionPage();
        break;
      case 'gratitude-pause':
        page = const GratitudePauseSessionPage();
        break;
      case 'body-stretch':
        page = const BodyStretchSessionPage();
        break;
      default:
        return;
    }

    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (!mounted) return;

    // After a session, refresh guided history next time user opens it.
    _guidedHistoryLoadedOnce = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Exercises',
          style: TextStyle(
            fontFamily: 'Inter Bold',
            fontSize: 20,
            color: Color(0xFF1F2A22),
          ),
        ),
        actions: [
          if (_tabController.index == 1)
            IconButton(
              onPressed: () async {
                final confirmed =
                    await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Delete all history?'),
                          content: const Text(
                            'This will permanently delete your exercise history. This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    ) ??
                    false;

                if (!confirmed) return;

                final deletedCount = await ref
                    .read(exerciseViewModelProvider.notifier)
                    .clearHistory();
                if (!mounted) return;
                if (deletedCount == null) {
                  final message =
                      ref.read(exerciseViewModelProvider).errorMessage ??
                      'Failed to clear history';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('History cleared ($deletedCount items)'),
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFF2D5A44),
              ),
              tooltip: 'Delete all history',
            ),
          IconButton(
            onPressed: () {
              ref.read(exerciseViewModelProvider.notifier).refresh();
              if (_tabController.index == 1) {
                _guidedHistoryLoadedOnce = true;
                ref.read(exerciseViewModelProvider.notifier).getGuidedHistory();
              }
            },
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2D5A44)),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF2D5A44),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontFamily: 'Inter Bold',
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Inter Medium',
                fontSize: 13,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF5A6B60),
              tabs: const [
                Tab(text: 'Explore'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (state.status == ExerciseStatus.saving)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFF2D5A44),
              backgroundColor: Color(0xFFEAF1ED),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ExploreTab(onOpenGuided: _openGuidedSession),
                _HistoryTab(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForCategory(String category) {
  final c = category.toLowerCase();
  if (c.contains('breath')) return Icons.air_rounded;
  if (c.contains('ground')) return Icons.nature_rounded;
  if (c.contains('gratitude')) return Icons.volunteer_activism_rounded;
  if (c.contains('stretch') || c.contains('body'))
    return Icons.self_improvement_rounded;
  return Icons.auto_awesome_rounded;
}

Color _accentForCategory(String category) {
  final c = category.toLowerCase();
  if (c.contains('breath')) return const Color(0xFFDCEEFF);
  if (c.contains('ground')) return const Color(0xFFDCEFE4);
  if (c.contains('gratitude')) return const Color(0xFFFFF0DC);
  if (c.contains('stretch') || c.contains('body'))
    return const Color(0xFFEDE4FF);
  return const Color(0xFFEAF1ED);
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab({required this.onOpenGuided});

  final Future<void> Function(GuidedExerciseMeta meta) onOpenGuided;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
      children: [
        const Text(
          'Guided Sessions',
          style: TextStyle(
            fontFamily: 'Inter Bold',
            fontSize: 22,
            color: Color(0xFF1F2A22),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${guidedExercises.length} mindful exercises to try',
          style: const TextStyle(
            fontFamily: 'Inter Regular',
            fontSize: 13,
            color: Color(0xFF5A6B60),
          ),
        ),
        const SizedBox(height: 24),
        ...guidedExercises.map((g) {
          final accent = _accentForCategory(g.category);
          final icon = _iconForCategory(g.category);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => onOpenGuided(g),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1F2A22).withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(
                                icon,
                                size: 26,
                                color: const Color(0xFF2D5A44),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.title,
                                  style: const TextStyle(
                                    fontFamily: 'Inter Bold',
                                    fontSize: 15,
                                    color: Color(0xFF1F2A22),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  g.category,
                                  style: const TextStyle(
                                    fontFamily: 'Inter Regular',
                                    fontSize: 12,
                                    color: Color(0xFF5A6B60),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF1ED),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: Color(0xFF2D5A44),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  g.minutesLabel,
                                  style: const TextStyle(
                                    fontFamily: 'Inter Medium',
                                    fontSize: 12,
                                    color: Color(0xFF2D5A44),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        g.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter Regular',
                          fontSize: 13,
                          color: Color(0xFF5A6B60),
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFF0EDE5)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            size: 18,
                            color: Color(0xFF2D5A44),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Start session',
                            style: TextStyle(
                              fontFamily: 'Inter Bold',
                              fontSize: 13,
                              color: Color(0xFF2D5A44),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Color(0xFF2D5A44),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.state});

  final ExerciseState state;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy');

    DateTime safeParseDay(String yyyyMmDd) =>
        DateTime.tryParse(yyyyMmDd) ?? DateTime.now();

    if (state.isGuidedHistoryLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D5A44)),
      );
    }

    if (state.guidedHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1ED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.self_improvement_outlined,
                size: 36,
                color: Color(0xFF2D5A44),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No sessions yet',
              style: TextStyle(
                fontFamily: 'Inter Bold',
                fontSize: 16,
                color: Color(0xFF1F2A22),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Complete a guided session to see\nyour history here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter Regular',
                fontSize: 13,
                color: Color(0xFF5A6B60),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
      children: [
        const Text(
          'Session History',
          style: TextStyle(
            fontFamily: 'Inter Bold',
            fontSize: 22,
            color: Color(0xFF1F2A22),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${state.guidedHistory.fold(0, (sum, d) => sum + d.sessions.length)} sessions completed',
          style: const TextStyle(
            fontFamily: 'Inter Regular',
            fontSize: 13,
            color: Color(0xFF5A6B60),
          ),
        ),
        const SizedBox(height: 24),
        ...state.guidedHistory.map((day) {
          final dayDate = safeParseDay(day.date);
          final isToday = DateUtils.isSameDay(dayDate, DateTime.now());
          final dateLabel = isToday ? 'Today' : df.format(dayDate);

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFF2D5A44)
                            : const Color(0xFFEAF1ED),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        dateLabel,
                        style: TextStyle(
                          fontFamily: 'Inter Bold',
                          fontSize: 12,
                          color: isToday
                              ? Colors.white
                              : const Color(0xFF2D5A44),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${day.totalMinutes} min',
                      style: const TextStyle(
                        fontFamily: 'Inter Regular',
                        fontSize: 12,
                        color: Color(0xFF5A6B60),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1F2A22).withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ...day.sessions.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        final cat = (s.category ?? '').trim();
                        final icon = _iconForCategory(cat);
                        final accent = _accentForCategory(cat);
                        final isLast = i == day.sessions.length - 1;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: accent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        icon,
                                        size: 22,
                                        color: const Color(0xFF2D5A44),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.title,
                                          style: const TextStyle(
                                            fontFamily: 'Inter Medium',
                                            fontSize: 14,
                                            color: Color(0xFF1F2A22),
                                          ),
                                        ),
                                        if (cat.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            cat,
                                            style: const TextStyle(
                                              fontFamily: 'Inter Regular',
                                              fontSize: 12,
                                              color: Color(0xFF5A6B60),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF1ED),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.timer_outlined,
                                          size: 14,
                                          color: Color(0xFF2D5A44),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${s.duration} min',
                                          style: const TextStyle(
                                            fontFamily: 'Inter Medium',
                                            fontSize: 12,
                                            color: Color(0xFF2D5A44),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: Color(0xFFF0EDE5),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
