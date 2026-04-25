import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ChartDataType { distance, duration, maxSpeed, avgSpeed }

class BarChartWidget extends StatefulWidget {
  final List<String> labels;
  final List<double> distanceData;
  final List<double> durationData;
  final List<double> maxSpeedData;
  final List<double> avgSpeedData;
  final Function(int index)? onBarTap;
  final int selectedIndex;

  const BarChartWidget({
    super.key,
    required this.labels,
    required this.distanceData,
    required this.durationData,
    required this.maxSpeedData,
    required this.avgSpeedData,
    this.onBarTap,
    this.selectedIndex = -1,
  });

  @override
  State<BarChartWidget> createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget>
    with SingleTickerProviderStateMixin {
  ChartDataType _selectedType = ChartDataType.distance;
  bool _showAverage = false;
  final ScrollController _scrollController = ScrollController();

  static const double barWidth = 22.0;
  static const double barSpacing = 22.0;
  static const double chartHeight = 160.0;
  static const double labelHeight = 36.0;
  static const double valueHeight = 30.0;
  static const double totalHeight = chartHeight + labelHeight + valueHeight + 1;

  int _visibleStart = 0;
  int _visibleEnd = 0;
  double _visibleMaxValue = 1.0;

  late AnimationController _animationController;
  late Animation<double> _animation;
  double _prevMaxValue = 1.0; // 추가

  @override
  void initState() {
    super.initState();

    // 애니메이션 추가
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToEnd();
      _updateVisibleRange();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _updateVisibleRange();
  }

  void _jumpToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _updateVisibleRange() {
    if (!_scrollController.hasClients) return;
    final data = _currentData;
    if (data.isEmpty) return;

    final itemWidth = barWidth + barSpacing;
    final scrollOffset = _scrollController.offset;
    final viewportWidth = _scrollController.position.viewportDimension;

    final start = (scrollOffset / itemWidth).floor().clamp(0, data.length - 1);
    final end = ((scrollOffset + viewportWidth) / itemWidth).ceil().clamp(
      0,
      data.length - 1,
    );

    final visibleData = data.sublist(start, (end + 1).clamp(0, data.length));
    final maxVal = visibleData.isEmpty
        ? 1.0
        : visibleData.reduce((a, b) => a > b ? a : b);
    final newMaxVal = maxVal > 0 ? maxVal : 1.0;

    if (start != _visibleStart ||
        end != _visibleEnd ||
        newMaxVal != _visibleMaxValue) {
      // 최대값 바뀔 때만 애니메이션
      if (newMaxVal != _visibleMaxValue) {
        _prevMaxValue = _visibleMaxValue;
        _animationController.forward(from: 0);
      }
      setState(() {
        _visibleStart = start;
        _visibleEnd = end;
        _visibleMaxValue = newMaxVal;
      });
    }
  }

  List<double> get _currentData {
    switch (_selectedType) {
      case ChartDataType.distance:
        return widget.distanceData;
      case ChartDataType.duration:
        return widget.durationData;
      case ChartDataType.maxSpeed:
        return widget.maxSpeedData;
      case ChartDataType.avgSpeed:
        return widget.avgSpeedData;
    }
  }

  String _formatValue(double value) {
    switch (_selectedType) {
      case ChartDataType.distance:
        return '${value.toStringAsFixed(1)}km';
      case ChartDataType.duration:
        final h = (value / 3600).floor();
        final m = ((value % 3600) / 60).floor();
        return h > 0 ? '${h}h${m}m' : '${m}m';
      case ChartDataType.maxSpeed:
      case ChartDataType.avgSpeed:
        return '${value.toStringAsFixed(1)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 데이터 선택 버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(child: _typeButton('거리', ChartDataType.distance)),
              const SizedBox(width: 5),
              Expanded(child: _typeButton('시간', ChartDataType.duration)),
              const SizedBox(width: 5),
              Expanded(child: _typeButton('최고속도', ChartDataType.maxSpeed)),
              const SizedBox(width: 5),
              Expanded(child: _typeButton('평균속도', ChartDataType.avgSpeed)),
              const SizedBox(width: 8),
              Container(width: 1, height: 26, color: Colors.grey[800]),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showAverage = !_showAverage),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _showAverage
                        ? Colors.orange.withOpacity(0.15)
                        : Colors.grey[850],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _showAverage ? Colors.orange : Colors.grey[700]!,
                    ),
                  ),
                  child: Text(
                    '평균',
                    style: TextStyle(
                      color: _showAverage ? Colors.orange : Colors.grey,
                      fontSize: 12,
                      fontWeight: _showAverage ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 그래프
        Expanded(
          child: _currentData.isEmpty
              ? const Center(
                  child: Text(
                    '아직 주행기록이 없어요',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : _buildChart(),
        ),
      ],
    );
  }

  Widget _typeButton(String label, ChartDataType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _visibleStart = 0;
          _visibleEnd = 0;
          _visibleMaxValue = 1.0;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _jumpToEnd();
          _updateVisibleRange();
        });
      },
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[700]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    final data = _currentData;
    final totalWidth = (barWidth + barSpacing) * data.length;

    return GestureDetector(
      onHorizontalDragUpdate: (_) {},
      onTapUp: (details) {
        // 탭한 위치로 인덱스 계산
        final scrollOffset = _scrollController.hasClients
            ? _scrollController.offset
            : 0.0;
        final tapX = details.localPosition.dx + scrollOffset;
        final index = (tapX / (barWidth + barSpacing)).floor().clamp(
          0,
          widget.labels.length - 1,
        );

        widget.onBarTap?.call(index);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            _updateVisibleRange();
          }
          return true;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: totalWidth,
            height: totalHeight,
            child: AnimatedBuilder(
              // 추가
              animation: _animation,
              builder: (context, _) {
                // 이전값 → 현재값 보간
                final animatedMax =
                    _prevMaxValue +
                    (_visibleMaxValue - _prevMaxValue) * _animation.value;

                return CustomPaint(
                  painter: BarChartPainter(
                    data: data,
                    labels: widget.labels,
                    maxValue: animatedMax,
                    visibleStart: _visibleStart,
                    visibleEnd: _visibleEnd,
                    barWidth: barWidth,
                    barSpacing: barSpacing,
                    chartHeight: chartHeight,
                    labelHeight: labelHeight,
                    valueHeight: valueHeight,
                    formatValue: _formatValue,
                    selectedIndex: widget.selectedIndex,
                    showAverage: _showAverage,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final double maxValue;
  final int visibleStart;
  final int visibleEnd;
  final double barWidth;
  final double barSpacing;
  final double chartHeight;
  final double labelHeight;
  final double valueHeight;
  final String Function(double) formatValue;
  final int selectedIndex;
  final bool showAverage;

  BarChartPainter({
    required this.data,
    required this.labels,
    required this.maxValue,
    required this.visibleStart,
    required this.visibleEnd,
    required this.barWidth,
    required this.barSpacing,
    required this.chartHeight,
    required this.labelHeight,
    required this.valueHeight,
    required this.formatValue,
    this.selectedIndex = -1,
    this.showAverage = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()..color = Colors.blue;
    final linePaint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 1;

    final valuePainterStyle = TextStyle(
      color: Colors.white,
      fontSize: 9,
      fontWeight: FontWeight.bold,
    );

    final labelPainterStyle = const TextStyle(
      color: Color(0xFF9E9E9E),
      fontSize: 10,
    );

    // 보이는 범위만 그리기
    final renderStart = (visibleStart - 5).clamp(0, data.length - 1);
    final renderEnd = (visibleEnd + 5).clamp(0, data.length - 1);

    for (int i = renderStart; i <= renderEnd; i++) {
      final isSelected = i == selectedIndex;

      // 막대 색상 — 선택 여부에 따라 변경
      final barPaint = Paint()
        ..color = isSelected ? const Color(0xFF64D4FF) : Colors.blue;

      final value = data[i];
      final ratio = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
      final barHeight = (chartHeight * ratio).clamp(4.0, chartHeight);
      final x = i * (barWidth + barSpacing);

      final barTop = valueHeight + (chartHeight - barHeight);
      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, barTop, barWidth, barHeight),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(barRect, barPaint);

      // 값 텍스트 색상도 변경
      final valuePainterStyle = TextStyle(
        color: isSelected ? Colors.white : Colors.white,
        fontSize: 9,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      );

      // 라벨 색상 변경
      final labelPainterStyle = TextStyle(
        color: isSelected
            ? Colors
                  .blue // 선택된 라벨은 파란색
            : const Color(0xFF9E9E9E),
        fontSize: isSelected ? 11 : 10, // 선택된 라벨은 살짝 크게
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      );

      // 값 텍스트
      final valueText = TextPainter(
        text: TextSpan(text: formatValue(value), style: valuePainterStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: barWidth + barSpacing);

      valueText.paint(
        canvas,
        Offset(
          x + (barWidth - valueText.width) / 2,
          barTop - valueText.height - 2,
        ),
      );

      // 라벨 텍스트
      final labelText = TextPainter(
        text: TextSpan(text: labels[i], style: labelPainterStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
      )..layout(maxWidth: barWidth + barSpacing);

      labelText.paint(
        canvas,
        Offset(
          x + (barWidth - labelText.width) / 2,
          valueHeight + chartHeight + 6,
        ),
      );
    }
    // 평균선 그리기
    if (showAverage && data.isNotEmpty) {
      final avg = data.reduce((a, b) => a + b) / data.length;
      final avgRatio = maxValue > 0 ? (avg / maxValue).clamp(0.0, 1.0) : 0.0;
      final avgY = valueHeight + chartHeight - (chartHeight * avgRatio);

      final avgPaint = Paint()
        ..color = Colors.orange.withOpacity(0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // 점선으로 그리기
      double x = 0;
      const dashWidth = 8.0;
      const dashSpace = 4.0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, avgY), Offset(x + dashWidth, avgY), avgPaint);
        x += dashWidth + dashSpace;
      }

      // 평균 라벨
      final avgText = TextPainter(
        text: TextSpan(
          text: '평균 ${formatValue(avg)}',
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      const labelPadH = 5.0;
      const labelPadV = 2.0;
      final labelLeft = 4.0;
      final labelTop = avgY - avgText.height - labelPadV * 2 - 2;
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          labelLeft,
          labelTop,
          avgText.width + labelPadH * 2,
          avgText.height + labelPadV * 2,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        bgRect,
        Paint()..color = const Color(0xCC1a1a1a),
      );
      avgText.paint(
        canvas,
        Offset(labelLeft + labelPadH, labelTop + labelPadV),
      );
    }

    // 구분선
    canvas.drawLine(
      Offset(0, valueHeight + chartHeight),
      Offset(size.width, valueHeight + chartHeight),
      linePaint,
    );
    // 구분선
    canvas.drawLine(
      Offset(0, valueHeight + chartHeight),
      Offset(size.width, valueHeight + chartHeight),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(BarChartPainter oldDelegate) {
    return oldDelegate.maxValue != maxValue ||
        oldDelegate.visibleStart != visibleStart ||
        oldDelegate.visibleEnd != visibleEnd ||
        oldDelegate.data != data ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.showAverage != showAverage;
  }
}
