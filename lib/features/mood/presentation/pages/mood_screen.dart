import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/features/mood/presentation/state/mood_state.dart';
import 'package:mentalwellness/features/mood/presentation/view_model/mood_viewmodel.dart';
import 'package:mentalwellness/features/mood/presentation/widgets/mood_history_tab.dart';
import 'package:mentalwellness/features/mood/presentation/widgets/mood_log_tab.dart';
import 'package:mentalwellness/features/mood/presentation/widgets/mood_overview_tab.dart';

class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  String? _selectedMoodLabel;
  int? _selectedMoodScore;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(moodViewModelProvider, (previous, next) {
      if (next.status == MoodStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    final state = ref.watch(moodViewModelProvider);
    final notifier = ref.read(moodViewModelProvider.notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F1EA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F1EA),
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1F2A22)),
          title: const Text(
            'Mood',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay Bold',
              fontSize: 18,
              color: Color(0xFF1F2A22),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => notifier.refresh(),
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF2D5A44),
            unselectedLabelColor: Color(0xFF7B8A7E),
            indicatorColor: Color(0xFF2D5A44),
            labelStyle: TextStyle(fontFamily: 'Inter Bold', fontSize: 13),
            unselectedLabelStyle: TextStyle(fontFamily: 'Inter Medium', fontSize: 13),
            tabs: [
              Tab(text: 'Log'),
              Tab(text: 'Overview'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: SafeArea(
          child: Builder(
            builder: (context) {
              if (state.status == MoodStatus.loading &&
                  state.overview == null &&
                  state.moods.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2D5A44)),
                );
              }

              return TabBarView(
                children: [
                  MoodLogTab(
                    state: state,
                    onRefresh: notifier.refresh,
                    selectedLabel: _selectedMoodLabel,
                    selectedScore: _selectedMoodScore,
                    onSelect: (label, score) {
                      setState(() {
                        _selectedMoodLabel = label;
                        _selectedMoodScore = score;
                      });
                    },
                    noteController: _noteController,
                    onSave: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final label = _selectedMoodLabel;
                      final score = _selectedMoodScore;
                      if (label == null || label.trim().isEmpty || score == null) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Pick how you feel first.')),
                        );
                        return;
                      }

                      final ok = await notifier.logMood(
                        mood: score.clamp(1, 10),
                        moodType: label,
                        note: _noteController.text,
                        date: DateTime.now(),
                      );
                      if (!ok || !mounted) return;
                      _noteController.clear();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Mood saved')),
                      );
                    },
                  ),
                  MoodOverviewTab(
                    overview: state.overview,
                    onRefresh: notifier.refresh,
                  ),
                  MoodHistoryTab(
                    state: state,
                    onRefresh: notifier.refresh,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
