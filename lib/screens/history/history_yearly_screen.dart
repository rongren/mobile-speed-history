import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/ride_record.dart';
import '../../providers/ride_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/bar_chart_widget.dart';
import '../../utils/format_utils.dart';

class HistoryYearlyScreen extends StatefulWidget {
  const HistoryYearlyScreen({super.key});

  @override
  State<HistoryYearlyScreen> createState() => _HistoryYearlyScreenState();
}

class _HistoryYearlyScreenState extends State<HistoryYearlyScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  int _selectedIndex = -1;
  bool _showMonthlyBreakdown = true;

  Map<int, Map<String, double>> _getMonthlyStats(
      List<RideRecord> records) {
    final Map<int, List<RideRecord>> monthGroups = {};
    for (final r in records) {
      monthGroups.putIfAbsent(r.month, () => []).add(r);
    }

    final Map<int, Map<String, double>> result = {};
    for (int m = 1; m <= 12; m++) {
      final list = monthGroups[m] ?? [];
      result[m] = {
        'distance': list.fold(0.0, (s, r) => s + r.totalDistance),
        'duration': list.fold(0.0, (s, r) => s + r.duration),
        'maxSpeed': list.isEmpty ? 0.0
            : list.map((r) => r.maxSpeed)
            .reduce((a, b) => a > b ? a : b),
        'avgSpeed': list.isEmpty ? 0.0
            : list.fold(0.0, (s, r) => s + r.avgSpeed) /
            list.length,
        'count': list.length.toDouble(),
      };
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final records = context.watch<RideProvider>().records;
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final isDark = settings.appTheme == 'dark';

    final cardColor = isDark ? const Color(0xFF1e1e1e) : Colors.white;
    final panelColor = isDark ? Colors.grey[950]! : const Color(0xFFEEF0F3);
    final textColor = isDark ? Colors.white : Colors.black87;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    final Map<int, List<RideRecord>> grouped = {};
    for (final r in records) {
      grouped.putIfAbsent(r.year, () => []).add(r);
    }
    final years = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    final labels = years.map((y) => '$y년').toList();
    final distanceData = years.map((y) =>
        grouped[y]!.fold(0.0, (s, r) => s + r.totalDistance)).toList();
    final durationData = years.map((y) =>
        grouped[y]!.fold(0.0, (s, r) => s + r.duration)).toList();
    final maxSpeedData = years.map((y) =>
        grouped[y]!.map((r) => r.maxSpeed)
            .reduce((a, b) => a > b ? a : b)).toList();
    final avgSpeedData = years.map((y) {
      final list = grouped[y]!;
      return list.fold(0.0, (s, r) => s + r.avgSpeed) / list.length;
    }).toList();

    List<RideRecord> selectedRecords = [];
    int selectedYear = 0;
    if (_selectedIndex >= 0 && _selectedIndex < years.length) {
      selectedRecords = grouped[years[_selectedIndex]] ?? [];
      selectedYear = years[_selectedIndex];
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

    final monthlyStats = selectedYear > 0
        ? _getMonthlyStats(selectedRecords)
        : <int, Map<String, double>>{};

    final monthLabels = ['1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'];

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: BarChartWidget(
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
                  _showMonthlyBreakdown = true;
                }
              });
            },
          ),
        ),

        Container(height: 1, color: dividerColor),

        if (_selectedIndex < 0)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '막대를 탭하면 상세 정보를 볼 수 있어요',
              style: TextStyle(
                  color: isDark ? Colors.grey : Colors.grey[600],
                  fontSize: 14),
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
                    '$selectedYear년',
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
                            _statItem('평균속도',
                                '${formatSpeed(avgSpeed, useKmh)} ${speedUnit(useKmh)}',
                                isBlue: true, textColor: textColor),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '총 ${formatNumber(selectedRecords.length)}회 주행',
                          style: const TextStyle(
                              color: Colors.blue, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    color: panelColor,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() =>
                          _showMonthlyBreakdown = !_showMonthlyBreakdown),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '월별 통계',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                _showMonthlyBreakdown
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        if (_showMonthlyBreakdown) ...[
                          const SizedBox(height: 12),
                          ...List.generate(12, (i) {
                            final month = i + 1;
                            final stat = monthlyStats[month]!;
                            final count = stat['count']!.toInt();
                            if (count == 0) return const SizedBox();
                            final distance = stat['distance']!;
                            final duration = stat['duration']!.toInt();
                            final maxSpd = stat['maxSpeed']!;
                            final avgSpd = stat['avgSpeed']!;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        monthLabels[i],
                                        style: TextStyle(
                                          color: textColor,
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
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _statItem('거리',
                                          '${formatDistance(distance, useKmh)} ${distanceUnit(useKmh)}',
                                          textColor: textColor),
                                      _statItem('시간',
                                          formatDuration(duration),
                                          textColor: textColor),
                                      _statItem('최고속도',
                                          '${formatSpeed(maxSpd, useKmh)} ${speedUnit(useKmh)}',
                                          textColor: textColor),
                                      _statItem('평균속도',
                                          '${formatSpeed(avgSpd, useKmh)} ${speedUnit(useKmh)}',
                                          textColor: textColor),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
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
