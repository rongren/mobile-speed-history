import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ride_provider.dart';

class HistoryAverageScreen extends StatelessWidget {
  const HistoryAverageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final records = context.watch<RideProvider>().records;

    if (records.isEmpty) {
      return _emptyWidget();
    }

    final avgDistance = records.fold(0.0, (s, r) => s + r.totalDistance) / records.length;
    final avgDuration = records.fold(0, (s, r) => s + r.duration) ~/ records.length;
    final avgMaxSpeed = records.fold(0.0, (s, r) => s + r.maxSpeed) / records.length;
    final avgAvgSpeed = records.fold(0.0, (s, r) => s + r.avgSpeed) / records.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _sectionTitle('1회 평균'),
          _statRow('평균 거리', '${avgDistance.toStringAsFixed(2)} km'),
          _statRow('평균 시간', _formatDuration(avgDuration)),
          _statRow('평균 최고속도', '${avgMaxSpeed.toStringAsFixed(1)} km/h'),
          _statRow('평균 속도', '${avgAvgSpeed.toStringAsFixed(1)} km/h'),
          const SizedBox(height: 24),
          _sectionTitle('전체 누적'),
          _statRow('총 주행 횟수', '${records.length}회'),
          _statRow('총 거리',
              '${records.fold(0.0, (s, r) => s + r.totalDistance).toStringAsFixed(2)} km'),
          _statRow('총 시간',
              _formatDuration(records.fold(0, (s, r) => s + r.duration))),
          _statRow('최고 속도',
              '${records.map((r) => r.maxSpeed).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)} km/h'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      margin: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              )),
        ],
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

  Widget _emptyWidget() {
    return const Center(
      child: Text('아직 주행기록이 없어요',
          style: TextStyle(color: Colors.grey, fontSize: 16)),
    );
  }
}