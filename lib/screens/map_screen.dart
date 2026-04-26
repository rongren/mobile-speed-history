import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/format_utils.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  NaverMapController? _mapController;
  NLocationOverlay? _locationOverlay;

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();
    final useKmh = context.watch<SettingsProvider>().useKmh;

    if (_mapController != null && ride.pathPoints.isNotEmpty) {
      _drawPath(ride.pathPoints);
      _updateLocationMarker(ride.pathPoints.last);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
        children: [
          // 지도
          Expanded(
            child: NaverMap(
              options: const NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(37.5665, 126.9780),
                  zoom: 15,
                ),
                locationButtonEnable: true,
              ),
              onMapReady: (controller) async {
                _mapController = controller;

                _locationOverlay = await controller.getLocationOverlay();
                _locationOverlay?.setIsVisible(true);

                try {
                  final position = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high,
                  );

                  _locationOverlay?.setPosition(
                    NLatLng(position.latitude, position.longitude),
                  );

                  // 애니메이션 없이 바로 이동 (reason: 멀미 방지)
                  await controller.updateCamera(
                    NCameraUpdate.scrollAndZoomTo(
                      target: NLatLng(position.latitude, position.longitude),
                      zoom: 16,
                    )..setAnimation(
                      animation: NCameraAnimation.none,  // 애니메이션 없음
                    ),
                  );
                } catch (e) {
                  print('위치 가져오기 실패: $e');
                }
              },
            ),
          ),

          // 하단 통계
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCard(
                  '거리',
                  '${convertDistance(ride.totalDistance, useKmh).toStringAsFixed(2)} ${distanceUnit(useKmh)}',
                  Icons.straighten,
                ),
                _divider(),
                _statCard(
                  '시간',
                  ride.formattedDuration,
                  Icons.timer,
                ),
                _divider(),
                _statCard(
                  '최고속도',
                  '${convertSpeed(ride.maxSpeed, useKmh).toStringAsFixed(1)} ${speedUnit(useKmh)}',
                  Icons.speed,
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  // 위치 오버레이 업데이트 (주행 중 마커 이동)
  void _updateLocationMarker(Position position) {
    _locationOverlay?.setPosition(
      NLatLng(position.latitude, position.longitude),
    );
  }

  Future<void> _drawPath(List<Position> positions) async {
    if (_mapController == null || positions.length < 2) return;

    final coords = positions
        .map((p) => NLatLng(p.latitude, p.longitude))
        .toList();

    final polyline = NPolylineOverlay(
      id: 'ride_path',
      coords: coords,
      color: Colors.blue,
      width: 5,
    );

    _mapController!.addOverlay(polyline);
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[700],
    );
  }
}