import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/ride_record.dart';
import '../../providers/ride_provider.dart';
import '../../widgets/bar_chart_widget.dart';
import '../../widgets/record_badges.dart';
import 'history_detail_map_screen.dart';

class HistoryDailyScreen extends StatefulWidget {
  const HistoryDailyScreen({super.key});

  @override
  State<HistoryDailyScreen> createState() => _HistoryDailyScreenState();
}

class _HistoryDailyScreenState extends State<HistoryDailyScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  int _selectedIndex = -1;
  int? _recentDays;
  bool _showWeekdayStats = true;

  String _formatDuration(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  Map<int, Map<String, double>> _getWeekdayStats(
      Map<String, List<RideRecord>> grouped) {
    final Map<int, List<double>> weekdayDistances = {};

    for (final key in grouped.keys) {
      final list = grouped[key]!;
      if (list.isEmpty) continue;

      final parts = key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final weekday = date.weekday - 1;
      final totalDist =
      list.fold(0.0, (s, r) => s + r.totalDistance);
      weekdayDistances.putIfAbsent(weekday, () => []).add(totalDist);
    }

    final Map<int, Map<String, double>> result = {};
    for (int i = 0; i < 7; i++) {
      final distances = weekdayDistances[i] ?? [];
      result[i] = {
        'avgDistance': distances.isEmpty
            ? 0.0
            : distances.reduce((a, b) => a + b) / distances.length,
        'count': distances.length.toDouble(),
      };
    }
    return result;
  }

  Widget _recentButton(String label, int? days) {
    final isSelected = _recentDays == days;
    return GestureDetector(
      onTap: () => setState(() {
        _recentDays = days;
        _selectedIndex = -1;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withOpacity(0.2)
              : Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.orange
                : Colors.grey[700]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.orange : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final records = context.watch<RideProvider>().records;
    final bestIds = context.read<RideProvider>().bestRecordIds;

    final Map<String, List<RideRecord>> grouped = {};
    for (final r in records) {
      final key =
          '${r.year}-${r.month.toString().padLeft(2, '0')}-${r.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(r);
    }

    // 빈 날짜 채우기
    if (grouped.isNotEmpty) {
      final allKeys = grouped.keys.toList()..sort();
      final firstDate = DateTime.parse(allKeys.first);
      final today = DateTime.now();
      DateTime cur = firstDate;

      while (!cur.isAfter(today)) {
        final key =
            '${cur.year}-${cur.month.toString().padLeft(2, '0')}-${cur.day.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(key, () => []);
        cur = cur.add(const Duration(days: 1));
      }
    }

    final weekdayStats = _getWeekdayStats(grouped);
    final allKeys = grouped.keys.toList()..sort();

    // 최근 N일 필터
    final filteredKeys = _recentDays == null
        ? allKeys
        : allKeys.where((k) {
      final parts = k.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return date.isAfter(
          DateTime.now()
              .subtract(Duration(days: _recentDays!)));
    }).toList();

    final labels = filteredKeys.map((k) {
      final parts = k.split('-');
      return '${int.parse(parts[1])}.${int.parse(parts[2])}';
    }).toList();

    final distanceData = filteredKeys.map((k) =>
        grouped[k]!.fold(0.0, (s, r) => s + r.totalDistance)).toList();
    final durationData = filteredKeys.map((k) =>
        grouped[k]!.fold(0.0, (s, r) => s + r.duration)).toList();
    final maxSpeedData = filteredKeys.map((k) =>
    grouped[k]!.isEmpty
        ? 0.0
        : grouped[k]!.map((r) => r.maxSpeed)
        .reduce((a, b) => a > b ? a : b)).toList();
    final avgSpeedData = filteredKeys.map((k) =>
    grouped[k]!.isEmpty
        ? 0.0
        : grouped[k]!.fold(0.0, (s, r) => s + r.avgSpeed) /
        grouped[k]!.length).toList();

    List<RideRecord> selectedRecords = [];
    String selectedLabel = '';
    if (_selectedIndex >= 0 && _selectedIndex < filteredKeys.length) {
      selectedRecords = grouped[filteredKeys[_selectedIndex]] ?? [];
      final parts = filteredKeys[_selectedIndex].split('-');
      selectedLabel =
      '${parts[0]}년 ${int.parse(parts[1])}월 ${int.parse(parts[2])}일';
    }

    final totalDistance = selectedRecords.fold(
        0.0, (s, r) => s + r.totalDistance);
    final totalDuration = selectedRecords.fold(
        0, (s, r) => s + r.duration);
    final maxSpeed = selectedRecords.isEmpty
        ? 0.0
        : selectedRecords.map((r) => r.maxSpeed)
        .reduce((a, b) => a > b ? a : b);
    final avgSpeed = selectedRecords.isEmpty
        ? 0.0
        : selectedRecords.fold(0.0, (s, r) => s + r.avgSpeed) /
        selectedRecords.length;

    return Column(
      children: [
        // 기간 필터
        Container(
          color: Colors.grey[950],
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                '기간',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              _recentButton('전체', null),
              const SizedBox(width: 6),
              _recentButton('7일', 7),
              const SizedBox(width: 6),
              _recentButton('30일', 30),
              const SizedBox(width: 6),
              _recentButton('90일', 90),
              const SizedBox(width: 6),
              _recentButton('180일', 180),
              const SizedBox(width: 6),
              _recentButton('365일', 365),
            ],
          ),
        ),

        // 그래프
        SizedBox(
          height: 300,
          child: BarChartWidget(
            key: ValueKey(_recentDays),
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
                }
              });
            },
          ),
        ),

        // 구분선
        Container(height: 1, color: Colors.grey[800]),

        // 요일별 통계
        Container(
          color: Colors.grey[950],
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() =>
                _showWeekdayStats = !_showWeekdayStats),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '요일별 평균 거리',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      _showWeekdayStats
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ],
                ),
              ),
              if (_showWeekdayStats) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final dayLabels = [
                      '월', '화', '수', '목', '금', '토', '일'
                    ];
                    final stat = weekdayStats[i]!;
                    final avgDist = stat['avgDistance']!;
                    final count = stat['count']!.toInt();
                    final maxDist = weekdayStats.values
                        .map((s) => s['avgDistance']!)
                        .reduce((a, b) => a > b ? a : b);
                    final ratio = maxDist > 0
                        ? avgDist / maxDist
                        : 0.0;
                    final isWeekend = i == 5 || i == 6;

                    return Column(
                      children: [
                        Container(
                          width: 28,
                          height: 60,
                          alignment:
                          Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 400),
                            curve: Curves.easeOut,
                            width: 28,
                            height: (60 * ratio)
                                .clamp(2.0, 60.0),
                            decoration:
                            BoxDecoration(
                              color: isWeekend
                                  ? Colors.orange
                                  : Colors.blue,
                              borderRadius:
                              const BorderRadius.only(
                                topLeft: Radius
                                    .circular(4),
                                topRight: Radius
                                    .circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          avgDist > 0
                              ? avgDist
                              .toStringAsFixed(1)
                              : '-',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dayLabels[i],
                          style: TextStyle(
                            color: isWeekend
                                ? Colors.orange
                                : Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${count}회',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ],
          ),
        ),

        // 구분선
        Container(height: 1, color: Colors.grey[800]),

        // 선택 안했을때 안내
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

        // 선택된 날짜 상세
        if (_selectedIndex >= 0)
          Expanded(
            child: selectedRecords.isEmpty
                ? const Center(
              child: Text(
                '해당 날짜에 기록이 없어요',
                style: TextStyle(
                    color: Colors.grey, fontSize: 14),
              ),
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
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

                  // 하루 요약
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue
                          .withOpacity(0.15),
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
                                _formatDuration(
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

                  // 회차별 목록
                  ...selectedRecords.asMap().entries
                      .map((e) {
                    final idx = e.key;
                    final record = e.value;
                    final time = DateTime
                        .fromMillisecondsSinceEpoch(
                        record.createdAt);
                    final timeStr =
                        '${time.hour.toString().padLeft(2, '0')}:'
                        '${time.minute.toString().padLeft(2, '0')}';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HistoryDetailMapScreen(
                                  record:
                                  record,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        margin:
                        const EdgeInsets.only(
                            bottom: 10),
                        padding:
                        const EdgeInsets.all(
                            14),
                        decoration: BoxDecoration(
                          color: const Color(
                              0xFF1e1e1e),
                          borderRadius:
                          BorderRadius
                              .circular(12),
                          border: Border.all(
                              color: Colors
                                  .grey[800]!),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                              children: [
                                Text(
                                  '${idx + 1}회차  $timeStr 출발',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Row(
                                  children: [
                                    Text(
                                      '경로 보기',
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 12),
                                    ),
                                    Icon(
                                        Icons.chevron_right,
                                        color: Colors.blue,
                                        size: 16),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            RecordBadges(
                              recordId: record.id,
                              bestIds: bestIds,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceAround,
                              children: [
                                _statItem(
                                    '거리',
                                    '${record.totalDistance.toStringAsFixed(2)} km'),
                                _statItem(
                                    '시간',
                                    _formatDuration(
                                        record.duration)),
                                _statItem(
                                    '최고속도',
                                    '${record.maxSpeed.toStringAsFixed(1)} km/h'),
                                _statItem(
                                    '평균속도',
                                    '${record.avgSpeed.toStringAsFixed(1)} km/h'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
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