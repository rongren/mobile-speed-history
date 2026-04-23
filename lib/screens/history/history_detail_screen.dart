import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ride_record.dart';
import '../../providers/ride_provider.dart';
import 'history_detail_map_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/record_badges.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  DateTime _selectedDate = DateTime.now();
  List<RideRecord> _dayRecords = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDayRecords();
    });
  }

  void _loadDayRecords() {
    final records = context.read<RideProvider>().records;
    final filtered = records.where((r) =>
    r.year == _selectedDate.year &&
        r.month == _selectedDate.month &&
        r.day == _selectedDate.day,
    ).toList();

    // setState 없이 그냥 반환값만 사용
    _dayRecords = filtered;
  }

  Future<void> _pickDateFromCalendar() async {
    final records = context.read<RideProvider>().records;

    // 기록 있는 날짜 Set
    final recordedDays = records.map((r) =>
        DateTime(r.year, r.month, r.day)).toSet();

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e1e1e),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(16)),
      ),
      builder: (ctx) {
        DateTime focusedDay = _selectedDate;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '날짜 선택',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TableCalendar(
                      locale: 'ko_KR',
                      firstDay: DateTime(2020),
                      lastDay: DateTime.now(),
                      focusedDay: focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, _selectedDate),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDate = selected;
                        });
                        _loadDayRecords();
                        Navigator.pop(ctx);
                      },
                      onPageChanged: (focused) {
                        setModalState(() {
                          focusedDay = focused;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        // 기본 날짜
                        defaultTextStyle: const TextStyle(
                            color: Colors.white),
                        weekendTextStyle: const TextStyle(
                            color: Colors.white),
                        outsideTextStyle: TextStyle(
                            color: Colors.grey[700]),
                        // 선택된 날짜
                        selectedDecoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        // 오늘
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: const TextStyle(
                            color: Colors.white),
                        // 기록 있는 날 점 표시
                        markerDecoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 1,
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: Colors.white),
                        rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: Colors.white),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                            color: Colors.grey),
                        weekendStyle: TextStyle(
                            color: Colors.grey),
                      ),
                      // 기록 있는 날 마커 표시
                      eventLoader: (day) {
                        final key = DateTime(
                          day.year,
                          day.month,
                          day.day,
                        );
                        return recordedDays.contains(key)
                            ? [true]
                            : [];
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
    int tempYear = _selectedDate.year;
    int tempMonth = _selectedDate.month;
    int tempDay = _selectedDate.day;

    final years = List.generate(
        DateTime.now().year - 2019, (i) => 2020 + i);
    final months = List.generate(12, (i) => i + 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e1e1e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final daysInMonth = DateUtils.getDaysInMonth(
                tempYear, tempMonth);
            final days = List.generate(daysInMonth, (i) => i + 1);
            if (tempDay > daysInMonth) tempDay = daysInMonth;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '날짜 선택',
                      style: TextStyle(
                        color: Colors.white,
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
                            onChanged: (v) {
                              setModalState(() =>
                              tempYear = v!);
                            },
                            format: (v) => '$v년',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _selectBox(
                            value: tempMonth,
                            items: months,
                            onChanged: (v) {
                              setModalState(() =>
                              tempMonth = v!);
                            },
                            format: (v) => '$v월',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _selectBox(
                            value: tempDay,
                            items: days,
                            onChanged: (v) {
                              setModalState(() =>
                              tempDay = v!);
                            },
                            format: (v) => '$v일',
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
                            _selectedDate = DateTime(
                              tempYear,
                              tempMonth,
                              tempDay,
                            );
                          });
                          _loadDayRecords();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius:
                            BorderRadius.circular(12),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF2a2a2a),
        menuMaxHeight: 200,   // 추가
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: items.map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(format(item)),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  String _formatDuration(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // watch 로 변경 감지 후 필터링
    final records = context.watch<RideProvider>().records;
    _dayRecords = records.where((r) =>
    r.year == _selectedDate.year &&
        r.month == _selectedDate.month &&
        r.day == _selectedDate.day,
    ).toList();

    final totalDistance = _dayRecords.fold(
        0.0, (s, r) => s + r.totalDistance);
    final totalDuration = _dayRecords.fold(
        0, (s, r) => s + r.duration);
    final maxSpeed = _dayRecords.isEmpty
        ? 0.0
        : _dayRecords.map((r) => r.maxSpeed)
        .reduce((a, b) => a > b ? a : b);
    final avgSpeed = _dayRecords.isEmpty
        ? 0.0
        : _dayRecords.fold(0.0, (s, r) => s + r.avgSpeed) /
        _dayRecords.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: true,  // 하단 시스템 네비 영역 확보
        child: Column(
          children: [
            // 날짜 선택 영역
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // 이전 날짜
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = _selectedDate
                            .subtract(const Duration(days: 1));
                      });
                      _loadDayRecords();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 날짜 텍스트
                  Expanded(
                    child: Text(
                      '${_selectedDate.year}년 '
                          '${_selectedDate.month}월 '
                          '${_selectedDate.day}일',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 다음 날짜 (오늘 이후는 비활성화)
                  GestureDetector(
                    onTap: _selectedDate.day == DateTime.now().day &&
                        _selectedDate.month == DateTime.now().month &&
                        _selectedDate.year == DateTime.now().year
                        ? null
                        : () {
                      setState(() {
                        _selectedDate = _selectedDate
                            .add(const Duration(days: 1));
                      });
                      _loadDayRecords();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _selectedDate.day == DateTime.now().day &&
                            _selectedDate.month == DateTime.now().month &&
                            _selectedDate.year == DateTime.now().year
                            ? Colors.grey[850]
                            : Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: _selectedDate.day == DateTime.now().day &&
                            _selectedDate.month == DateTime.now().month &&
                            _selectedDate.year == DateTime.now().year
                            ? Colors.grey[700]
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 셀렉트 버튼
                  GestureDetector(
                    onTap: _showSelectPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.list,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('선택',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 달력 버튼
                  GestureDetector(
                    onTap: _pickDateFromCalendar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('달력',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 하루 합계 요약
            if (_dayRecords.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.blue.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem('총 거리',
                        '${totalDistance.toStringAsFixed(2)} km'),
                    _summaryItem('총 시간',
                        _formatDuration(totalDuration)),
                    _summaryItem('최고속도',
                        '${maxSpeed.toStringAsFixed(1)} km/h'),
                    _summaryItem('평균속도',
                        '${avgSpeed.toStringAsFixed(1)} km/h'),
                  ],
                ),
              ),

            // 기록 목록
            Expanded(
              child: _dayRecords.isEmpty
                  ? const Center(
                child: Text(
                  '해당 날짜에 주행기록이 없어요',
                  style: TextStyle(
                      color: Colors.grey, fontSize: 16),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                itemCount: _dayRecords.length,
                itemBuilder: (context, index) {
                  final record = _dayRecords[index];
                  final bestIds = context.read<RideProvider>().bestRecordIds;
                  final time =
                  DateTime.fromMillisecondsSinceEpoch(
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
                                record: record,
                              ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(
                          bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                            children: [
                              Text(
                                '$timeStr 출발',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                              const Row(
                                children: [
                                  Text(
                                    '경로 보기',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          RecordBadges(
                            recordId: record.id,
                            bestIds: bestIds,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceAround,
                            children: [
                              _statItem('거리',
                                  '${record.totalDistance.toStringAsFixed(2)} km'),
                              _statItem('시간',
                                  _formatDuration(record.duration)),
                              _statItem('최고속도',
                                  '${record.maxSpeed.toStringAsFixed(1)} km/h'),
                              _statItem('평균속도',
                                  '${record.avgSpeed.toStringAsFixed(1)} km/h'),
                            ],
                          ),
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

  Widget _summaryItem(String label, String value) {
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
          style: const TextStyle(
              color: Colors.blue, fontSize: 11),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value) {
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
          style: const TextStyle(
              color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }
}