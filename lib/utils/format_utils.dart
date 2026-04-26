String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  return '${h.toString().padLeft(2, '0')}:'
      '${m.toString().padLeft(2, '0')}:'
      '${s.toString().padLeft(2, '0')}';
}

double convertSpeed(double kmh, bool useKmh) =>
    useKmh ? kmh : kmh * 0.621371;

double convertDistance(double km, bool useKmh) =>
    useKmh ? km : km * 0.621371;

String speedUnit(bool useKmh) => useKmh ? 'km/h' : 'mph';

String distanceUnit(bool useKmh) => useKmh ? 'km' : 'mi';

// 칼로리 추정: 거리(km) × 체중(kg) × 0.5 kcal
int calcCalories(double distanceKm, double weightKg) =>
    (distanceKm * weightKg * 0.5).round();
