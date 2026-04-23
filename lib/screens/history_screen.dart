import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {

  @override
  void initState() {
    super.initState();
    // 진입할 때마다 갱신
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideProvider>().loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();
    final records = ride.records;  // Provider에서 받아오기

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('주행기록',
            style: TextStyle(color: Colors.white)),
      ),
      body: records.isEmpty
          ? const Center(
        child: Text(
          '아직 주행기록이 없어요',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return Container(
            margin: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.year}년 ${record.month}월 ${record.day}일',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
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
          );
        },
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

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}