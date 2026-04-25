import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/ride_record.dart';
import '../../providers/ride_provider.dart';
import '../../widgets/bar_chart_widget.dart';
import '../../utils/format_utils.dart';

class HistoryMonthlyScreen extends StatefulWidget {
  const HistoryMonthlyScreen({super.key});

  @override
  State<HistoryMonthlyScreen> createState() => _HistoryMonthlyScreenState();
}

class _HistoryMonthlyScreenState extends State<HistoryMonthlyScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  int _selectedIndex = -1;
  bool _showHeatmap = true;

  // 히트맵 색상 계산
  Color _heatmapColor(double value, double maxValue) {
    if (value <= 0) return Colors.grey[850]!;
    final ratio = (value / maxValue).clamp(0.0, 1.0);
    return Color.lerp(
      Colors.blue.withOpacity(0.2),
      Colors.blue,
      ratio,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final records = context.watch<RideProvider>().records;

    final Map<String, List<RideRecord>> grouped = {};
    for (final r in records) {
      final key =
          '${r.year}-${r.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(r);
    }
    final keys = grouped.keys.toList()..sort();

    final labels = keys.map((k) {
      final parts = k.split('-');
      return '${parts[0]}\n${int.parse(parts[1])}월';
    }).toList();

    final distanceData = keys.map((k) =>
        grouped[k]!.fold(0.0, (s, r) => s + r.totalDistance)).toList();
    final durationData = keys.map((k) =>
        grouped[k]!.fold(0.0, (s, r) => s + r.duration)).toList();
    final maxSpeedData = keys.map((k) =>
        grouped[k]!.map((r) => r.maxSpeed)
            .reduce((a, b) => a > b ? a : b)).toList();
    final avgSpeedData = keys.map((k) {
      final list = grouped[k]!;
      return list.fold(0.0, (s, r) => s + r.avgSpeed) / list.length;
    }).toList();

    List<RideRecord> selectedRecords = [];
    String selectedLabel = '';
    int selectedYear = 0;
    int selectedMonth = 0;

    if (_selectedIndex >= 0 && _selectedIndex < keys.length) {
      selectedRecords = grouped[keys[_selectedIndex]] ?? [];
      final parts = keys[_selectedIndex].split('-');
      selectedYear = int.parse(parts[0]);
      selectedMonth = int.parse(parts[1]);
      selectedLabel = '${selectedYear}년 ${selectedMonth}월';
    }

    final totalDistance = selectedRecords.fold(
        0.0, (s, r) => s + r.totalDistance);
    final totalDuration = selectedRecords.fold(
        0, (s, r) => s + r.duration);
    final maxSpeed = selectedRecords.isEmpty ? 0.0
        : selectedRecords.map((r) => r.maxSpeed)
        .reduce((a, b) => a > b ? a : b);
    final avgSpeed = selectedRecords.isEmpty ? 0.0
        : selectedRecords.fold(0.0, (s, r) => s + r.avgSpeed) /
        selectedRecords.length;

    // 히트맵 데이터 — 일별 거리
    Map<int, double> dailyDistance = {};
    if (selectedYear > 0) {
      for (final r in selectedRecords) {
        dailyDistance[r.day] =
            (dailyDistance[r.day] ?? 0) + r.totalDistance;
      }
    }
    final maxDailyDist = dailyDistance.values.isEmpty
        ? 1.0
        : dailyDistance.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // 그래프
        SizedBox(
          height: 300,
          child: BarChartWidget(
            labels: labels,
            distanceData: distanceData,
            durationData: durationData,
            maxSpeedData: maxSpeedData,
            avgSpeedData: avgSpeedData,
            selectedIndex: _selectedIndex,
            onBarTap: (index) {
              SystemSound.play(SystemSoundType.click);
              setState(() {
                if (_selectedIndex == index) {
                  _selectedIndex = -1;
                } else {
                  _selectedIndex = index;
                  _showHeatmap = true;
                }
              });
            },
          ),
        ),

        Container(height: 1, color: Colors.grey[800]),

        if (_selectedIndex < 0)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '막대를 탭하면 상세 정보를 볼 수 있어요',
              style: TextStyle(
                  color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),

        if (_selectedIndex >= 0)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedLabel,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 요약 카드
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.blue
                              .withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceAround,
                          children: [
                            _statItem('총 거리',
                                '${totalDistance.toStringAsFixed(2)} km',
                                isBlue: true),
                            _statItem('총 시간',
                                formatDuration(
                                    totalDuration),
                                isBlue: true),
                            _statItem('최고속도',
                                '${maxSpeed.toStringAsFixed(1)} km/h',
                                isBlue: true),
                            _statItem('평균속도',
                                '${avgSpeed.toStringAsFixed(1)} km/h',
                                isBlue: true),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '총 ${selectedRecords.length}회 주행',
                          style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 히트맵
                  Container(
                    color: Colors.grey[950],
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() =>
                          _showHeatmap =
                          !_showHeatmap),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                            children: [
                              const Text(
                                '일별 거리 히트맵',
                                style: TextStyle(
                                  color: Colors
                                      .orange,
                                  fontSize: 13,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                              Icon(
                                _showHeatmap
                                    ? Icons
                                    .keyboard_arrow_up
                                    : Icons
                                    .keyboard_arrow_down,
                                color: Colors
                                    .orange,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        if (_showHeatmap) ...[
                          const SizedBox(height: 12),
                          // 요일 헤더
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceAround,
                            children: ['월', '화', '수', '목', '금', '토', '일']
                                .map((d) => SizedBox(
                              width: 36,
                              child: Text(
                                d,
                                textAlign:
                                TextAlign
                                    .center,
                                style: TextStyle(
                                  color: d == '토' || d == '일'
                                      ? Colors.orange
                                      : Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ))
                                .toList(),
                          ),
                          const SizedBox(height: 6),
                          // 달력 그리기
                          _buildHeatmapCalendar(
                            selectedYear,
                            selectedMonth,
                            dailyDistance,
                            maxDailyDist,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 주차별 breakdown
                  _buildWeeklyBreakdown(
                    selectedYear,
                    selectedMonth,
                    selectedRecords,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Map<int, Map<String, double>> _getWeeklyStats(
      int year, int month, List<RideRecord> records) {
    final Map<int, List<RideRecord>> weekGroups = {};

    for (final r in records) {
      final day = r.day;
      final week = ((day - 1) / 7).floor() + 1;  // 1~5주차
      weekGroups.putIfAbsent(week, () => []).add(r);
    }

    final Map<int, Map<String, double>> result = {};
    for (int w = 1; w <= 5; w++) {
      final list = weekGroups[w] ?? [];
      result[w] = {
        'distance': list.fold(0.0, (s, r) => s + r.totalDistance),
        'duration': list.fold(0.0, (s, r) => s + r.duration),
        'maxSpeed': list.isEmpty ? 0.0
            : list.map((r) => r.maxSpeed)
            .reduce((a, b) => a > b ? a : b),
        'avgSpeed': list.isEmpty ? 0.0
            : list.fold(0.0, (s, r) => s + r.avgSpeed) / list.length,
        'count': list.length.toDouble(),
      };
    }
    return result;
  }

  Widget _buildWeeklyBreakdown(
      int year, int month, List<RideRecord> records) {
    if (records.isEmpty) return const SizedBox();

    final weeklyStats = _getWeeklyStats(year, month, records);

    // 실제 데이터 있는 주차만
    final activeWeeks = weeklyStats.entries
        .where((e) => e.value['count']! > 0)
        .toList();

    if (activeWeeks.isEmpty) return const SizedBox();

    return Container(
      color: Colors.grey[950],
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '주차별 통계',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...activeWeeks.map((e) {
            final week = e.key;
            final stat = e.value;
            final count = stat['count']!.toInt();
            final distance = stat['distance']!;
            final duration = stat['duration']!.toInt();
            final maxSpeed = stat['maxSpeed']!;
            final avgSpeed = stat['avgSpeed']!;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1e1e1e),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$week주차',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$count회 주행',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('거리',
                          '${distance.toStringAsFixed(2)} km'),
                      _statItem('시간',
                          formatDuration(duration)),
                      _statItem('최고속도',
                          '${maxSpeed.toStringAsFixed(1)} km/h'),
                      _statItem('평균속도',
                          '${avgSpeed.toStringAsFixed(1)} km/h'),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeatmapCalendar(
      int year,
      int month,
      Map<int, double> dailyDistance,
      double maxDist,
      ) {
    final firstDay = DateTime(year, month, 1);
    // 월요일 = 0 기준으로 첫째날 오프셋
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final day = cellIndex - startOffset + 1;

            if (day < 1 || day > daysInMonth) {
              return const SizedBox(width: 36, height: 36);
            }

            final dist = dailyDistance[day] ?? 0.0;
            final color = _heatmapColor(dist, maxDist);
            final isToday = DateTime.now().year == year &&
                DateTime.now().month == month &&
                DateTime.now().day == day;

            return Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: isToday
                    ? Border.all(
                    color: Colors.orange, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      color: dist > 0
                          ? Colors.white
                          : Colors.grey[600],
                      fontSize: 11,
                      fontWeight: dist > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (dist > 0)
                    Text(
                      '${dist.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                      ),
                    ),
                ],
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _statItem(String label, String value, {bool isBlue = false}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isBlue ? Colors.blue : Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}