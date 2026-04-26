import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ride_record.dart';
import '../../providers/ride_provider.dart';
import '../../providers/settings_provider.dart';
import 'history_detail_map_screen.dart';
import '../../widgets/record_badges.dart';
import '../../utils/format_utils.dart';

enum SortType {
  dateDesc,
  dateAsc,
  distanceDesc,
  distanceAsc,
  speedDesc,
  speedAsc,
}

class HistoryTotalScreen extends StatefulWidget {
  const HistoryTotalScreen({super.key});

  @override
  State<HistoryTotalScreen> createState() => _HistoryTotalScreenState();
}

class _HistoryTotalScreenState extends State<HistoryTotalScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int? _filterYear = DateTime.now().year;
  int? _filterMonth;
  int? _filterDay;

  final Set<int> _pendingDeleteIds = {};
  SortType _sortType = SortType.dateDesc;

  String get _sortLabel {
    switch (_sortType) {
      case SortType.dateDesc:
        return '날짜 최신순';
      case SortType.dateAsc:
        return '날짜 오래된순';
      case SortType.distanceDesc:
        return '거리 긴순';
      case SortType.distanceAsc:
        return '거리 짧은순';
      case SortType.speedDesc:
        return '속도 빠른순';
      case SortType.speedAsc:
        return '속도 느린순';
    }
  }

  List<RideRecord> _sortedRecords(List<RideRecord> records) {
    final sorted = List<RideRecord>.from(records);
    switch (_sortType) {
      case SortType.dateDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortType.dateAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortType.distanceDesc:
        sorted.sort((a, b) => b.totalDistance.compareTo(a.totalDistance));
        break;
      case SortType.distanceAsc:
        sorted.sort((a, b) => a.totalDistance.compareTo(b.totalDistance));
        break;
      case SortType.speedDesc:
        sorted.sort((a, b) => b.maxSpeed.compareTo(a.maxSpeed));
        break;
      case SortType.speedAsc:
        sorted.sort((a, b) => a.maxSpeed.compareTo(b.maxSpeed));
        break;
    }
    return sorted;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e1e1e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '정렬 기준',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...SortType.values.map((type) {
                final isSelected = _sortType == type;
                // 각 type 별 라벨
                String label;
                switch (type) {
                  case SortType.dateDesc:
                    label = '날짜 최신순';
                    break;
                  case SortType.dateAsc:
                    label = '날짜 오래된순';
                    break;
                  case SortType.distanceDesc:
                    label = '거리 긴순';
                    break;
                  case SortType.distanceAsc:
                    label = '거리 짧은순';
                    break;
                  case SortType.speedDesc:
                    label = '속도 빠른순';
                    break;
                  case SortType.speedAsc:
                    label = '속도 느린순';
                    break;
                }

                return ListTile(
                  onTap: () {
                    setState(() => _sortType = type);
                    Navigator.pop(ctx);
                  },
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  title: Text(
                    label, // _sortLabel 대신 label 사용
                    style: TextStyle(
                      color: isSelected ? Colors.blue : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  List<RideRecord> _filteredRecords(List<RideRecord> records) {
    return records.where((r) {
      if (_filterYear != null && r.year != _filterYear) return false;
      if (_filterMonth != null && r.month != _filterMonth) return false;
      if (_filterDay != null && r.day != _filterDay) return false;
      return true;
    }).toList();
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e1e),
        title: const Text('정말 삭제할까요?', style: TextStyle(color: Colors.white)),
        content: Text(
          '${_pendingDeleteIds.length}개의 기록을 삭제합니다.\n되돌릴 수 없어요.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (final id in _pendingDeleteIds) {
                await context.read<RideProvider>().deleteRecord(id);
              }
              setState(() => _pendingDeleteIds.clear());
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _filterBox({
    required String label,
    required int? value,
    required List<int> items,
    required void Function(int?)? onChanged,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: value != null
              ? Colors.blue.withOpacity(0.15)
              : Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value != null
                ? Colors.blue.withOpacity(0.5)
                : Colors.grey[700]!,
          ),
        ),
        child: DropdownButton<int?>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: const Color(0xFF2a2a2a),
          menuMaxHeight: 200,
          hint: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                '$label 전체',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ...items.map(
              (item) =>
                  DropdownMenuItem<int?>(value: item, child: Text('$item')),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final records = context.watch<RideProvider>().records;
    final useKmh = context.watch<SettingsProvider>().useKmh;
    final filtered = _sortedRecords(_filteredRecords(records));

    final years = records.map((r) => r.year).toSet().toList()..sort();
    final months = List.generate(12, (i) => i + 1);
    final days = List.generate(31, (i) => i + 1);

    return Stack(
      children: [
        Column(
          children: [
            // 필터 영역
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _filterBox(
                    label: '년',
                    value: years.contains(_filterYear) ? _filterYear : null,
                    items: years,
                    onChanged: (v) => setState(() {
                      _filterYear = v;
                      if (v == null) {
                        _filterMonth = null;
                        _filterDay = null;
                      }
                    }),
                  ),
                  const SizedBox(width: 6),
                  _filterBox(
                    label: '월',
                    value: _filterMonth,
                    items: months,
                    onChanged: _filterYear == null
                        ? null
                        : (v) => setState(() {
                            _filterMonth = v;
                            if (v == null) {
                              _filterDay = null;
                            }
                          }),
                  ),
                  const SizedBox(width: 6),
                  _filterBox(
                    label: '일',
                    value: _filterDay,
                    items: days,
                    onChanged: _filterMonth == null
                        ? null
                        : (v) => setState(() => _filterDay = v),
                  ),
                  const SizedBox(width: 6),
                  // 초기화 버튼 (항상 표시)
                  GestureDetector(
                    onTap: () => setState(() {
                      _filterYear = null;
                      _filterMonth = null;
                      _filterDay = null;
                    }),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            _filterYear != null ||
                                _filterMonth != null ||
                                _filterDay != null
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.refresh,
                        color:
                            _filterYear != null ||
                                _filterMonth != null ||
                                _filterDay != null
                            ? Colors.blue
                            : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 총 개수
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '총 ${filtered.length}개',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  // 정렬 버튼
                  GestureDetector(
                    onTap: _showSortOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sort, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _sortLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 목록
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        '해당 조건의 기록이 없어요',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        _pendingDeleteIds.isEmpty ? 16 : 80,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final record = filtered[index];
                        final bestIds = context.read<RideProvider>().bestRecordIds;
                        final isPending =
                            record.id != null &&
                            _pendingDeleteIds.contains(record.id);
                        final time = DateTime.fromMillisecondsSinceEpoch(
                          record.createdAt,
                        );
                        final timeStr =
                            '${time.hour.toString().padLeft(2, '0')}:'
                            '${time.minute.toString().padLeft(2, '0')}';

                        return Stack(
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isPending ? 0.35 : 1.0,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.fromLTRB(16, 16, 40, 16),
                                decoration: BoxDecoration(
                                  color: isPending
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.grey[900],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isPending
                                        ? Colors.red.withOpacity(0.5)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${record.year}년 ${record.month}월 ${record.day}일  $timeStr 출발',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => HistoryDetailMapScreen(
                                                  record: record,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Row(
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
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _statItem(
                                          '거리',
                                          '${convertDistance(record.totalDistance, useKmh).toStringAsFixed(2)} ${distanceUnit(useKmh)}',
                                        ),
                                        _statItem(
                                          '시간',
                                          formatDuration(record.duration),
                                        ),
                                        _statItem(
                                          '최고속도',
                                          '${convertSpeed(record.maxSpeed, useKmh).toStringAsFixed(1)} ${speedUnit(useKmh)}',
                                        ),
                                        _statItem(
                                          '평균속도',
                                          '${convertSpeed(record.avgSpeed, useKmh).toStringAsFixed(1)} ${speedUnit(useKmh)}',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 삭제 버튼
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  if (record.id == null) return;
                                  setState(() {
                                    if (isPending) {
                                      _pendingDeleteIds.remove(record.id);
                                    } else {
                                      _pendingDeleteIds.add(record.id!);
                                    }
                                  });
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isPending
                                        ? Colors.blue
                                        : Colors.red.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPending ? Icons.add : Icons.remove,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),

        // 삭제/취소 버튼 (하단 고정)
        if (_pendingDeleteIds.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.black,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _pendingDeleteIds.clear()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '취소',
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _confirmDelete(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_pendingDeleteIds.length}개 삭제',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
            ),
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
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
