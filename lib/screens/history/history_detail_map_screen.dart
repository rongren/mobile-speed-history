import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:provider/provider.dart';
import '../../models/ride_record.dart';
import '../../providers/settings_provider.dart';
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

  NMapType _toNMapType(String type) {
    switch (type) {
      case 'satellite': return NMapType.satellite;
      case 'hybrid': return NMapType.hybrid;
      default: return NMapType.basic;
    }
  }

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
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? Colors.black : Colors.white;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dividerColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    NLatLng initialPosition = const NLatLng(37.5665, 126.9780);
    if (points.isNotEmpty) {
      final avgLat =
          points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
      final avgLng =
          points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
      initialPosition = NLatLng(avgLat, avgLng);
    }

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          '${record.year}년 ${record.month}월 ${record.day}일 '
              '${time.hour.toString().padLeft(2, '0')}:'
              '${time.minute.toString().padLeft(2, '0')} 출발',
          style: TextStyle(color: textColor, fontSize: 15),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: initialPosition,
                  zoom: 15,
                ),
                mapType: _toNMapType(settings.mapType),
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

                  final bounds = NLatLngBounds.from(points);
                  await controller.updateCamera(
                    NCameraUpdate.fitBounds(
                      bounds,
                      padding: const EdgeInsets.all(40),
                    ),
                  );
                }
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              color: cardColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statCard('거리',
                      '${formatDistance(record.totalDistance, useKmh)} ${distanceUnit(useKmh)}',
                      textColor),
                  _divider(dividerColor),
                  _statCard('시간', formatDuration(record.duration), textColor),
                  _divider(dividerColor),
                  _statCard('최고속도',
                      '${formatSpeed(record.maxSpeed, useKmh)} ${speedUnit(useKmh)}',
                      textColor),
                  _divider(dividerColor),
                  _statCard('평균속도',
                      '${formatSpeed(record.avgSpeed, useKmh)} ${speedUnit(useKmh)}',
                      textColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _divider(Color color) {
    return Container(height: 36, width: 1, color: color);
  }
}
