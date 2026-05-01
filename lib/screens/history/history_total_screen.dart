import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ride_record.dart';
import '../../providers/ride_provider.dart';
import '../../providers/settings_provider.dart';
import 'history_detail_map_screen.dart';
import '../../widgets/record_badges.dart';
import '../../utils/format_utils.dart';
import '../../utils/gpx_utils.dart';
import '../../widgets/memo_bottom_sheet.dart';
import '../../widgets/stat_item.dart';

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
      case SortType.dateDesc: return '날짜 최신순';
      case SortType.dateAsc: return '날짜 오래된순';
      case SortType.distanceDesc: return '거리 긴순';
      case SortType.distanceAsc: return '거리 짧은순';
      case SortType.speedDesc: return '속도 빠른순';
      case SortType.speedAsc: return '속도 느린순';
    }
  }

  List<RideRecord> _sortedRecords(List<RideRecord> records) {
    final sorted = List<RideRecord>.from(records);
    switch (_sortType) {
      case SortType.dateDesc: sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt)); break;
      case SortType.dateAsc: sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt)); break;
      case SortType.distanceDesc: sorted.sort((a, b) => b.totalDistance.compareTo(a.totalDistance)); break;
      case SortType.distanceAsc: sorted.sort((a, b) => a.totalDistance.compareTo(b.totalDistance)); break;
      case SortType.speedDesc: sorted.sort((a, b) => b.maxSpeed.compareTo(a.maxSpeed)); break;
      case SortType.speedAsc: sorted.sort((a, b) => a.maxSpeed.compareTo(b.maxSpeed)); break;
    }
    return sorted;
  }

  void _showSortOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1e1e1e) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '정렬 기준',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...SortType.values.map((type) {
                final isSelected = _sortType == type;
                String label;
                switch (type) {
                  case SortType.dateDesc: label = '날짜 최신순'; break;
                  case SortType.dateAsc: label = '날짜 오래된순'; break;
                  case SortType.distanceDesc: label = '거리 긴순'; break;
                  case SortType.distanceAsc: label = '거리 짧은순'; break;
                  case SortType.speedDesc: label = '속도 빠른순'; break;
                  case SortType.speedAsc: label = '속도 느린순'; break;
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
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.blue : textColor,
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

  void _confirmDelete(BuildContext context, bool isDark) {
    final dialogBg = isDark ? const Color(0xFF1e1e1e) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text('정말 삭제할까요?', style: TextStyle(color: textColor)),
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
    required Color cardColor,
    required Color dropdownBg,
    required Color textColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: value != null ? Colors.blue.withOpacity(0.15) : cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value != null
                ? Colors.blue.withOpacity(0.5)
                : borderColor,
          ),
        ),
        child: DropdownButton<int?>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: dropdownBg,
          menuMaxHeight: 200,
          hint: Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          style: TextStyle(color: textColor, fontSize: 13),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                '$label 전체',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ...items.map(
              (item) => DropdownMenuItem<int?>(value: item, child: Text('$item')),
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
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final weightKg = settings.weightKg;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final panelColor = isDark ? Colors.grey[900]! : Colors.white;
    final dropdownBg = isDark ? const Color(0xFF2a2a2a) : Colors.grey[100]!;
    final deleteBg = isDark ? Colors.black : const Color(0xFFF2F4F7);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey : Colors.grey[600]!;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final resetBtnColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final sortBtnColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

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
              color: panelColor,
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
                    cardColor: cardColor,
                    dropdownBg: dropdownBg,
                    textColor: textColor,
                    borderColor: borderColor,
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
                            if (v == null) _filterDay = null;
                          }),
                    cardColor: cardColor,
                    dropdownBg: dropdownBg,
                    textColor: textColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(width: 6),
                  _filterBox(
                    label: '일',
                    value: _filterDay,
                    items: days,
                    onChanged: _filterMonth == null
                        ? null
                        : (v) => setState(() => _filterDay = v),
                    cardColor: cardColor,
                    dropdownBg: dropdownBg,
                    textColor: textColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(width: 6),
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
                        color: _filterYear != null ||
                                _filterMonth != null ||
                                _filterDay != null
                            ? Colors.blue.withOpacity(0.3)
                            : resetBtnColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.refresh,
                        color: _filterYear != null ||
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

            // 총 개수 + 정렬
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '총 ${formatNumber(filtered.length)}개',
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: _showSortOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: sortBtnColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sort, color: textColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _sortLabel,
                            style: TextStyle(color: textColor, fontSize: 12),
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
                  ? Center(
                      child: Text(
                        '해당 조건의 기록이 없어요',
                        style: TextStyle(color: subTextColor, fontSize: 16),
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
                        final time = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
                        final timeStr =
                            '${time.hour.toString().padLeft(2, '0')}:'
                            '${time.minute.toString().padLeft(2, '0')}';

                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: isPending
                                  ? null
                                  : () => _showRecordDetail(
                                      context, record, useKmh, weightKg, isDark),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isPending ? 0.35 : 1.0,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.fromLTRB(16, 16, 40, 16),
                                  decoration: BoxDecoration(
                                    color: isPending
                                        ? Colors.red.withOpacity(0.1)
                                        : cardColor,
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
                                      Text(
                                        '${record.year}년 ${record.month}월 ${record.day}일  $timeStr 출발',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      RecordBadges(
                                          recordId: record.id, bestIds: bestIds),
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
                                      if (weightKg != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          '🔥 ${formatNumber(calcCalories(record.totalDistance, weightKg)!)} kcal',
                                          style: const TextStyle(
                                              color: Colors.orange, fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: deleteBg,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _pendingDeleteIds.clear()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '취소',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor,
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
                        onTap: () => _confirmDelete(context, isDark),
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
      builder: (ctx) => StatefulBuilder(
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
    );
  }

}
