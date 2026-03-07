import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

final motionSensorServiceProvider = Provider<MotionSensorService>((ref) {
  final service = MotionSensorService();
  ref.onDispose(service.dispose);
  return service;
});

class MotionSample {
  final double linearAcceleration;
  final double angularVelocity;
  final double stillnessScore;
  final bool isStill;
  final DateTime capturedAt;

  const MotionSample({
    required this.linearAcceleration,
    required this.angularVelocity,
    required this.stillnessScore,
    required this.isStill,
    required this.capturedAt,
  });
}

class MotionSensorService {
  static const Duration _emitInterval = Duration(milliseconds: 250);
  static const double _stillnessThreshold = 70.0;

  StreamSubscription<UserAccelerometerEvent>? _userAccelerometerSub;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSub;

  final _controller = StreamController<MotionSample>.broadcast();

  bool _isRunning = false;
  DateTime _lastEmitAt = DateTime.fromMillisecondsSinceEpoch(0);
  double _latestLinearAcceleration = 0.0;
  double _latestAngularVelocity = 0.0;

  bool get isRunning => _isRunning;
  Stream<MotionSample> get stream => _controller.stream;

  void start() {
    if (_isRunning) return;

    _isRunning = true;

    _userAccelerometerSub = userAccelerometerEventStream().listen(
      (event) {
        _latestLinearAcceleration = _magnitude3(event.x, event.y, event.z);
        _emitIfDue();
      },
      onError: (_) {},
      cancelOnError: false,
    );

    _gyroscopeSub = gyroscopeEventStream().listen(
      (event) {
        _latestAngularVelocity = _magnitude3(event.x, event.y, event.z);
        _emitIfDue();
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    _isRunning = false;

    await _userAccelerometerSub?.cancel();
    await _gyroscopeSub?.cancel();

    _userAccelerometerSub = null;
    _gyroscopeSub = null;
  }

  void _emitIfDue() {
    if (!_isRunning || _controller.isClosed) return;

    final now = DateTime.now();
    if (now.difference(_lastEmitAt) < _emitInterval) return;
    _lastEmitAt = now;

    final stillnessScore = _stillnessScore(
      linearAcceleration: _latestLinearAcceleration,
      angularVelocity: _latestAngularVelocity,
    );

    _controller.add(
      MotionSample(
        linearAcceleration: _latestLinearAcceleration,
        angularVelocity: _latestAngularVelocity,
        stillnessScore: stillnessScore,
        isStill: stillnessScore >= _stillnessThreshold,
        capturedAt: now,
      ),
    );
  }

  double _stillnessScore({
    required double linearAcceleration,
    required double angularVelocity,
  }) {
    final normalizedAccel = _normalize(linearAcceleration, maxExpected: 1.8);
    final normalizedGyro = _normalize(angularVelocity, maxExpected: 1.5);

    final motionScore = (normalizedAccel * 0.65) + (normalizedGyro * 0.35);
    final stillness = (1.0 - motionScore) * 100.0;
    return stillness.clamp(0.0, 100.0).toDouble();
  }

  double _normalize(double value, {required double maxExpected}) {
    if (maxExpected <= 0) return 0.0;
    return (value / maxExpected).clamp(0.0, 1.0).toDouble();
  }

  double _magnitude3(double x, double y, double z) {
    return math.sqrt((x * x) + (y * y) + (z * z));
  }

  void dispose() {
    unawaited(stop());
    _controller.close();
  }
}
