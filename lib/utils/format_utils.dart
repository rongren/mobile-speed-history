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

// 칼로리 추정: 거리(km) × 체중(kg) × 0.5 kcal — 체중 null이면 null 반환
int? calcCalories(double distanceKm, double? weightKg) {
  if (weightKg == null) return null;
  return (distanceKm * weightKg * 0.5).round();
}

// 1000단위 콤마 포맷 (예: 1234 → "1,234")
String formatNumber(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}${buf.toString()}';
}

// 소수점 포함 1000단위 콤마 포맷 (예: 1234.5 → "1,234.5")
String formatDouble(double value, int decimals) {
  final fixed = value.toStringAsFixed(decimals);
  final dotIdx = fixed.indexOf('.');
  final intStr = dotIdx >= 0 ? fixed.substring(0, dotIdx) : fixed;
  final decStr = dotIdx >= 0 ? fixed.substring(dotIdx) : '';
  final isNeg = intStr.startsWith('-');
  final digits = isNeg ? intStr.substring(1) : intStr;
  final buf = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${isNeg ? '-' : ''}${buf.toString()}$decStr';
}

// 단위 변환 + 콤마 포맷 (거리)
String formatDistance(double km, bool useKmh, {int decimals = 2}) =>
    formatDouble(convertDistance(km, useKmh), decimals);

// 단위 변환 + 콤마 포맷 (속도)
String formatSpeed(double kmh, bool useKmh, {int decimals = 1}) =>
    formatDouble(convertSpeed(kmh, useKmh), decimals);
