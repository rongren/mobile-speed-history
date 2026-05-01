import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ride_record.dart';
import '../../providers/ride_provider.dart';
import '../../providers/settings_provider.dart';
import 'history_detail_map_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/record_badges.dart';
import '../../utils/format_utils.dart';
import '../../utils/gpx_utils.dart';
import '../../widgets/memo_bottom_sheet.dart';
import '../../widgets/stat_item.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDateFromCalendar() async {
    final records = context.read<RideProvider>().records;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1e1e1e) : Colors.white;
    final dialogBg = isDark ? const Color(0xFF1e1e1e) : Colors.white;
    final dropdownBg = isDark ? const Color(0xFF2a2a2a) : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black87;

    final recordedDays = records
        .map((r) => DateTime(r.year, r.month, r.day))
        .toSet();
    final recordYears = records.map((r) => r.year).toSet().toList()..sort();
    if (recordYears.isEmpty) recordYears.add(DateTime.now().year);

    final firstDay = recordedDays.isEmpty
        ? DateTime(DateTime.now().year)
        : recordedDays.reduce((a, b) => a.isBefore(b) ? a : b);

    await showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        DateTime focusedDay = _selectedDate;

        return StatefulBuilder(
          builder: (context, setModalState) {
            void showYearMonthPicker() {
              int tempYear = focusedDay.year;
              int tempMonth = focusedDay.month;

              showDialog(
                context: ctx,
                builder: (dialogCtx) => StatefulBuilder(
                  builder: (dialogCtx, setDialogState) {
                    return AlertDialog(
                      backgroundColor: dialogBg,
                      title: Text(
                        '연도 / 월 선택',
                        style: TextStyle(color: textColor, fontSize: 15),
                      ),
                      content: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<int>(
                              value: tempYear,
                              isExpanded: true,
                              dropdownColor: dropdownBg,
                              style: TextStyle(color: textColor),
                              underline: const SizedBox(),
                              items: recordYears
                                  .map((y) => DropdownMenuItem(
                                        value: y,
                                        child: Text('$y년'),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => tempYear = v);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<int>(
                              value: tempMonth,
                              isExpanded: true,
                              dropdownColor: dropdownBg,
                              style: TextStyle(color: textColor),
                              underline: const SizedBox(),
                              items: List.generate(12, (i) => i + 1)
                                  .map((m) => DropdownMenuItem(
                                        value: m,
                                        child: Text('$m월'),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => tempMonth = v);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('취소',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              focusedDay = DateTime(tempYear, tempMonth, 1);
                            });
                            Navigator.pop(dialogCtx);
                          },
                          child: const Text('이동',
                              style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    );
                  },
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '날짜 선택',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TableCalendar(
                      locale: 'ko_KR',
                      firstDay: firstDay,
                      lastDay: DateTime.now(),
                      focusedDay: focusedDay,
                      sixWeekMonthsEnforced: true,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, _selectedDate),
                      onDaySelected: (selected, focused) {
                        setState(() => _selectedDate = selected);
                        Navigator.pop(ctx);
                      },
                      onPageChanged: (focused) {
                        setModalState(() => focusedDay = focused);
                      },
                      calendarBuilders: CalendarBuilders(
                        headerTitleBuilder: (context, day) {
                          return GestureDetector(
                            onTap: showYearMonthPicker,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${day.year}년 ${day.month}월',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: textColor,
                                  size: 22,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: TextStyle(color: textColor),
                        weekendTextStyle: TextStyle(color: textColor),
                        outsideTextStyle:
                            TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[400]),
                        selectedDecoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(color: textColor),
                        markerDecoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 1,
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
                        rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                            color: isDark ? Colors.grey : Colors.grey[600]!),
                        weekendStyle: TextStyle(
                            color: isDark ? Colors.grey : Colors.grey[600]!),
                      ),
                      eventLoader: (day) {
                        final key = DateTime(day.year, day.month, day.day);
                        return recordedDays.contains(key) ? [true] : [];
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSelectPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1e1e1e) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dropdownBg = isDark ? const Color(0xFF2a2a2a) : Colors.grey[100]!;
    final boxColor = isDark ? Colors.grey[900]! : Colors.grey[200]!;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    int tempYear = _selectedDate.year;
    int tempMonth = _selectedDate.month;
    int tempDay = _selectedDate.day;

    final records = context.read<RideProvider>().records;
    final years = records.map((r) => r.year).toSet().toList()..sort();
    if (years.isEmpty) years.add(DateTime.now().year);
    final months = List.generate(12, (i) => i + 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final daysInMonth = DateUtils.getDaysInMonth(tempYear, tempMonth);
            final days = List.generate(daysInMonth, (i) => i + 1);
            if (tempDay > daysInMonth) tempDay = daysInMonth;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '날짜 선택',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _selectBox(
                            value: tempYear,
                            items: years,
                            onChanged: (v) => setModalState(() => tempYear = v!),
                            format: (v) => '$v년',
                            boxColor: boxColor,
                            borderColor: borderColor,
                            dropdownBg: dropdownBg,
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _selectBox(
                            value: tempMonth,
                            items: months,
                            onChanged: (v) => setModalState(() => tempMonth = v!),
                            format: (v) => '$v월',
                            boxColor: boxColor,
                            borderColor: borderColor,
                            dropdownBg: dropdownBg,
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _selectBox(
                            value: tempDay,
                            items: days,
                            onChanged: (v) => setModalState(() => tempDay = v!),
                            format: (v) => '$v일',
                            boxColor: boxColor,
                            borderColor: borderColor,
                            dropdownBg: dropdownBg,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = DateTime(tempYear, tempMonth, tempDay);
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '확인',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _selectBox<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) format,
    required Color boxColor,
    required Color borderColor,
    required Color dropdownBg,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: dropdownBg,
        menuMaxHeight: 200,
        style: TextStyle(color: textColor, fontSize: 14),
        items: items.map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(format(item)),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final records = context.watch<RideProvider>().records;
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final weightKg = settings.weightKg;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? Colors.black : const Color(0xFFF2F4F7);
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final navBtnColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final navBtnDisabledColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey : Colors.grey[600]!;

    final dayRecords = records.where((r) =>
    r.year == _selectedDate.year &&
        r.month == _selectedDate.month &&
        r.day == _selectedDate.day,
    ).toList();

    final totalDistance = dayRecords.fold(0.0, (s, r) => s + r.totalDistance);
    final totalDuration = dayRecords.fold(0, (s, r) => s + r.duration);
    final maxSpeed = dayRecords.isEmpty
        ? 0.0
        : dayRecords.map((r) => r.maxSpeed).reduce((a, b) => a > b ? a : b);
    final avgSpeed = dayRecords.isEmpty
        ? 0.0
        : dayRecords.fold(0.0, (s, r) => s + r.avgSpeed) / dayRecords.length;

    final isToday = _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // 날짜 선택 영역
            Container(
              color: cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: navBtnColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.chevron_left, color: textColor, size: 20),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      '${_selectedDate.year}년 '
                          '${_selectedDate.month}월 '
                          '${_selectedDate.day}일',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  GestureDetector(
                    onTap: isToday
                        ? null
                        : () {
                      setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isToday ? navBtnDisabledColor : navBtnColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: isToday ? subTextColor : textColor,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  GestureDetector(
                    onTap: _showSelectPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: navBtnColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.list, color: textColor, size: 16),
                          const SizedBox(width: 4),
                          Text('선택', style: TextStyle(color: textColor, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  GestureDetector(
                    onTap: _pickDateFromCalendar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: navBtnColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: textColor, size: 16),
                          const SizedBox(width: 4),
                          Text('달력', style: TextStyle(color: textColor, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 하루 합계 요약
            if (dayRecords.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
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
                        StatItem(label: '총 거리', value: '${formatDistance(totalDistance, useKmh)} ${distanceUnit(useKmh)}', textColor: textColor, labelBlue: true),
                        StatItem(label: '총 시간', value: formatDuration(totalDuration), textColor: textColor, labelBlue: true),
                        StatItem(label: '최고속도', value: '${formatSpeed(maxSpeed, useKmh)} ${speedUnit(useKmh)}', textColor: textColor, labelBlue: true),
                        StatItem(label: '평균속도', value: '${formatSpeed(avgSpeed, useKmh)} ${speedUnit(useKmh)}', textColor: textColor, labelBlue: true),
                      ],
                    ),
                    if (weightKg != null) ...[
                      const SizedBox(height: 10),
                      Divider(color: Colors.blue.withOpacity(0.3), height: 1),
                      const SizedBox(height: 10),
                      StatItem(label: '총 칼로리', value: '${formatNumber(calcCalories(totalDistance, weightKg)!)} kcal', textColor: textColor, labelBlue: true),
                    ],
                  ],
                ),
              ),

            // 기록 목록
            Expanded(
              child: dayRecords.isEmpty
                  ? Center(
                child: Text(
                  '해당 날짜에 주행기록이 없어요',
                  style: TextStyle(color: subTextColor, fontSize: 16),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: dayRecords.length,
                itemBuilder: (context, index) {
                  final record = dayRecords[index];
                  final bestIds = context.read<RideProvider>().bestRecordIds;
                  final time = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
                  final timeStr =
                      '${time.hour.toString().padLeft(2, '0')}:'
                      '${time.minute.toString().padLeft(2, '0')}';

                  return GestureDetector(
                    onTap: () => _showRecordDetail(context, record, useKmh, weightKg, isDark),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$timeStr 출발',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          RecordBadges(recordId: record.id, bestIds: bestIds),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              StatItem(label: '거리', value: '${formatDistance(record.totalDistance, useKmh)} ${distanceUnit(useKmh)}', textColor: textColor),
                              StatItem(label: '시간', value: formatDuration(record.duration), textColor: textColor),
                              StatItem(label: '최고속도', value: '${formatSpeed(record.maxSpeed, useKmh)} ${speedUnit(useKmh)}', textColor: textColor),
                              StatItem(label: '평균속도', value: '${formatSpeed(record.avgSpeed, useKmh)} ${speedUnit(useKmh)}', textColor: textColor),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordDetail(BuildContext context, RideRecord record,
      bool useKmh, double? weightKg, bool isDark) {
    final ride = context.read<RideProvider>();
    final int? calories = calcCalories(record.totalDistance, weightKg);
    final ctrl = TextEditingController(text: record.memo ?? '');
    final time = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';

    final dialogBg = isDark ? const Color(0xFF1e1e1e) : Colors.white;
    final memoBoxColor = isDark ? Colors.grey[900]! : Colors.grey[100]!;
    final btnBg = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    bool isSharing = false;

    showDialog(
      context: context,
      builder: (ctx) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(viewInsets: EdgeInsets.zero),
        child: StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${record.year}년 ${record.month}월 ${record.day}일',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        Text('$timeStr 출발',
                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Colors.grey, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          StatDetailItem(label: '거리', value: formatDistance(record.totalDistance, useKmh), unit: distanceUnit(useKmh), textColor: textColor),
                          StatDetailItem(label: '시간', value: formatDuration(record.duration), textColor: textColor),
                          StatDetailItem(label: '최고속도', value: formatSpeed(record.maxSpeed, useKmh), unit: speedUnit(useKmh), textColor: textColor),
                          StatDetailItem(label: '평균속도', value: formatSpeed(record.avgSpeed, useKmh), unit: speedUnit(useKmh), textColor: textColor),
                        ],
                      ),
                      if (calories != null) ...[
                        const SizedBox(height: 10),
                        Divider(color: Colors.blue.withOpacity(0.3), height: 1),
                        const SizedBox(height: 10),
                        StatDetailItem(label: '칼로리', value: formatNumber(calories), unit: 'kcal', textColor: textColor),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    await showMemoBottomSheet(ctx, controller: ctrl);
                    if (ctx.mounted) {
                      if (record.id != null) {
                        await ride.updateMemo(record.id!, ctrl.text.trim());
                      }
                      setDialogState(() {});
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 60),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: memoBoxColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ctrl.text.isEmpty
                        ? Text('메모를 남겨보세요 (탭하여 입력)',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13))
                        : Text(ctrl.text,
                            style: TextStyle(color: textColor, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnBg,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => HistoryDetailMapScreen(record: record)),
                          );
                        },
                        icon: Icon(Icons.map_outlined, color: textColor, size: 18),
                        label: Text('경로 보기',
                            style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnBg,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSharing ? null : () async {
                          setDialogState(() => isSharing = true);
                          try {
                            await shareGpx(record);
                          } finally {
                            if (ctx.mounted) setDialogState(() => isSharing = false);
                          }
                        },
                        icon: isSharing
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: textColor))
                            : const Icon(Icons.route,
                                color: Colors.deepPurple, size: 18),
                        label: Text('GPX 공유',
                            style: TextStyle(
                                color: isSharing ? Colors.grey : textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

}
