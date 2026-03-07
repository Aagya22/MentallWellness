import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/features/exercise/presentation/pages/guided/guided_session_ui.dart';
import 'package:mentalwellness/features/exercise/presentation/pages/guided/guided_session_utils.dart';
import 'package:mentalwellness/features/exercise/presentation/view_model/exercise_viewmodel.dart';

enum _Status { begin, running, paused, complete }

class _Prompt {
  final String id;
  final String text;
  final int seconds;

  const _Prompt({required this.id, required this.text, required this.seconds});
}

const _prompts = <_Prompt>[
  _Prompt(
    id: 'p1',
    text: "Name something you're grateful for today",
    seconds: 40,
  ),
  _Prompt(
    id: 'p2',
    text: 'Name someone who made a difference recently',
    seconds: 40,
  ),
  _Prompt(
    id: 'p3',
    text: 'Name something about yourself you appreciate',
    seconds: 40,
  ),
];

class GratitudePauseSessionPage extends ConsumerStatefulWidget {
  const GratitudePauseSessionPage({super.key});

  @override
  ConsumerState<GratitudePauseSessionPage> createState() =>
      _GratitudePauseSessionPageState();
}

class _GratitudePauseSessionPageState
    extends ConsumerState<GratitudePauseSessionPage> {
  static final int _plannedSeconds = _prompts.fold<int>(
    0,
    (sum, p) => sum + p.seconds,
  ); // 120

  _Status _status = _Status.begin;
  int _index = 0;
  int _remaining = _prompts.first.seconds;

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
    final completed = _prompts
        .take(_index)
        .fold<int>(0, (sum, p) => sum + p.seconds);
    final spent = _prompts[_index].seconds - _remaining;
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
      _remaining = _prompts.first.seconds;
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
    if (_index < _prompts.length - 1) {
      setState(() {
        _index += 1;
        _remaining = _prompts[_index].seconds;
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
          title: 'Gratitude Pause',
          category: 'Reflection',
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
    final prompt = _prompts[_index];

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
            'Gratitude Pause',
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
                statusText: 'Gratitude reflection',
                trailingText: _status == _Status.complete
                    ? 'Completed'
                    : 'Prompt ${_index + 1}/${_prompts.length}',
              ),
              const SizedBox(height: 12),
              GuidedHeroCard(
                icon: Icons.favorite_border_rounded,
                title: _status == _Status.complete
                    ? 'You took a moment for yourself'
                    : prompt.text,
                subtitle: _status == _Status.complete
                    ? 'That matters. Carry this calm feeling into the rest of your day.'
                    : 'Take your time. There is no right answer here.',
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
                gradientColors: const [Color(0xFF6A4C7A), Color(0xFF8A6A9A)],
              ),
              const SizedBox(height: 12),
              GuidedSectionCard(
                title: _status == _Status.complete
                    ? 'Session summary'
                    : 'Reflection cue',
                icon: _status == _Status.complete
                    ? Icons.fact_check_outlined
                    : Icons.lightbulb_outline,
                child: _status == _Status.complete
                    ? const Text(
                        'You finished all gratitude prompts. Repeating this practice can improve mood and focus over time.',
                        style: TextStyle(
                          fontFamily: 'Inter Regular',
                          fontSize: 13,
                          color: Color(0xFF5A6B60),
                          height: 1.4,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Name one detail for the prompt before moving on.',
                            style: TextStyle(
                              fontFamily: 'Inter Regular',
                              fontSize: 13,
                              color: Color(0xFF5A6B60),
                              height: 1.4,
                            ),
                          ),
                          if (_index < _prompts.length - 1) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Next prompt: ${_prompts[_index + 1].text}',
                              style: const TextStyle(
                                fontFamily: 'Inter Medium',
                                fontSize: 12,
                                color: Color(0xFF6A4C7A),
                              ),
                            ),
                          ],
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
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Done reflecting'),
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
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Done reflecting'),
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
