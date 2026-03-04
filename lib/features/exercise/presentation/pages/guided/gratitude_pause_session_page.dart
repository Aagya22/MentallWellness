import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
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
  _Prompt(id: 'p1', text: "Name something you're grateful for today", seconds: 40),
  _Prompt(id: 'p2', text: 'Name someone who made a difference recently', seconds: 40),
  _Prompt(id: 'p3', text: 'Name something about yourself you appreciate', seconds: 40),
];

class GratitudePauseSessionPage extends ConsumerStatefulWidget {
  const GratitudePauseSessionPage({super.key});

  @override
  ConsumerState<GratitudePauseSessionPage> createState() => _GratitudePauseSessionPageState();
}

class _GratitudePauseSessionPageState extends ConsumerState<GratitudePauseSessionPage> {
  static final int _plannedSeconds = _prompts.fold<int>(0, (sum, p) => sum + p.seconds); // 120

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
    final completed = _prompts.take(_index).fold<int>(0, (sum, p) => sum + p.seconds);
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

    final ok = await ref.read(exerciseViewModelProvider.notifier).completeGuidedExercise(
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
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Exit')),
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
        appBar: AppBar(title: const Text('Gratitude Pause')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _status == _Status.complete
                    ? Column(
                        children: [
                          const Text(
                            'You took a moment for yourself.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Inter Bold', fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'That matters.',
                            style: TextStyle(fontFamily: 'Inter Medium', fontSize: 14),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _isSaving
                                ? 'Saving your session…'
                                : _saveFailed
                                    ? 'Couldn\'t save this session.'
                                    : 'Session saved to history.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'Inter Medium', fontSize: 13),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Text(
                            prompt.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'Inter Bold', fontSize: 18),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Take your time. There’s no right answer.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Inter Regular', fontSize: 13, color: Color(0xFF5A6B60)),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '${_remaining}s',
                            style: const TextStyle(fontFamily: 'Inter Bold', fontSize: 32),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatSeconds(_plannedSeconds - _elapsedSeconds),
                            style: const TextStyle(fontFamily: 'Inter Regular', fontSize: 12, color: Color(0xFF5A6B60)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Prompt ${_index + 1} of ${_prompts.length}',
                            style: const TextStyle(fontFamily: 'Inter Medium', fontSize: 12, color: Color(0xFF5A6B60)),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              if (_status == _Status.begin)
                ElevatedButton(onPressed: _begin, child: const Text('Begin session'))
              else if (_status == _Status.running) ...[
                ElevatedButton(onPressed: _pause, child: const Text('Pause')),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: _advance, child: const Text('Done reflecting')),
              ] else if (_status == _Status.paused) ...[
                ElevatedButton(onPressed: _resume, child: const Text('Resume')),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: _advance, child: const Text('Done reflecting')),
              ] else ...[
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
