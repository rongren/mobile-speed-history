import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';
import '../providers/settings_provider.dart';
import '../models/ride_record.dart';
import '../utils/format_utils.dart';

class SpeedometerScreen extends StatefulWidget {
  const SpeedometerScreen({super.key});

  @override
  State<SpeedometerScreen> createState() => _SpeedometerScreenState();
}

class _SpeedometerScreenState extends State<SpeedometerScreen> {
  double _maxSpeed = 60;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _maxSpeed = context
          .read<SettingsProvider>()
          .defaultGaugeSpeed
          .toDouble();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [

          // 최고속도 선택 라디오 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [60, 120, 180, 240].map((speed) {
              final isSelected = _maxSpeed == speed.toDouble();
              return GestureDetector(
                onTap: () => setState(() => _maxSpeed = speed.toDouble()),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 70,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[700]!,
                    ),
                  ),
                  child: Center(  // 이거 추가
                    child: Text(
                      '$speed',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // 속도계 게이지
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.width * 0.75,
              child: CustomPaint(
                painter: SpeedometerPainter(
                  speed: ride.currentSpeed,
                  maxSpeed: _maxSpeed,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 150),
                      Text(
                        convertSpeed(ride.currentSpeed, useKmh)
                            .toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        speedUnit(useKmh),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 통계 카드 (표시 항목 설정 반영)
          _buildStatsRow(ride, settings, useKmh),

          const SizedBox(height: 16),

          // 자동 일시정지 표시
          if (ride.isRiding && ride.isAutoPaused)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pause_circle_outline,
                      color: Colors.orange, size: 16),
                  SizedBox(width: 6),
                  Text('자동 일시정지 중',
                      style: TextStyle(color: Colors.orange, fontSize: 13)),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // 시작/정지 버튼
          GestureDetector(
            onTap: () async {
              if (ride.isRiding) {
                final useKmh = settings.useKmh;
                final weightKg = settings.weightKg;
                final minDist = settings.minRecordDistanceKm;
                final savedRecord = await ride.stopRide(
                  minRecordDistanceKm: minDist,
                );
                if (!context.mounted) return;
                if (savedRecord == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '거리 부족 (최소 ${minDist.toStringAsFixed(1)} km) — 저장 안 됨',
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else {
                  _showRideSummary(context, savedRecord, useKmh, weightKg);
                }
              } else {
                ride.startRide(
                  gpsHighAccuracy: settings.gpsHighAccuracy,
                  autoPause: settings.autoPause,
                );
              }
            },
            child: Container(
              width: 140,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: ride.isRiding ? Colors.red : Colors.green,
                boxShadow: [
                  BoxShadow(
                    color: (ride.isRiding ? Colors.red : Colors.green)
                        .withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  ride.isRiding ? '정지' : '시작',

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
        ),
      ),
    );
  }

  void _showRideSummary(BuildContext context, RideRecord record,
      bool useKmh, double? weightKg) {
    final ctrl = TextEditingController();
    final ride = context.read<RideProvider>();
    final int? calories = calcCalories(record.totalDistance, weightKg);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1e1e1e),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '주행 완료',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryStatCard('거리',
                          '${convertDistance(record.totalDistance, useKmh).toStringAsFixed(2)}',
                          distanceUnit(useKmh)),
                      _summaryStatCard(
                          '시간', formatDuration(record.duration), ''),
                      _summaryStatCard('최고속도',
                          '${convertSpeed(record.maxSpeed, useKmh).toStringAsFixed(1)}',
                          speedUnit(useKmh)),
                      if (calories != null)
                        _summaryStatCard(
                            '칼로리', formatNumber(calories), 'kcal')
                      else
                        _summaryStatCard('평균속도',
                            '${convertSpeed(record.avgSpeed, useKmh).toStringAsFixed(1)}',
                            speedUnit(useKmh)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 메모 표시 영역 (탭하면 바텀시트 입력)
                GestureDetector(
                  onTap: () async {
                    final bsCtrl = TextEditingController(text: ctrl.text);
                    await showModalBottomSheet(
                      context: ctx,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (bsCtx) => Padding(
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.of(bsCtx).viewInsets.bottom),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF1e1e1e),
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('메모',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: bsCtrl,
                                autofocus: true,
                                maxLength: 80,
                                maxLines: 5,
                                minLines: 3,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: '메모를 남겨보세요',
                                  hintStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14),
                                  filled: true,
                                  fillColor: Colors.grey[900],
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  counterStyle: const TextStyle(
                                      color: Colors.grey, fontSize: 11),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    ctrl.text = bsCtrl.text;
                                    Navigator.pop(bsCtx);
                                  },
                                  child: const Text('완료',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    if (ctx.mounted) setDialogState(() {});
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 70),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ctrl.text.isEmpty
                        ? Text('메모를 남겨보세요 (탭하여 입력)',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14))
                        : Text(ctrl.text,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final memo = ctrl.text.trim();
                      if (memo.isNotEmpty && record.id != null) {
                        await ride.updateMemo(record.id!, memo);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('확인',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryStatCard(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        if (unit.isNotEmpty)
          Text(unit,
              style:
                  const TextStyle(color: Colors.blue, fontSize: 11)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildStatsRow(
      RideProvider ride, SettingsProvider settings, bool useKmh) {
    final currentAvgSpeed = ride.duration > 0
        ? ride.totalDistance / (ride.duration / 3600.0)
        : 0.0;

    final items = <(String, String)>[
      if (settings.showDistance)
        ('거리',
            '${convertDistance(ride.totalDistance, useKmh).toStringAsFixed(2)} ${distanceUnit(useKmh)}'),
      if (settings.showDuration) ('시간', ride.formattedDuration),
      if (settings.showMaxSpeed)
        ('최고속도',
            '${convertSpeed(ride.maxSpeed, useKmh).toStringAsFixed(1)} ${speedUnit(useKmh)}'),
      if (settings.showAvgSpeed)
        ('평균속도',
            '${convertSpeed(currentAvgSpeed, useKmh).toStringAsFixed(1)} ${speedUnit(useKmh)}'),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) _divider(),
              Expanded(child: _statCard(items[i].$1, items[i].$2)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.grey[700],
    );
  }
}

class SpeedometerPainter extends CustomPainter {
  final double speed;
  final double maxSpeed;

  SpeedometerPainter({required this.speed, required this.maxSpeed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    const startAngle = 150.0 * pi / 180;
    const sweepTotal = 240.0 * pi / 180;

    // 배경 호 (회색)
    final bgPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    // 속도 호 (속도에 따라 색상 변경)
    final speedRatio = (speed / maxSpeed).clamp(0.0, 1.0);
    final speedSweep = sweepTotal * speedRatio;

    if (speedSweep > 0) {
      final Color arcColor;
      if (speedRatio < 0.5) {
        arcColor = Colors.blue;
      } else if (speedRatio < 0.75) {
        arcColor = Colors.green;
      } else if (speedRatio < 0.9) {
        arcColor = Colors.orange;
      } else {
        arcColor = Colors.red;
      }

      final speedPaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        speedSweep,
        false,
        speedPaint,
      );
    }

    // 눈금
    _drawTicks(canvas, center, radius, startAngle, sweepTotal);

    // 바늘
    _drawNeedle(canvas, center, radius, speedRatio, startAngle, sweepTotal);

    // 중심 원
    canvas.drawCircle(center, 10, Paint()..color = Colors.white);
    canvas.drawCircle(center, 6, Paint()..color = Colors.grey[900]!);
  }

  void _drawTicks(Canvas canvas, Offset center, double radius,
      double startAngle, double sweepTotal) {
    const totalTicks = 24;
    const majorTickInterval = 4;

    for (int i = 0; i <= totalTicks; i++) {
      final angle = startAngle + (sweepTotal / totalTicks) * i;
      final isMajor = i % majorTickInterval == 0;

      final tickLength = isMajor ? 14.0 : 7.0;
      final tickWidth = isMajor ? 2.0 : 1.0;
      final tickColor = isMajor ? Colors.white : Colors.grey[600]!;

      final outerR = radius - 18;
      final innerR = outerR - tickLength;

      final outerPoint = Offset(
        center.dx + outerR * cos(angle),
        center.dy + outerR * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + innerR * cos(angle),
        center.dy + innerR * sin(angle),
      );

      canvas.drawLine(
        outerPoint,
        innerPoint,
        Paint()
          ..color = tickColor
          ..strokeWidth = tickWidth,
      );

      // 주요 눈금 숫자
      if (isMajor) {
        final speedLabel =
        ((maxSpeed / totalTicks) * i).round().toString();
        final labelR = outerR - tickLength - 16;
        final labelPoint = Offset(
          center.dx + labelR * cos(angle),
          center.dy + labelR * sin(angle),
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: speedLabel,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          labelPoint -
              Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }
  }

  void _drawNeedle(Canvas canvas, Offset center, double radius,
      double speedRatio, double startAngle, double sweepTotal) {
    final needleAngle = startAngle + sweepTotal * speedRatio;
    final needleLength = radius - 35;

    final needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );
    final tailEnd = Offset(
      center.dx - 20 * cos(needleAngle),
      center.dy - 20 * sin(needleAngle),
    );

    canvas.drawLine(
      tailEnd,
      needleEnd,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed || oldDelegate.maxSpeed != maxSpeed;
  }
}