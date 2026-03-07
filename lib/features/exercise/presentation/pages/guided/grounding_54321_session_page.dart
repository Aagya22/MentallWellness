import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/features/exercise/presentation/pages/guided/guided_session_ui.dart';
import 'package:mentalwellness/features/exercise/presentation/pages/guided/guided_session_utils.dart';
import 'package:mentalwellness/features/exercise/presentation/view_model/exercise_viewmodel.dart';

enum _Status { begin, running, paused, complete }

class _Step {
  final int number;
  final String label;
  final String prompt;
  final String description;
  final int seconds;

  const _Step({
    required this.number,
    required this.label,
    required this.prompt,
    required this.description,
    required this.seconds,
  });
}

const _steps = <_Step>[
  _Step(
    number: 5,
    label: 'See',
    prompt: 'Name 5 things you can see',
    description: 'Look around the room. Notice colors, shapes, objects.',
    seconds: 30,
  ),
  _Step(
    number: 4,
    label: 'Hear',
    prompt: 'Name 4 things you can hear',
    description: 'Listen closely. Notice near and far sounds.',
    seconds: 25,
  ),
  _Step(
    number: 3,
    label: 'Touch',
    prompt: 'Name 3 things you can touch',
    description: 'Feel texture and temperature — hands, clothes, chair.',
    seconds: 20,
  ),
  _Step(
    number: 2,
    label: 'Smell',
    prompt: 'Name 2 things you can smell',
    description: 'Breathe gently. Notice any scents in the air.',
    seconds: 15,
  ),
  _Step(
    number: 1,
    label: 'Taste',
    prompt: 'Name 1 thing you can taste',
    description: 'Notice a taste in your mouth, or take a small sip of water.',
    seconds: 10,
  ),
];

class Grounding54321SessionPage extends ConsumerStatefulWidget {
  const Grounding54321SessionPage({super.key});

  @override
  ConsumerState<Grounding54321SessionPage> createState() =>
      _Grounding54321SessionPageState();
}

class _Grounding54321SessionPageState
    extends ConsumerState<Grounding54321SessionPage> {
  static final int _plannedSeconds = _steps.fold<int>(
    0,
    (sum, s) => sum + s.seconds,
  ); // 100

  _Status _status = _Status.begin;
  int _index = 0;
  int _remaining = _steps.first.seconds;

  Timer? _timer;

  bool _isSaving = false;
  bool _saveFailed = false;
  bool _didSave = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = (_remaining - 1).clamp(0, 1 << 30);
      });

      if (_status == _Status.running && _remaining <= 0) {
        _advance();
      }
    });
  }

  int get _elapsedSeconds {
    final completed = _steps
        .take(_index)
        .fold<int>(0, (sum, s) => sum + s.seconds);
    final spent = _steps[_index].seconds - _remaining;
    return (completed + spent).clamp(0, _plannedSeconds);
  }

  double get _progress {
    if (_status == _Status.begin) return 0.0;
    if (_status == _Status.complete) return 1.0;
    return _elapsedSeconds / _plannedSeconds;
  }

  void _begin() {
    setState(() {
      _status = _Status.running;
      _index = 0;
      _remaining = _steps.first.seconds;
    });
    _startTimer();
  }

  void _pause() {
    if (_status != _Status.running) return;
    _timer?.cancel();
    setState(() => _status = _Status.paused);
  }

  void _resume() {
    if (_status != _Status.paused) return;
    setState(() => _status = _Status.running);
    _startTimer();
  }

  void _advance() {
    if (_index < _steps.length - 1) {
      setState(() {
        _index += 1;
        _remaining = _steps[_index].seconds;
      });
      return;
    }

    _timer?.cancel();
    setState(() => _status = _Status.complete);
    _saveIfNeeded();
  }

  Future<void> _saveIfNeeded() async {
    if (_didSave) return;
    _didSave = true;

    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });

    final ok = await ref
        .read(exerciseViewModelProvider.notifier)
        .completeGuidedExercise(
          title: '5-4-3-2-1 Grounding',
          category: 'Anxiety',
          plannedDurationSeconds: _plannedSeconds,
          elapsedSeconds: _plannedSeconds,
          completedAt: DateTime.now(),
        );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _saveFailed = !ok;
    });

    if (ok) {
      showMySnackBar(
        context: context,
        message: 'Session saved to history',
        color: const Color(0xFF2D5A44),
      );
    }
  }

  Future<bool> _confirmExit() async {
    if (_status == _Status.complete) return true;

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Exit session?'),
          content: const Text('It won\'t be saved unless completed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );

    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final ok = await _confirmExit();
        if (!ok) return;

        _timer?.cancel();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F1EA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F1EA),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1F2A22)),
          title: const Text(
            '5-4-3-2-1 Grounding',
            style: TextStyle(
              fontFamily: 'Inter Bold',
              fontSize: 18,
              color: Color(0xFF1F2A22),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              GuidedProgressHeader(
                progress: _progress,
                statusText: 'Grounding session',
                trailingText: _status == _Status.complete
                    ? 'Completed'
                    : 'Step ${_index + 1}/${_steps.length}',
              ),
              const SizedBox(height: 12),
              GuidedHeroCard(
                icon: Icons.spa_outlined,
                title: _status == _Status.complete
                    ? 'Back to the present'
                    : step.prompt,
                subtitle: _status == _Status.complete
                    ? 'You anchored yourself through your senses.'
                    : step.description,
                highlightText: _status == _Status.complete
                    ? 'Done'
                    : '${_remaining}s',
                footerText: _status == _Status.complete
                    ? (_isSaving
                          ? 'Saving your session...'
                          : _saveFailed
                          ? 'Could not save this session.'
                          : 'Session saved to history.')
                    : 'Remaining ${formatSeconds(_plannedSeconds - _elapsedSeconds)}',
                gradientColors: const [Color(0xFF2E5A72), Color(0xFF4B7892)],
              ),
              const SizedBox(height: 12),
              GuidedSectionCard(
                title: _status == _Status.complete
                    ? 'Session summary'
                    : 'Current step',
                icon: _status == _Status.complete
                    ? Icons.fact_check_outlined
                    : Icons.visibility_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_status != _Status.complete)
                      Text(
                        'Focus area: ${step.label} (${step.number})',
                        style: const TextStyle(
                          fontFamily: 'Inter Bold',
                          fontSize: 13,
                          color: Color(0xFF1F2A22),
                        ),
                      ),
                    if (_status != _Status.complete) const SizedBox(height: 8),
                    Text(
                      _status == _Status.complete
                          ? 'You completed all grounding stages: 5, 4, 3, 2, and 1. Great reset.'
                          : '5 -> 4 -> 3 -> 2 -> 1  |  Now: ${step.number}',
                      style: const TextStyle(
                        fontFamily: 'Inter Regular',
                        fontSize: 13,
                        color: Color(0xFF5A6B60),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCE7E1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_status == _Status.begin)
                      ElevatedButton.icon(
                        onPressed: _begin,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Begin session'),
                      )
                    else if (_status == _Status.running) ...[
                      ElevatedButton.icon(
                        onPressed: _pause,
                        icon: const Icon(Icons.pause_rounded),
                        label: const Text('Pause'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _advance,
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Next'),
                      ),
                    ] else if (_status == _Status.paused) ...[
                      ElevatedButton.icon(
                        onPressed: _resume,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Resume'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _advance,
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Next'),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Close'),
                      ),
                      if (_saveFailed)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _didSave = false;
                              _saveFailed = false;
                            });
                            _saveIfNeeded();
                          },
                          child: const Text('Try saving again'),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
