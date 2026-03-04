String formatSeconds(int seconds) {
  final clamped = seconds < 0 ? 0 : seconds;
  final m = clamped ~/ 60;
  final s = clamped % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return '$mm:$ss';
}
