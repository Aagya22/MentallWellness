import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/core/services/sensors/motion_sensor_service.dart';
import 'package:mentalwellness/features/exercise/presentation/pages/guided/guided_session_ui.dart';
import 'package:mentalwellness/features/exercise/presentation/pages/guided/guided_session_utils.dart';
import 'package:mentalwellness/features/exercise/presentation/view_model/exercise_viewmodel.dart';

enum _Status { begin, running, paused, complete }

enum _Phase { inhale, hold, exhale }

class BoxBreathingSessionPage extends ConsumerStatefulWidget {
  const BoxBreathingSessionPage({super.key});

  @override
  ConsumerState<BoxBreathingSessionPage> createState() =>
      _BoxBreathingSessionPageState();
}

class _BoxBreathingSessionPageState
    extends ConsumerState<BoxBreathingSessionPage> {
  static const int _phaseSeconds = 4;
  static const int _cycles = 4;
  static const int _plannedSeconds = _phaseSeconds * 4 * _cycles; // 64s
  static const double _stillnessThreshold = 70.0;

  _Status _status = _Status.begin;
  int _elapsedSeconds = 0;

  Timer? _timer;
  StreamSubscription<MotionSample>? _motionSub;

  final List<double> _recentStillnessScores = <double>[];
  double _stillnessScore = 100.0;
  double _latestLinearAcceleration = 0.0;
  double _latestAngularVelocity = 0.0;
  bool _isStill = true;

  bool _isSaving = false;
  bool _saveFailed = false;
  bool _didSave = false;

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_stopMotionTracking());
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
          unawaited(_stopMotionTracking());
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

    final ok = await ref
        .read(exerciseViewModelProvider.notifier)
        .completeGuidedExercise(
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

    final segInCycle =
        segIndex % 4; // 0 inhale, 1 hold-large, 2 exhale, 3 hold-small
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

  void _startMotionTracking() {
    _motionSub?.cancel();
    _recentStillnessScores.clear();

    final motionService = ref.read(motionSensorServiceProvider);
    motionService.start();

    _motionSub = motionService.stream.listen((sample) {
      if (!mounted) return;

      _recentStillnessScores.add(sample.stillnessScore);
      if (_recentStillnessScores.length > 8) {
        _recentStillnessScores.removeAt(0);
      }

      final averagedStillnessScore =
          _recentStillnessScores.reduce((a, b) => a + b) /
          _recentStillnessScores.length;

      setState(() {
        _stillnessScore = averagedStillnessScore;
        _latestLinearAcceleration = sample.linearAcceleration;
        _latestAngularVelocity = sample.angularVelocity;
        _isStill = averagedStillnessScore >= _stillnessThreshold;
      });
    });
  }

  Future<void> _stopMotionTracking() async {
    await _motionSub?.cancel();
    _motionSub = null;
    await ref.read(motionSensorServiceProvider).stop();
  }

  String _stillnessLabel(double score) {
    if (score >= 80) return 'Very steady';
    if (score >= 70) return 'Steady';
    if (score >= 50) return 'Some movement';
    return 'Movement detected';
  }

  Color _stillnessColor(double score) {
    if (score >= 70) return const Color(0xFF2D5A44);
    if (score >= 50) return const Color(0xFFB0792A);
    return const Color(0xFF8B2E2E);
  }

  void _begin() {
    setState(() {
      _elapsedSeconds = 0;
      _status = _Status.running;
    });
    _startMotionTracking();
    _startTimer();
  }

  void _pause() {
    if (_status != _Status.running) return;
    _timer?.cancel();
    setState(() => _status = _Status.paused);
    unawaited(_stopMotionTracking());
  }

  void _resume() {
    if (_status != _Status.paused) return;
    setState(() => _status = _Status.running);
    _startMotionTracking();
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
        await _stopMotionTracking();
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
            'Box Breathing',
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
                progress: progress,
                statusText: 'Box breathing session',
                trailingText: _status == _Status.complete
                    ? 'Completed'
                    : 'Cycle $cycle/$_cycles',
              ),
              const SizedBox(height: 12),
              GuidedHeroCard(
                icon: Icons.air_rounded,
                title: _status == _Status.complete
                    ? 'Nicely done'
                    : _instruction(phase, holdSize),
                subtitle: _status == _Status.complete
                    ? 'You completed 4 calm breathing cycles.'
                    : 'Follow the pace: inhale, hold, exhale, and hold again.',
                highlightText: _status == _Status.complete
                    ? 'Done'
                    : '$remainingInPhase s',
                footerText: _status == _Status.complete
                    ? (_isSaving
                          ? 'Saving your session...'
                          : _saveFailed
                          ? 'Could not save this session.'
                          : 'Session saved to history.')
                    : 'Remaining ${formatSeconds(_plannedSeconds - _elapsedSeconds)}',
                gradientColors: const [Color(0xFF2D5A44), Color(0xFF4B7892)],
              ),
              const SizedBox(height: 12),
              GuidedSectionCard(
                title: 'Motion feedback',
                icon: Icons.sensors_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Stillness quality',
                          style: TextStyle(
                            fontFamily: 'Inter Medium',
                            fontSize: 12,
                            color: Color(0xFF5A6B60),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _stillnessColor(
                              _stillnessScore,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _stillnessLabel(_stillnessScore),
                            style: TextStyle(
                              fontFamily: 'Inter Medium',
                              fontSize: 11,
                              color: _stillnessColor(_stillnessScore),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_status == _Status.begin)
                      const Text(
                        'Start the session to activate accelerometer and gyroscope tracking.',
                        style: TextStyle(
                          fontFamily: 'Inter Regular',
                          fontSize: 12,
                          color: Color(0xFF5A6B60),
                          height: 1.35,
                        ),
                      )
                    else ...[
                      LinearProgressIndicator(
                        value: (_stillnessScore / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(8),
                        color: _stillnessColor(_stillnessScore),
                        backgroundColor: const Color(0xFFEAF1ED),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isStill
                            ? 'Nice and calm. Keep your device steady while breathing.'
                            : 'You are moving a bit. Try keeping your phone still for better focus.',
                        style: const TextStyle(
                          fontFamily: 'Inter Regular',
                          fontSize: 12,
                          color: Color(0xFF5A6B60),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _MotionValueTile(
                              label: 'Accel',
                              value:
                                  '${_latestLinearAcceleration.toStringAsFixed(2)} m/s²',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MotionValueTile(
                              label: 'Gyro',
                              value:
                                  '${_latestAngularVelocity.toStringAsFixed(2)} rad/s',
                            ),
                          ),
                        ],
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
                    else if (_status == _Status.running)
                      ElevatedButton.icon(
                        onPressed: _pause,
                        icon: const Icon(Icons.pause_rounded),
                        label: const Text('Pause'),
                      )
                    else if (_status == _Status.paused)
                      ElevatedButton.icon(
                        onPressed: _resume,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Resume'),
                      )
                    else ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _stopMotionTracking();
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
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

class _MotionValueTile extends StatelessWidget {
  const _MotionValueTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter Medium',
              fontSize: 11,
              color: Color(0xFF5A6B60),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter Bold',
              fontSize: 12,
              color: Color(0xFF1F2A22),
            ),
          ),
        ],
      ),
    );
  }
}
