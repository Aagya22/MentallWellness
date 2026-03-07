import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ambient_light_source.dart'
    if (dart.library.io) 'ambient_light_source_mobile.dart';

final ambientLightServiceProvider = Provider<AmbientLightService>((ref) {
  final service = AmbientLightService();
  ref.onDispose(service.dispose);
  return service;
});

enum AmbientLightLevel { unknown, dark, dim, normal, bright }

class AmbientLightSample {
  final double? lux;
  final AmbientLightLevel level;
  final bool sensorAvailable;
  final DateTime capturedAt;

  const AmbientLightSample({
    required this.lux,
    required this.level,
    required this.sensorAvailable,
    required this.capturedAt,
  });

  factory AmbientLightSample.unavailable({required DateTime capturedAt}) {
    return AmbientLightSample(
      lux: null,
      level: AmbientLightLevel.unknown,
      sensorAvailable: false,
      capturedAt: capturedAt,
    );
  }
}

class AmbientLightService {
  static const Duration _noDataTimeout = Duration(seconds: 3);

  final AmbientLightSource _source = createAmbientLightSource();
  final _controller = StreamController<AmbientLightSample>.broadcast();

  StreamSubscription<int>? _subscription;
  Timer? _noDataTimer;
  bool _isRunning = false;
  bool _receivedAnyReading = false;

  bool get isRunning => _isRunning;
  Stream<AmbientLightSample> get stream => _controller.stream;

  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _receivedAnyReading = false;

    _noDataTimer?.cancel();
    _noDataTimer = Timer(_noDataTimeout, () {
      if (_controller.isClosed || _receivedAnyReading) return;
      _controller.add(
        AmbientLightSample.unavailable(capturedAt: DateTime.now()),
      );
    });

    _subscription = _source.lightStream.listen(
      (luxValue) {
        if (_controller.isClosed) return;

        if (luxValue < 0) {
          _controller.add(
            AmbientLightSample.unavailable(capturedAt: DateTime.now()),
          );
          return;
        }

        _receivedAnyReading = true;
        final lux = luxValue.toDouble();

        _controller.add(
          AmbientLightSample(
            lux: lux,
            level: _mapLightLevel(lux),
            sensorAvailable: true,
            capturedAt: DateTime.now(),
          ),
        );
      },
      onError: (_) {
        if (_controller.isClosed) return;
        _controller.add(
          AmbientLightSample.unavailable(capturedAt: DateTime.now()),
        );
      },
      cancelOnError: false,
    );
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    _isRunning = false;

    _noDataTimer?.cancel();
    _noDataTimer = null;

    await _subscription?.cancel();
    _subscription = null;
  }

  AmbientLightLevel _mapLightLevel(double lux) {
    if (lux < 5) return AmbientLightLevel.dark;
    if (lux < 50) return AmbientLightLevel.dim;
    if (lux < 250) return AmbientLightLevel.normal;
    return AmbientLightLevel.bright;
  }

  void dispose() {
    unawaited(stop());
    _controller.close();
  }
}
