import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../../models/ride_record.dart';
import '../../utils/format_utils.dart';

class HistoryDetailMapScreen extends StatefulWidget {
  final RideRecord record;

  const HistoryDetailMapScreen({super.key, required this.record});

  @override
  State<HistoryDetailMapScreen> createState() =>
      _HistoryDetailMapScreenState();
}

class _HistoryDetailMapScreenState extends State<HistoryDetailMapScreen> {
  NaverMapController? _mapController;

  List<NLatLng> _parsePathPoints() {
    try {
      final List decoded = jsonDecode(widget.record.pathPoints);
      return decoded.map((p) => NLatLng(
        p['lat'] as double,
        p['lng'] as double,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final time = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
    final points = _parsePathPoints();

    // 경로 중심 좌표
    NLatLng initialPosition = const NLatLng(37.5665, 126.9780);
    if (points.isNotEmpty) {
      final avgLat =
          points.map((p) => p.latitude).reduce((a, b) => a + b) /
              points.length;
      final avgLng =
          points.map((p) => p.longitude).reduce((a, b) => a + b) /
              points.length;
      initialPosition = NLatLng(avgLat, avgLng);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${record.year}년 ${record.month}월 ${record.day}일 '
              '${time.hour.toString().padLeft(2, '0')}:'
              '${time.minute.toString().padLeft(2, '0')} 출발',
          style: const TextStyle(
              color: Colors.white, fontSize: 15),
        ),
      ),
      body: Column(
        children: [
          // 지도
          Expanded(
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: initialPosition,
                  zoom: 15,
                ),
              ),
              onMapReady: (controller) async {
                _mapController = controller;

                if (points.length >= 2) {
                  final polyline = NPolylineOverlay(
                    id: 'history_path',
                    coords: points,
                    color: Colors.blue,
                    width: 5,
                  );
                  await controller.addOverlay(polyline);

                  // 경로 전체가 보이도록 카메라 이동
                  final bounds = NLatLngBounds.from(points);
                  await controller.updateCamera(
                    NCameraUpdate.fitBounds(
                      bounds,
                      padding: EdgeInsets.all(40),
                    ),
                  );
                }
              },
            ),
          ),

          // 하단 통계 — SafeArea 추가
          SafeArea(
            top: false,
            child: Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statCard('거리',
                      '${record.totalDistance.toStringAsFixed(2)} km'),
                  _divider(),
                  _statCard('시간',
                      formatDuration(record.duration)),
                  _divider(),
                  _statCard('최고속도',
                      '${record.maxSpeed.toStringAsFixed(1)} km/h'),
                  _divider(),
                  _statCard('평균속도',
                      '${record.avgSpeed.toStringAsFixed(1)} km/h'),
                ],
              ),
            ),
          ),
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
              color: Colors.grey, fontSize: 12),
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