import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_range_entity.dart';
import 'package:mentalwellness/features/mood/domain/usecases/get_moods_range_usecase.dart';
import 'package:mentalwellness/features/mood/presentation/widgets/mood_shared.dart';
import 'package:mentalwellness/features/schedule/domain/entities/schedule_entity.dart';
import 'package:mentalwellness/features/schedule/presentation/state/schedule_state.dart';
import 'package:mentalwellness/features/schedule/presentation/view_model/schedule_viewmodel.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentMonth;
  late DateTime _selectedDay;

  Timer? _upcomingTick;

  bool _isMoodLoading = false;
  String? _moodError;
  Map<String, MoodRangeEntity> _moodsByDay = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);

    Future.microtask(_loadMonth);

    // Rebuild occasionally so past events drop off automatically.
    _upcomingTick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _upcomingTick?.cancel();
    super.dispose();
  }

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  ({DateTime from, DateTime to, String fromKey, String toKey}) _monthRange(DateTime month) {
    final from = DateTime(month.year, month.month, 1);
    // Fetch a little ahead so the Upcoming list can show next month too.
    final to = DateTime(month.year, month.month + 2, 0);
    return (from: from, to: to, fromKey: _dateKey(from), toKey: _dateKey(to));
  }

  Future<void> _loadMonth() async {
    final range = _monthRange(_currentMonth);

    setState(() {
      _isMoodLoading = true;
      _moodError = null;
    });

    final scheduleFuture = ref.read(scheduleViewModelProvider.notifier).fetchForRange(
          from: range.from,
          to: range.to,
        );

    final moodsFuture = _loadMoods(from: range.fromKey, to: range.toKey);

    await Future.wait([scheduleFuture, moodsFuture]);
  }

  Future<void> _loadMoods({required String from, required String to}) async {
    final usecase = ref.read(getMoodsRangeUsecaseProvider);
    final res = await usecase(from: from, to: to);

    if (!mounted) return;

    res.fold(
      (f) {
        setState(() {
          _isMoodLoading = false;
          _moodsByDay = {};
          _moodError = f.message;
        });
      },
      (list) {
        final next = <String, MoodRangeEntity>{};
        for (final m in list) {
          if (m.dayKey.trim().isEmpty) continue;
          next[m.dayKey] = m;
        }
        setState(() {
          _isMoodLoading = false;
          _moodsByDay = next;
          _moodError = null;
        });
      },
    );
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    final newMonth = DateTime(picked.year, picked.month, 1);
    final monthChanged = newMonth.year != _currentMonth.year || newMonth.month != _currentMonth.month;

    setState(() {
      _selectedDay = DateTime(picked.year, picked.month, picked.day);
      _currentMonth = newMonth;
    });

    if (monthChanged) {
      await _loadMonth();
    }
  }

  Future<void> _prevMonth() async {
    final prev = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    setState(() {
      _currentMonth = prev;
      _selectedDay = DateTime(prev.year, prev.month, 1);
    });
    await _loadMonth();
  }

  Future<void> _nextMonth() async {
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    setState(() {
      _currentMonth = next;
      _selectedDay = DateTime(next.year, next.month, 1);
    });
    await _loadMonth();
  }

  Map<String, List<ScheduleEntity>> _groupByDay(List<ScheduleEntity> schedules) {
    final map = <String, List<ScheduleEntity>>{};
    for (final s in schedules) {
      map.putIfAbsent(s.date, () => []).add(s);
    }
    for (final entry in map.entries) {
      entry.value.sort((a, b) => a.time.compareTo(b.time));
    }
    return map;
  }

  DateTime? _parseScheduleDateTime(ScheduleEntity s) {
    final dm = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s.date);
    final tm = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(s.time);
    if (dm == null || tm == null) return null;
    final y = int.parse(dm.group(1)!);
    final mo = int.parse(dm.group(2)!);
    final d = int.parse(dm.group(3)!);
    final h = int.parse(tm.group(1)!);
    final mi = int.parse(tm.group(2)!);
    return DateTime(y, mo, d, h, mi);
  }

  List<ScheduleEntity> _upcomingSchedules(List<ScheduleEntity> schedules) {
    final now = DateTime.now();
    final upcoming = <({ScheduleEntity s, DateTime dt})>[];
    for (final s in schedules) {
      final dt = _parseScheduleDateTime(s);
      if (dt == null) continue;
      if (!dt.isBefore(now)) {
        upcoming.add((s: s, dt: dt));
      }
    }
    upcoming.sort((a, b) => a.dt.compareTo(b.dt));
    return upcoming.map((e) => e.s).toList();
  }

  Future<void> _openDayDetails(DateTime day, Map<String, List<ScheduleEntity>> byDay) async {
    final key = _dateKey(day);
    final mood = _moodsByDay[key];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _DayDetailsSheet(
        day: day,
        mood: mood,
        schedules: byDay[key] ?? const <ScheduleEntity>[],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleViewModelProvider);
    final dfMonth = DateFormat('MMMM yyyy');

    final byDay = _groupByDay(scheduleState.schedules);
    final upcoming = _upcomingSchedules(scheduleState.schedules);

    final showSaving = scheduleState.status == ScheduleStatus.saving;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Calendar',
          style: TextStyle(
            fontFamily: 'Inter Bold',
            fontSize: 20,
            color: Color(0xFF1F2A22),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _pickDay,
            icon: const Icon(Icons.today_outlined, color: Color(0xFF2D5A44)),
            tooltip: 'Jump to date',
          ),
          IconButton(
            onPressed: _loadMonth,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2D5A44)),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _UpsertScheduleSheet(initialDate: _selectedDay),
          );
        },
        backgroundColor: const Color(0xFF2D5A44),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (showSaving)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFF2D5A44),
              backgroundColor: Color(0xFFEAF1ED),
            ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Month navigation header ──────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: Row(
                      children: [
                        _NavArrow(
                          icon: Icons.chevron_left_rounded,
                          onTap: _prevMonth,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                dfMonth.format(_currentMonth),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Inter Bold',
                                  fontSize: 18,
                                  color: Color(0xFF1F2A22),
                                ),
                              ),
                              if (_isMoodLoading)
                                const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 3),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Color(0xFF2D5A44),
                                    ),
                                  ),
                                )
                              else if (_moodError != null)
                                Text(
                                  _moodError!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter Medium',
                                    fontSize: 10,
                                    color: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _NavArrow(
                          icon: Icons.chevron_right_rounded,
                          onTap: _nextMonth,
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Weekday row ──────────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _WeekdayLabel('S', isSunday: true),
                        _WeekdayLabel('M'),
                        _WeekdayLabel('T'),
                        _WeekdayLabel('W'),
                        _WeekdayLabel('T'),
                        _WeekdayLabel('F'),
                        _WeekdayLabel('S', isSunday: true),
                      ],
                    ),
                  ),
                ),
                // ── Month grid ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                    child: _MonthGrid(
                      month: _currentMonth,
                      selectedDay: _selectedDay,
                      schedulesByDay: byDay,
                      moodsByDay: _moodsByDay,
                      onSelectDay: (d) async {
                        setState(() => _selectedDay = d);
                        await _openDayDetails(d, byDay);
                      },
                    ),
                  ),
                ),
                if (scheduleState.status == ScheduleStatus.loading ||
                    scheduleState.status == ScheduleStatus.initial)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 18),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (scheduleState.status == ScheduleStatus.error)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        scheduleState.errorMessage ?? 'Failed to load schedules',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'Inter Medium'),
                      ),
                    ),
                  )
                // ── Upcoming events ──────────────────────────────
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D5A44),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Upcoming events',
                            style: TextStyle(
                              fontFamily: 'Inter Bold',
                              fontSize: 16,
                              color: Color(0xFF1F2A22),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${upcoming.length}',
                            style: const TextStyle(
                              fontFamily: 'Inter Bold',
                              fontSize: 13,
                              color: Color(0xFF2D5A44),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (upcoming.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 10, 16, 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_available_outlined,
                                size: 36,
                                color: Color(0xFFB0C4BB),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No upcoming events',
                                style: TextStyle(
                                  fontFamily: 'Inter Medium',
                                  fontSize: 14,
                                  color: Color(0xFF5A6B60),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final s = upcoming[index];
                            final d = DateTime.tryParse(s.date) ?? _selectedDay;
                            final isFirst = index == 0;
                            return _UpcomingScheduleTile(
                              schedule: s,
                              scheduleDay: d,
                              isFirst: isFirst,
                            );
                          },
                          childCount: upcoming.length,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF2D5A44)),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label, {this.isSunday = false});

  final String label;
  final bool isSunday;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter Bold',
            fontSize: 11,
            color: isSunday ? const Color(0xFFD96B6B) : const Color(0xFF5A6B60),
          ),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.schedulesByDay,
    required this.moodsByDay,
    required this.onSelectDay,
  });

  final DateTime month;
  final DateTime selectedDay;
  final Map<String, List<ScheduleEntity>> schedulesByDay;
  final Map<String, MoodRangeEntity> moodsByDay;
  final void Function(DateTime day) onSelectDay;

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final first = DateTime(month.year, month.month, 1);

    // Sunday start: Dart weekday is Mon=1..Sun=7
    final offset = first.weekday % 7; // Sun=0, Mon=1..Sat=6

    final totalCells = (() {
      final count = offset + daysInMonth;
      final weeks = (count / 7).ceil();
      return weeks * 7;
    })();

    final today = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.86,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < offset) {
          return const SizedBox.shrink();
        }
        final day = index - offset + 1;
        if (day > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(month.year, month.month, day);
        final key = _dateKey(date);

        final isSelected = DateUtils.isSameDay(date, selectedDay);
        final isToday = DateUtils.isSameDay(date, today);
        final isSunday = date.weekday == DateTime.sunday;

        final events = schedulesByDay[key] ?? const <ScheduleEntity>[];
        final mood = moodsByDay[key];
        final hasIndicator = events.isNotEmpty || mood != null;

        // Today: filled dark-green cell. Selected (not today): outlined. Normal: white.
        Color bg;
        BoxBorder? border;
        Color dayColor;

        if (isToday) {
          bg = const Color(0xFF2D5A44);
          border = null;
          dayColor = Colors.white;
        } else if (isSelected) {
          bg = const Color(0xFFEAF1ED);
          border = Border.all(color: const Color(0xFF2D5A44), width: 1.5);
          dayColor = const Color(0xFF2D5A44);
        } else {
          bg = Colors.white;
          border = Border.all(color: const Color(0xFF1F2A22).withValues(alpha: 0.08));
          dayColor = isSunday ? const Color(0xFFD96B6B) : const Color(0xFF1F2A22);
        }

        final dotColor = isToday ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF2D5A44);

        return GestureDetector(
          onTap: () => onSelectDay(date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: border,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontFamily: isToday || isSelected ? 'Inter Bold' : 'Inter Medium',
                    fontSize: 13,
                    color: dayColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (hasIndicator)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: dotColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                else
                  const SizedBox(height: 5),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DayDetailsSheet extends ConsumerWidget {
  const _DayDetailsSheet({
    required this.day,
    required this.mood,
    required this.schedules,
  });

  final DateTime day;
  final MoodRangeEntity? mood;
  final List<ScheduleEntity> schedules;

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _moodLabel(MoodRangeEntity mood) {
    final t = (mood.moodType ?? '').trim();
    if (t.isNotEmpty) {
      final lower = t.toLowerCase();
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }
    return 'Mood ${mood.mood}/10';
  }

  Future<void> _openAdd(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpsertScheduleSheet(initialDate: day),
    );
  }

  Future<void> _openEdit(BuildContext context, ScheduleEntity schedule) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpsertScheduleSheet(
        initialDate: DateTime.tryParse(schedule.date) ?? day,
        existing: schedule,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, ScheduleEntity schedule) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete event?'),
          content: Text('Delete "${schedule.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    final success = await ref.read(scheduleViewModelProvider.notifier).deleteSchedule(
          id: schedule.id,
          dayToRefresh: day,
        );
    if (!context.mounted) return;

    if (success) {
      showMySnackBar(
        context: context,
        message: 'Event deleted',
        color: const Color(0xFF2D5A44),
      );
    } else {
      final msg = ref.read(scheduleViewModelProvider).errorMessage ?? 'Failed to delete event';
      showMySnackBar(context: context, message: msg, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final df = DateFormat('EEE, MMM d, yyyy');

    final state = ref.watch(scheduleViewModelProvider);
    final byDay = <String, List<ScheduleEntity>>{};
    for (final s in state.schedules) {
      byDay.putIfAbsent(s.date, () => []).add(s);
    }
    final key = _dateKey(day);
    final daySchedules = (byDay[key] ?? schedules).toList()..sort((a, b) => a.time.compareTo(b.time));

    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottom),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F1EA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2A22).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE').format(day),
                          style: const TextStyle(
                            fontFamily: 'Inter Medium',
                            fontSize: 12,
                            color: Color(0xFF5A6B60),
                          ),
                        ),
                        Text(
                          df.format(day),
                          style: const TextStyle(
                            fontFamily: 'Inter Bold',
                            fontSize: 18,
                            color: Color(0xFF1F2A22),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF5A6B60)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1ED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.mood_outlined,
                        size: 18,
                        color: Color(0xFF2D5A44),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Mood',
                      style: TextStyle(
                        fontFamily: 'Inter Medium',
                        fontSize: 13,
                        color: Color(0xFF5A6B60),
                      ),
                    ),
                    const Spacer(),
                    if (mood != null) ...[
                    Text(
                      moodEmojiFor(moodType: mood!.moodType, score: mood!.mood),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _moodLabel(mood!),
                      style: const TextStyle(
                        fontFamily: 'Inter Medium',
                        fontSize: 13,
                        color: Color(0xFF1F2A22),
                      ),
                    ),
                  ] else
                    const Text(
                      'No mood logged',
                      style: TextStyle(
                        fontFamily: 'Inter Medium',
                        fontSize: 13,
                        color: Color(0xFF5A6B60),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Events',
                    style: TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 15,
                      color: Color(0xFF1F2A22),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _openAdd(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5A44),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Add event',
                            style: TextStyle(
                              fontFamily: 'Inter Medium',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (daySchedules.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 32,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'No events for this day',
                        style: TextStyle(
                          fontFamily: 'Inter Medium',
                          fontSize: 13,
                          color: Color(0xFF5A6B60),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: daySchedules.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final s = daySchedules[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // left accent bar
                          Container(
                            width: 4,
                            height: double.infinity,
                            constraints: const BoxConstraints(minHeight: 56),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2D5A44),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.title,
                                          style: const TextStyle(
                                            fontFamily: 'Inter Bold',
                                            fontSize: 14,
                                            color: Color(0xFF1F2A22),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEAF1ED),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          s.time,
                                          style: const TextStyle(
                                            fontFamily: 'Inter Medium',
                                            fontSize: 11,
                                            color: Color(0xFF2D5A44),
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        iconSize: 18,
                                        padding: EdgeInsets.zero,
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _openEdit(context, s);
                                          } else if (value == 'delete') {
                                            _confirmDelete(context, ref, s);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                                        ],
                                      ),
                                    ],
                                  ),
                                          if (s.location != null && s.location!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF5A6B60)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            s.location!.trim(),
                                            style: const TextStyle(
                                              fontFamily: 'Inter Regular',
                                              fontSize: 12,
                                              color: Color(0xFF5A6B60),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (s.description != null && s.description!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      s.description!.trim(),
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
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingScheduleTile extends ConsumerWidget {
  const _UpcomingScheduleTile({
    required this.schedule,
    required this.scheduleDay,
    this.isFirst = false,
  });

  final ScheduleEntity schedule;
  final DateTime scheduleDay;
  final bool isFirst;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isToday = DateUtils.isSameDay(scheduleDay, DateTime.now());
    final dateLabel = isToday ? 'Today' : DateFormat('EEE, MMM d').format(scheduleDay);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          Column(
            children: [
              Container(
                width: 36,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF2D5A44) : const Color(0xFFEAF1ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      schedule.time.split(':')[0],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter Bold',
                        fontSize: 13,
                        color: isToday ? Colors.white : const Color(0xFF2D5A44),
                      ),
                    ),
                    Text(
                      schedule.time.split(':').length > 1
                          ? ':${schedule.time.split(':')[1]}'
                          : '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter Regular',
                        fontSize: 10,
                        color: isToday ? Colors.white70 : const Color(0xFF5A6B60),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Content card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          schedule.title,
                          style: const TextStyle(
                            fontFamily: 'Inter Bold',
                            fontSize: 14,
                            color: Color(0xFF1F2A22),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isToday ? const Color(0xFF2D5A44) : const Color(0xFFEAF1ED),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          dateLabel,
                          style: TextStyle(
                            fontFamily: 'Inter Medium',
                            fontSize: 11,
                            color: isToday ? Colors.white : const Color(0xFF2D5A44),
                          ),
                        ),
                      ),
                    ],
                  ),
                          if (schedule.location != null && schedule.location!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF5A6B60)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            schedule.location!.trim(),
                            style: const TextStyle(
                              fontFamily: 'Inter Regular',
                              fontSize: 12,
                              color: Color(0xFF5A6B60),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpsertScheduleSheet extends ConsumerStatefulWidget {
  const _UpsertScheduleSheet({
    required this.initialDate,
    this.existing,
  });

  final DateTime initialDate;
  final ScheduleEntity? existing;

  @override
  ConsumerState<_UpsertScheduleSheet> createState() => _UpsertScheduleSheetState();
}

class _UpsertScheduleSheetState extends ConsumerState<_UpsertScheduleSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description ?? '';
      _locationController.text = existing.location ?? '';
      _date = DateTime.tryParse(existing.date) ?? widget.initialDate;

      final parts = existing.time.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          _time = TimeOfDay(hour: h, minute: m);
        }
      }
    } else {
      _date = widget.initialDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? widget.initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() => _time = picked);
  }

  String _timeKey(TimeOfDay tod) {
    final hh = tod.hour.toString().padLeft(2, '0');
    final mm = tod.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final date = _date;
    final time = _time;

    if (title.isEmpty) {
      showMySnackBar(context: context, message: 'Title is required', color: Colors.red);
      return;
    }
    if (date == null) {
      showMySnackBar(context: context, message: 'Date is required', color: Colors.red);
      return;
    }
    if (time == null) {
      showMySnackBar(context: context, message: 'Time is required', color: Colors.red);
      return;
    }

    final existing = widget.existing;
    final ok = existing == null
        ? await ref.read(scheduleViewModelProvider.notifier).createSchedule(
              title: title,
              date: date,
              time: _timeKey(time),
              description: _descriptionController.text,
              location: _locationController.text,
            )
        : await ref.read(scheduleViewModelProvider.notifier).updateSchedule(
              id: existing.id,
              title: title,
              date: date,
              time: _timeKey(time),
              description: _descriptionController.text,
              location: _locationController.text,
            );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      showMySnackBar(
        context: context,
        message: widget.existing == null ? 'Event added' : 'Event updated',
        color: const Color(0xFF2D5A44),
      );
    } else {
      final msg = ref.read(scheduleViewModelProvider).errorMessage ??
          (widget.existing == null ? 'Failed to add event' : 'Failed to update event');
      showMySnackBar(context: context, message: msg, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final df = DateFormat('MMM d, yyyy');
    final dateLabel = _date == null ? 'Pick date' : df.format(_date!);
    final timeLabel = _time == null ? 'Pick time' : _time!.format(context);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event',
              style: TextStyle(
                fontFamily: 'Inter Bold',
                fontSize: 16,
                color: Color(0xFF1F2A22),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.existing == null ? 'Add event' : 'Edit event',
              style: const TextStyle(
                fontFamily: 'Inter Medium',
                fontSize: 12,
                color: Color(0xFF5A6B60),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickDate,
                    child: Text(dateLabel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickTime,
                    child: Text(timeLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location (optional)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
