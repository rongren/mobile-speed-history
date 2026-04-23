import 'dart:math';
import '../models/ride_record.dart';
import 'database_helper.dart';

class SampleDataHelper {
  static Future<void> insertSampleData() async {
    print('샘플 데이터 삽입 시작!');

    final db = DatabaseHelper.instance;

    // 기존 데이터 전체 삭제 추가
    final database = await db.database;
    await database.delete('ride_records');

    final random = Random();

    // 2022년 1월 1일부터 오늘까지
    final start = DateTime(2016, 1, 1);
    final end = DateTime.now();

    DateTime current = start;

    while (current.isBefore(end)) {
      // 월요일(1)부터 일요일(7) 중 이번 주 탈 날짜 랜덤 선택 (3~6일)
      final weekStart = current;
      final rideDays = <int>{};
      final rideCount = 3 + random.nextInt(4); // 3~6일

      while (rideDays.length < rideCount) {
        rideDays.add(random.nextInt(7)); // 0~6 (월~일)
      }

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final day = weekStart.add(Duration(days: dayOffset));
        if (day.isAfter(end)) break;

        if (rideDays.contains(dayOffset)) {
          // 하루에 1~4회 주행
          final sessionCount = random.nextInt(4) + 1;

          for (int s = 0; s < sessionCount; s++) {
            // 거리: 5~40km 랜덤
            final distance = 5.0 + random.nextDouble() * 35;

            // 평균속도: 15~28 km/h 랜덤
            final avgSpeed = 15.0 + random.nextDouble() * 13;

            // 시간 = 거리 / 속도 (초)
            final duration = ((distance / avgSpeed) * 3600).toInt();

            // 최고속도: 평균 * 1.3~1.7
            final maxSpeed =
                avgSpeed * (1.3 + random.nextDouble() * 0.4);

            // 출발 시간: 오전 6시 ~ 오후 8시
            final hour = 6 + random.nextInt(14);
            final minute = random.nextInt(60);
            final rideTime = DateTime(
                day.year, day.month, day.day, hour, minute);

            final record = RideRecord(
              year: day.year,
              month: day.month,
              day: day.day,
              totalDistance: double.parse(
                  distance.toStringAsFixed(2)),
              maxSpeed: double.parse(
                  maxSpeed.toStringAsFixed(1)),
              avgSpeed: double.parse(
                  avgSpeed.toStringAsFixed(1)),
              duration: duration,
              pathPoints: '[]',
              createdAt: rideTime.millisecondsSinceEpoch,
            );

            await db.insertRecord(record);
          }
        }
      }

      // 다음 주로
      current = weekStart.add(const Duration(days: 7));
    }

    print('샘플 데이터 삽입 완료!');
  }
}