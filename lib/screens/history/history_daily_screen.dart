import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/ride_record.dart';
import '../../providers/ride_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/bar_chart_widget.dart';
import '../../widgets/record_badges.dart';
import 'history_detail_map_screen.dart';
import '../../utils/format_utils.dart';

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
      final totalDist = list.fold(0.0, (s, r) => s + r.totalDistance);
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

  Widget _recentButton(String label, int days, bool isDark) {
    final isSelected = _recentDays == days;
    return GestureDetector(
      onTap: () => setState(() {
        _recentDays = isSelected ? null : days;
        _selectedIndex = -1;
      }),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withOpacity(0.2)
              : (isDark ? Colors.grey[850]! : Colors.grey[200]!),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.orange
                : (isDark ? Colors.grey[700]! : Colors.grey[400]!),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.orange
                : (isDark ? Colors.grey : Colors.grey[600]!),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final weightKg = settings.weightKg;
    final isDark = settings.appTheme == 'dark';

    final cardColor = isDark ? const Color(0xFF1e1e1e) : Colors.white;
    final panelColor = isDark ? Colors.grey[950]! : const Color(0xFFEEF0F3);
    final textColor = isDark ? Colors.white : Colors.black87;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    final Map<String, List<RideRecord>> grouped = {};
    for (final r in records) {
      final key =
          '${r.year}-${r.month.toString().padLeft(2, '0')}-${r.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(r);
    }

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
          DateTime.now().subtract(Duration(days: _recentDays!)));
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
        : grouped[k]!.map((r) => r.maxSpeed).reduce((a, b) => a > b ? a : b)).toList();
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

    final totalDistance = selectedRecords.fold(0.0, (s, r) => s + r.totalDistance);
    final totalDuration = selectedRecords.fold(0, (s, r) => s + r.duration);
    final maxSpeed = selectedRecords.isEmpty
        ? 0.0
        : selectedRecords.map((r) => r.maxSpeed).reduce((a, b) => a > b ? a : b);
    final avgSpeed = selectedRecords.isEmpty
        ? 0.0
        : selectedRecords.fold(0.0, (s, r) => s + r.avgSpeed) / selectedRecords.length;

    return Column(
      children: [
        // 기간 필터
        Container(
          color: panelColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(child: _recentButton('7일', 7, isDark)),
              const SizedBox(width: 6),
              Expanded(child: _recentButton('30일', 30, isDark)),
              const SizedBox(width: 6),
              Expanded(child: _recentButton('90일', 90, isDark)),
              const SizedBox(width: 6),
              Expanded(child: _recentButton('180일', 180, isDark)),
              const SizedBox(width: 6),
              Expanded(child: _recentButton('365일', 365, isDark)),
            ],
          ),
        ),

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
            useKmh: useKmh,
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

        Container(height: 1, color: dividerColor),

        // 요일별 통계
        Container(
          color: panelColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _showWeekdayStats = !_showWeekdayStats),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final dayLabels = ['월', '화', '수', '목', '금', '토', '일'];
                    final stat = weekdayStats[i]!;
                    final avgDist = stat['avgDistance']!;
                    final count = stat['count']!.toInt();
                    final maxDist = weekdayStats.values
                        .map((s) => s['avgDistance']!)
                        .reduce((a, b) => a > b ? a : b);
                    final ratio = maxDist > 0 ? avgDist / maxDist : 0.0;
                    final isWeekend = i == 5 || i == 6;

                    return Column(
                      children: [
                        Container(
                          width: 28,
                          height: 60,
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            width: 28,
                            height: (60 * ratio).clamp(2.0, 60.0),
                            decoration: BoxDecoration(
                              color: isWeekend ? Colors.orange : Colors.blue,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          avgDist > 0
                              ? formatDistance(avgDist, useKmh, decimals: 1)
                              : '-',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dayLabels[i],
                          style: TextStyle(
                            color: isWeekend
                                ? Colors.orange
                                : (isDark ? Colors.grey : Colors.grey[600]!),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${count}회',
                          style: TextStyle(
                            color: isDark ? Colors.grey : Colors.grey[500]!,
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

        Container(height: 1, color: dividerColor),

        if (_selectedIndex < 0)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '막대를 탭하면 상세 정보를 볼 수 있어요',
              style: TextStyle(
                  color: isDark ? Colors.grey : Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),

        if (_selectedIndex >= 0)
          Expanded(
            child: selectedRecords.isEmpty
                ? Center(
              child: Text(
                '해당 날짜에 기록이 없어요',
                style: TextStyle(
                    color: isDark ? Colors.grey : Colors.grey[600],
                    fontSize: 14),
              ),
            )
                : SingleChildScrollView(
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

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem('총 거리',
                                '${formatDistance(totalDistance, useKmh)} ${distanceUnit(useKmh)}',
                                isBlue: true, textColor: textColor),
                            _statItem('총 시간',
                                formatDuration(totalDuration),
                                isBlue: true, textColor: textColor),
                            _statItem('최고속도',
                                '${formatSpeed(maxSpeed, useKmh)} ${speedUnit(useKmh)}',
                                isBlue: true, textColor: textColor),
                            if (weightKg != null)
                              _statItem('칼로리',
                                  '${formatNumber(calcCalories(totalDistance, weightKg)!)} kcal',
                                  isBlue: true, textColor: textColor)
                            else
                              _statItem('평균속도',
                                  '${formatSpeed(avgSpeed, useKmh)} ${speedUnit(useKmh)}',
                                  isBlue: true, textColor: textColor),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '총 ${formatNumber(selectedRecords.length)}회 주행',
                          style: const TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  ...selectedRecords.asMap().entries.map((e) {
                    final idx = e.key;
                    final record = e.value;
                    final time = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
                    final timeStr =
                        '${time.hour.toString().padLeft(2, '0')}:'
                        '${time.minute.toString().padLeft(2, '0')}';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HistoryDetailMapScreen(record: record),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${idx + 1}회차  $timeStr 출발',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Row(
                                  children: [
                                    Text('경로 보기',
                                        style: TextStyle(color: Colors.blue, fontSize: 12)),
                                    Icon(Icons.chevron_right, color: Colors.blue, size: 16),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            RecordBadges(recordId: record.id, bestIds: bestIds),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statItem('거리',
                                    '${formatDistance(record.totalDistance, useKmh)} ${distanceUnit(useKmh)}',
                                    textColor: textColor),
                                _statItem('시간',
                                    formatDuration(record.duration),
                                    textColor: textColor),
                                _statItem('최고속도',
                                    '${formatSpeed(record.maxSpeed, useKmh)} ${speedUnit(useKmh)}',
                                    textColor: textColor),
                                _statItem('평균속도',
                                    '${formatSpeed(record.avgSpeed, useKmh)} ${speedUnit(useKmh)}',
                                    textColor: textColor),
                              ],
                            ),
                            if (weightKg != null ||
                                (record.memo != null && record.memo!.isNotEmpty)) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (weightKg != null)
                                    Text(
                                      '🔥 ${formatNumber(calcCalories(record.totalDistance, weightKg)!)} kcal',
                                      style: const TextStyle(
                                          color: Colors.orange, fontSize: 12),
                                    ),
                                  if (weightKg != null &&
                                      record.memo != null &&
                                      record.memo!.isNotEmpty)
                                    const SizedBox(width: 12),
                                  if (record.memo != null && record.memo!.isNotEmpty)
                                    Expanded(
                                      child: Text(
                                        '📝 ${record.memo}',
                                        style: TextStyle(
                                            color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                                            fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ],
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

  Widget _statItem(String label, String value,
      {bool isBlue = false, required Color textColor}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: textColor,
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
