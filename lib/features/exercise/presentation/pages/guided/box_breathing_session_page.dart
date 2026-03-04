import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/features/exercise/presentation/pages/guided/guided_session_utils.dart';
import 'package:mentalwellness/features/exercise/presentation/view_model/exercise_viewmodel.dart';

enum _Status { begin, running, paused, complete }

enum _Phase { inhale, hold, exhale }

class BoxBreathingSessionPage extends ConsumerStatefulWidget {
  const BoxBreathingSessionPage({super.key});

  @override
  ConsumerState<BoxBreathingSessionPage> createState() => _BoxBreathingSessionPageState();
}

class _BoxBreathingSessionPageState extends ConsumerState<BoxBreathingSessionPage> {
  static const int _phaseSeconds = 4;
  static const int _cycles = 4;
  static const int _plannedSeconds = _phaseSeconds * 4 * _cycles; // 64s

  _Status _status = _Status.begin;
  int _elapsedSeconds = 0;

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
        _elapsedSeconds = (_elapsedSeconds + 1).clamp(0, _plannedSeconds);
        if (_elapsedSeconds >= _plannedSeconds) {
          _status = _Status.complete;
          _timer?.cancel();
        }
      });

      if (_status == _Status.complete) {
        _saveIfNeeded();
      }
    });
  }

  Future<void> _saveIfNeeded() async {
    if (_didSave) return;
    _didSave = true;

    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });

    final ok = await ref.read(exerciseViewModelProvider.notifier).completeGuidedExercise(
          title: 'Box Breathing',
          category: 'Breathing',
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

  Map<String, dynamic> _segmentForElapsed(int elapsedSeconds) {
    final totalSegments = _cycles * 4;
    final clamped = elapsedSeconds.clamp(0, _plannedSeconds);
    final segIndex = (clamped ~/ _phaseSeconds).clamp(0, totalSegments - 1);
    final segElapsed = clamped % _phaseSeconds;

    final segInCycle = segIndex % 4; // 0 inhale, 1 hold-large, 2 exhale, 3 hold-small
    final cycle = (segIndex ~/ 4) + 1;

    final phase = segInCycle == 0
        ? _Phase.inhale
        : segInCycle == 2
            ? _Phase.exhale
            : _Phase.hold;

    final holdSize = segInCycle == 1 ? 'large' : 'small';
    final remainingInPhase = _phaseSeconds - segElapsed;

    return {
      'cycle': cycle,
      'phase': phase,
      'holdSize': holdSize,
      'remainingInPhase': remainingInPhase,
    };
  }

  String _instruction(_Phase phase, String holdSize) {
    if (phase == _Phase.inhale) return 'Breathe in slowly…';
    if (phase == _Phase.exhale) return 'Breathe out slowly…';
    return holdSize == 'large' ? 'Hold your breath…' : 'Hold…';
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
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Exit')),
          ],
        );
      },
    );

    return res ?? false;
  }

  void _begin() {
    setState(() {
      _elapsedSeconds = 0;
      _status = _Status.running;
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

  @override
  Widget build(BuildContext context) {
    final seg = _segmentForElapsed(_elapsedSeconds);
    final phase = seg['phase'] as _Phase;
    final holdSize = seg['holdSize'] as String;
    final remainingInPhase = seg['remainingInPhase'] as int;
    final cycle = seg['cycle'] as int;

    final progress = _status == _Status.begin
        ? 0.0
        : _status == _Status.complete
            ? 1.0
            : _elapsedSeconds / _plannedSeconds;

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
          title: const Text('Box Breathing'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      _status == _Status.complete ? 'Nicely done' : 'Cycle $cycle of $_cycles',
                      style: const TextStyle(fontFamily: 'Inter Bold', fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _status == _Status.complete ? 'You completed 4 calm breathing cycles.' : _instruction(phase, holdSize),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Inter Medium', fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    if (_status != _Status.complete)
                      Text(
                        '$remainingInPhase s',
                        style: const TextStyle(fontFamily: 'Inter Bold', fontSize: 32),
                      )
                    else
                      Text(
                        _isSaving
                            ? 'Saving your session…'
                            : _saveFailed
                                ? 'Couldn\'t save this session.'
                                : 'Session saved to history.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'Inter Medium', fontSize: 13),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      formatSeconds(_plannedSeconds - _elapsedSeconds),
                      style: const TextStyle(fontFamily: 'Inter Regular', fontSize: 12, color: Color(0xFF5A6B60)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_status == _Status.begin)
                ElevatedButton(
                  onPressed: _begin,
                  child: const Text('Begin session'),
                )
              else if (_status == _Status.running)
                ElevatedButton(
                  onPressed: _pause,
                  child: const Text('Pause'),
                )
              else if (_status == _Status.paused)
                ElevatedButton(
                  onPressed: _resume,
                  child: const Text('Resume'),
                )
              else ...[
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
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
      ),
    );
  }
}
