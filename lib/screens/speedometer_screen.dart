import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/format_utils.dart';

class SpeedometerScreen extends StatefulWidget {
  const SpeedometerScreen({super.key});

  @override
  State<SpeedometerScreen> createState() => _SpeedometerScreenState();
}

class _SpeedometerScreenState extends State<SpeedometerScreen> {
  double _maxSpeed = 60;

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

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

          // 통계 3개
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statCard(
                    '거리',
                    '${convertDistance(ride.totalDistance, useKmh).toStringAsFixed(2)} ${distanceUnit(useKmh)}',
                  ),
                  _divider(),
                  _statCard('시간', ride.formattedDuration),
                  _divider(),
                  _statCard(
                    '최고속도',
                    '${convertSpeed(ride.maxSpeed, useKmh).toStringAsFixed(1)} ${speedUnit(useKmh)}',
                  ),
                ],
              ),
            ),
          ),

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
                final saved = await ride.stopRide(
                  minRecordDistanceKm: settings.minRecordDistanceKm,
                );
                if (!saved && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '거리 부족 (최소 ${settings.minRecordDistanceKm.toStringAsFixed(1)} km) — 저장 안 됨',
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
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