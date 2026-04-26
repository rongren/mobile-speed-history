import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/format_utils.dart';

class HistoryAverageScreen extends StatelessWidget {
  const HistoryAverageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final records = context.watch<RideProvider>().records;
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final weightKg = settings.weightKg;

    if (records.isEmpty) {
      return const Center(
        child: Text('아직 주행기록이 없어요',
            style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    // 기본 통계
    final avgDistance =
        records.fold(0.0, (s, r) => s + r.totalDistance) / records.length;
    final avgDuration =
        records.fold(0, (s, r) => s + r.duration) ~/ records.length;
    final avgMaxSpeed =
        records.fold(0.0, (s, r) => s + r.maxSpeed) / records.length;
    final avgAvgSpeed =
        records.fold(0.0, (s, r) => s + r.avgSpeed) / records.length;
    final totalDist = records.fold(0.0, (s, r) => s + r.totalDistance);
    final totalDuration = records.fold(0, (s, r) => s + r.duration);
    final bestSpeed =
        records.map((r) => r.maxSpeed).reduce((a, b) => a > b ? a : b);

    // 칼로리
    final totalCalories = calcCalories(totalDist, weightKg);
    final avgCalories = calcCalories(avgDistance, weightKg);

    // 최근 30일
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recent = records.where((r) {
      final date = DateTime(r.year, r.month, r.day);
      return !date.isBefore(thirtyDaysAgo);
    }).toList();
    final recentAvgDist = recent.isEmpty
        ? null
        : recent.fold(0.0, (s, r) => s + r.totalDistance) / recent.length;
    final recentAvgSpeed = recent.isEmpty
        ? null
        : recent.fold(0.0, (s, r) => s + r.avgSpeed) / recent.length;

    // 평균 주행 간격
    int? avgIntervalDays;
    if (records.length >= 2) {
      final sorted = List.from(records)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      int totalGap = 0;
      for (int i = 1; i < sorted.length; i++) {
        final prev =
            DateTime.fromMillisecondsSinceEpoch(sorted[i - 1].createdAt);
        final curr =
            DateTime.fromMillisecondsSinceEpoch(sorted[i].createdAt);
        totalGap += curr.difference(prev).inDays;
      }
      avgIntervalDays = totalGap ~/ (sorted.length - 1);
    }

    // 요일별 평균 거리
    final weekdayTotals = List.filled(7, 0.0);
    final weekdayCounts = List.filled(7, 0);
    for (final r in records) {
      final wd = DateTime(r.year, r.month, r.day).weekday - 1; // 0=월..6=일
      weekdayTotals[wd] += r.totalDistance;
      weekdayCounts[wd]++;
    }
    final weekdayAvgs = List.generate(
        7, (i) => weekdayCounts[i] > 0 ? weekdayTotals[i] / weekdayCounts[i] : 0.0);
    final maxWeekdayAvg = weekdayAvgs.reduce((a, b) => a > b ? a : b);
    final weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final bestDayIdx = weekdayCounts.every((c) => c == 0)
        ? -1
        : weekdayAvgs.indexOf(weekdayAvgs.reduce((a, b) => a > b ? a : b));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 전체 누적 헤더 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('전체 누적',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _bigStat('총 횟수', '${formatNumber(records.length)}회',
                        Icons.directions_bike),
                    _vDivider(),
                    _bigStat(
                        '총 거리',
                        '${formatDistance(totalDist, useKmh, decimals: 1)} ${distanceUnit(useKmh)}',
                        Icons.straighten),
                    _vDivider(),
                    _bigStat('총 시간', formatDuration(totalDuration), Icons.timer),
                  ],
                ),
                if (totalCalories != null) ...[
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _bigStat('총 칼로리',
                          '${formatNumber(totalCalories)} kcal',
                          Icons.local_fire_department),
                      _vDivider(),
                      _bigStat(
                          '최고 속도',
                          '${formatSpeed(bestSpeed, useKmh)} ${speedUnit(useKmh)}',
                          Icons.speed),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 14),
                  _bigStat(
                      '최고 속도',
                      '${formatSpeed(bestSpeed, useKmh)} ${speedUnit(useKmh)}',
                      Icons.speed),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          _sectionLabel('1회 평균'),
          const SizedBox(height: 10),

          // ── 평균 2×2 그리드
          Row(
            children: [
              Expanded(
                child: _avgCard('거리',
                    '${formatDistance(avgDistance, useKmh)}',
                    distanceUnit(useKmh), Icons.straighten, Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _avgCard('시간', formatDuration(avgDuration), '',
                    Icons.timer, Colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _avgCard(
                    '최고속도',
                    '${formatSpeed(avgMaxSpeed, useKmh)}',
                    speedUnit(useKmh),
                    Icons.speed,
                    Colors.orange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _avgCard(
                    '평균속도',
                    '${formatSpeed(avgAvgSpeed, useKmh)}',
                    speedUnit(useKmh),
                    Icons.trending_up,
                    Colors.purple),
              ),
            ],
          ),
          if (avgCalories != null) ...[
            const SizedBox(height: 10),
            _statTile('1회 평균 칼로리', '${formatNumber(avgCalories)} kcal',
                icon: Icons.local_fire_department,
                iconColor: Colors.deepOrange),
          ],

          const SizedBox(height: 24),
          _sectionLabel('최근 30일'),
          const SizedBox(height: 10),

          recent.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('최근 30일 기록 없음',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center),
                )
              : Row(
                  children: [
                    Expanded(
                      child: _compareCard(
                        '평균 거리',
                        '${formatDistance(recentAvgDist!, useKmh)} ${distanceUnit(useKmh)}',
                        '전체 ${formatDistance(avgDistance, useKmh)}',
                        recentAvgDist > avgDistance,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _compareCard(
                        '평균 속도',
                        '${formatSpeed(recentAvgSpeed!, useKmh)} ${speedUnit(useKmh)}',
                        '전체 ${formatSpeed(avgAvgSpeed, useKmh)}',
                        recentAvgSpeed > avgAvgSpeed,
                      ),
                    ),
                  ],
                ),

          const SizedBox(height: 24),
          _sectionLabel('주행 패턴'),
          const SizedBox(height: 10),

          Row(
            children: [
              if (avgIntervalDays != null)
                Expanded(
                  child: _statTile(
                    '평균 주행 간격',
                    avgIntervalDays == 0 ? '매일' : '$avgIntervalDays일에 1번',
                    icon: Icons.calendar_today,
                    iconColor: Colors.cyan,
                  ),
                ),
              if (avgIntervalDays != null && bestDayIdx >= 0)
                const SizedBox(width: 10),
              if (bestDayIdx >= 0)
                Expanded(
                  child: _statTile(
                    '가장 많이 탄 요일',
                    weekdayNames[bestDayIdx],
                    icon: Icons.star,
                    iconColor: Colors.amber,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // ── 요일별 막대
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('요일별 평균 거리',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final ratio = maxWeekdayAvg > 0
                        ? weekdayAvgs[i] / maxWeekdayAvg
                        : 0.0;
                    final isMax = i == bestDayIdx && weekdayCounts[i] > 0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          children: [
                            weekdayCounts[i] > 0
                                ? Text(
                                    formatDistance(weekdayAvgs[i], useKmh, decimals: 1),
                                    style: TextStyle(
                                      color: isMax
                                          ? Colors.blue
                                          : Colors.grey[600],
                                      fontSize: 9,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : const SizedBox(height: 13),
                            const SizedBox(height: 3),
                            Container(
                              height: 60 * ratio +
                                  (weekdayCounts[i] > 0 ? 4 : 0),
                              decoration: BoxDecoration(
                                color: isMax
                                    ? Colors.blue
                                    : weekdayCounts[i] > 0
                                        ? Colors.grey[700]
                                        : Colors.grey[850],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              weekdayNames[i],
                              style: TextStyle(
                                color: isMax ? Colors.blue : Colors.grey,
                                fontSize: 12,
                                fontWeight: isMax
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold));
  }

  Widget _bigStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 18),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 48, color: Colors.white24);

  Widget _avgCard(String label, String value, String unit, IconData icon,
      Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(unit, style: TextStyle(color: color, fontSize: 11)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _compareCard(
      String label, String recentVal, String overallVal, bool isUp) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isUp ? Icons.arrow_upward : Icons.arrow_downward,
                color: isUp ? Colors.green : Colors.red,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(recentVal,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(overallVal,
              style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value,
      {IconData? icon, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? Colors.grey, size: 16),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
