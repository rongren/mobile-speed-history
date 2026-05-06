import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';
import '../providers/settings_provider.dart';
import '../models/ride_record.dart';
import '../utils/format_utils.dart';
import '../widgets/memo_bottom_sheet.dart';
import '../widgets/stat_item.dart';

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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final alertKmh = settings.speedAlertKmh;
    final isOverAlert = alertKmh != null && ride.isRiding && ride.currentSpeed >= alertKmh;

    final speedTextColor = isOverAlert ? Colors.red : cs.onSurface;
    final panelColor = cs.surfaceContainer;
    final unitTextColor = cs.onSurfaceVariant;
    final selectorBgColor = cs.surfaceContainerHighest;
    final selectorBorderColor = cs.outlineVariant;
    final selectorTextColor = cs.onSurfaceVariant;
    final dividerColor = cs.outlineVariant;
    final statLabelColor = cs.onSurfaceVariant;

    final isPaused = ride.isRiding && ride.isPaused;
    final bgColor = isPaused
        ? Color.lerp(cs.surface, Colors.orange, isDark ? 0.13 : 0.09)!
        : cs.surface;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: bgColor,
        child: SafeArea(
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
                    color: isSelected ? Colors.blue : selectorBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.blue : selectorBorderColor,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$speed',
                      style: TextStyle(
                        color: isSelected ? Colors.white : selectorTextColor,
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
                  isDark: isDark,
                  isOverAlert: isOverAlert,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 150),
                      Text(
                        formatSpeed(ride.currentSpeed, useKmh),
                        style: TextStyle(
                          color: speedTextColor,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        speedUnit(useKmh),
                        style: TextStyle(
                          color: unitTextColor,
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
          _buildStatsRow(ride, settings, useKmh,
              panelColor: panelColor,
              dividerColor: dividerColor,
              labelColor: statLabelColor,
              valueColor: cs.onSurface,
              isDark: isDark),

          const SizedBox(height: 16),

          // 일시정지 표시 — 항상 공간 차지, 내용만 페이드
          AnimatedOpacity(
            opacity: isPaused ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pause_circle_outline,
                      color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    ride.isManuallyPaused ? '일시정지 중' : '자동 일시정지 중',
                    style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 시작/일시정지/정지 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (ride.isRiding) ...[
                // 일시정지 / 재개 버튼
                GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    if (ride.isManuallyPaused) {
                      ride.resumeRide();
                    } else {
                      ride.pauseRide();
                    }
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: ride.isManuallyPaused ? Colors.green : Colors.orange,
                      boxShadow: [
                        BoxShadow(
                          color: (ride.isManuallyPaused ? Colors.green : Colors.orange)
                              .withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      ride.isManuallyPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              // 시작 / 정지 버튼
              GestureDetector(
                onTap: () async {
                  SystemSound.play(SystemSoundType.click);
                  if (ride.isRiding) {
                    final useKmh = settings.useKmh;
                    final weightKg = settings.weightKg;
                    final minDist = settings.minRecordDistanceKm;
                    final minDur = settings.minRecordDurationSec;
                    final savedRecord = await ride.stopRide(
                      minRecordDistanceKm: minDist,
                      minRecordDurationSec: minDur,
                    );
                    if (!context.mounted) return;
                    if (savedRecord == null) {
                      final reason = ride.stopFailReason;
                      final msg = reason == 'duration'
                          ? '시간 부족 (최소 ${minDur}초) — 저장 안 됨'
                          : '거리 부족 (최소 ${formatDouble(minDist, 1)} km) — 저장 안 됨';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
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
                      speedAlertKmh: settings.speedAlertKmh,
                      lowSpeedMode: settings.lowSpeedMode,
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
            ],
          ),

          const SizedBox(height: 20),
        ],
        ),
      ),
      ),
    );
  }

  void _showRideSummary(BuildContext context, RideRecord record,
      bool useKmh, double? weightKg) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = TextEditingController();
    final ride = context.read<RideProvider>();
    final int? calories = calcCalories(record.totalDistance, weightKg);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(viewInsets: EdgeInsets.zero),
        child: StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '주행 완료',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      StatDetailItem(label: '거리', value: formatDistance(record.totalDistance, useKmh), unit: distanceUnit(useKmh), textColor: cs.onSurface),
                      StatDetailItem(label: '시간', value: formatDuration(record.duration), textColor: cs.onSurface),
                      StatDetailItem(label: '최고속도', value: formatSpeed(record.maxSpeed, useKmh), unit: speedUnit(useKmh), textColor: cs.onSurface),
                      if (calories != null)
                        StatDetailItem(label: '칼로리', value: formatNumber(calories), unit: 'kcal', textColor: cs.onSurface)
                      else
                        StatDetailItem(label: '평균속도', value: formatSpeed(record.avgSpeed, useKmh), unit: speedUnit(useKmh), textColor: cs.onSurface),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    await showMemoBottomSheet(ctx, controller: ctrl);
                    if (ctx.mounted) setDialogState(() {});
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 70),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ctrl.text.isEmpty
                        ? Text('메모를 남겨보세요 (탭하여 입력)',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14))
                        : Text(ctrl.text,
                            style: TextStyle(color: cs.onSurface, fontSize: 14)),
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
      ),
    );
  }

  Widget _buildStatsRow(
      RideProvider ride, SettingsProvider settings, bool useKmh, {
      required Color panelColor,
      required Color dividerColor,
      required Color labelColor,
      required Color valueColor,
      required bool isDark,
  }) {
    final currentAvgSpeed = ride.duration > 0
        ? ride.totalDistance / (ride.duration / 3600.0)
        : 0.0;

    final items = <(String, String)>[
      if (settings.showDistance)
        ('거리',
            '${formatDistance(ride.totalDistance, useKmh)} ${distanceUnit(useKmh)}'),
      if (settings.showDuration) ('시간', ride.formattedDuration),
      if (settings.showMaxSpeed)
        ('최고속도',
            '${formatSpeed(ride.maxSpeed, useKmh)} ${speedUnit(useKmh)}'),
      if (settings.showAvgSpeed)
        ('평균속도',
            '${formatSpeed(currentAvgSpeed, useKmh)} ${speedUnit(useKmh)}'),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: !isDark
              ? [const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) _divider(dividerColor),
              Expanded(child: _statCard(items[i].$1, items[i].$2, labelColor: labelColor, valueColor: valueColor)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, {required Color labelColor, required Color valueColor}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: labelColor, fontSize: 13),
        ),
      ],
    );
  }

  Widget _divider(Color color) {
    return Container(
      height: 36,
      width: 1,
      color: color,
    );
  }
}

class SpeedometerPainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final bool isDark;
  final bool isOverAlert;

  SpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
    this.isDark = true,
    this.isOverAlert = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    const startAngle = 150.0 * pi / 180;
    const sweepTotal = 240.0 * pi / 180;

    // 배경 호 (회색)
    final bgPaint = Paint()
      ..color = isDark ? Colors.grey[800]! : Colors.grey[300]!
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
      if (isOverAlert) {
        arcColor = Colors.red;
      } else if (speedRatio < 0.5) {
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
    _drawTicks(canvas, center, radius, startAngle, sweepTotal, isDark);

    // 바늘
    _drawNeedle(canvas, center, radius, speedRatio, startAngle, sweepTotal, isDark);

    // 중심 원
    canvas.drawCircle(center, 10, Paint()..color = isDark ? Colors.white : Colors.black87);
    canvas.drawCircle(center, 6, Paint()..color = isDark ? Colors.grey[900]! : const Color(0xFFF2F4F7));
  }

  void _drawTicks(Canvas canvas, Offset center, double radius,
      double startAngle, double sweepTotal, bool isDark) {
    const totalTicks = 24;
    const majorTickInterval = 4;

    for (int i = 0; i <= totalTicks; i++) {
      final angle = startAngle + (sweepTotal / totalTicks) * i;
      final isMajor = i % majorTickInterval == 0;

      final tickLength = isMajor ? 14.0 : 7.0;
      final tickWidth = isMajor ? 2.0 : 1.0;
      final tickColor = isMajor
          ? (isDark ? Colors.white : Colors.black87)
          : (isDark ? Colors.grey[600]! : Colors.grey[400]!);

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
            style: TextStyle(
              color: isDark ? Colors.grey : Colors.grey[600],
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
      double speedRatio, double startAngle, double sweepTotal, bool isDark) {
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
        ..color = isOverAlert ? Colors.red : (isDark ? Colors.white : Colors.black87)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed ||
        oldDelegate.maxSpeed != maxSpeed ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isOverAlert != isOverAlert;
  }
}