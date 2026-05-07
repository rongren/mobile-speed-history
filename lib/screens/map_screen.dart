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

  // 경로 오버레이 관리
  bool _pathOverlayAdded = false;
  int _lastPathLength = 0;

  // 마커 보간용
  NLatLng? _prevLatLng;
  NLatLng? _targetLatLng;
  NLatLng? _lastGpsLatLng;   // GPS 변경 감지
  DateTime? _lastGpsUpdateAt;

  NMapType _toNMapType(String type) {
    switch (type) {
      case 'satellite': return NMapType.satellite;
      case 'hybrid': return NMapType.hybrid;
      default: return NMapType.basic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final cs = Theme.of(context).colorScheme;
    final cardColor = cs.surfaceContainer;
    final textColor = cs.onSurface;
    final dividerColor = cs.outlineVariant;

    if (_mapController != null && ride.pathPoints.isNotEmpty) {
      if (ride.pathPoints.length != _lastPathLength) {
        _lastPathLength = ride.pathPoints.length;
        _drawPath(ride.pathPoints);
      }

      final last = ride.pathPoints.last;
      final latLng = NLatLng(last.latitude, last.longitude);

      // 새 GPS 좌표가 왔을 때만 보간 목표 갱신
      if (_lastGpsLatLng == null ||
          _lastGpsLatLng!.latitude != latLng.latitude ||
          _lastGpsLatLng!.longitude != latLng.longitude) {
        _prevLatLng = _targetLatLng ?? latLng;
        _targetLatLng = latLng;
        _lastGpsLatLng = latLng;
        _lastGpsUpdateAt = DateTime.now();
      }

      // 경과 시간 기반 보간 (1초에 걸쳐 이동)
      if (_prevLatLng != null && _targetLatLng != null && _lastGpsUpdateAt != null) {
        final t = (DateTime.now().difference(_lastGpsUpdateAt!).inMilliseconds / 1000.0).clamp(0.0, 1.0);
        final interpLat = _prevLatLng!.latitude + (_targetLatLng!.latitude - _prevLatLng!.latitude) * t;
        final interpLng = _prevLatLng!.longitude + (_targetLatLng!.longitude - _prevLatLng!.longitude) * t;
        _updateLocationMarker(NLatLng(interpLat, interpLng));
      }
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
        children: [
          // 지도
          Expanded(
            key: ValueKey(settings.mapType),
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: const NCameraPosition(
                  target: NLatLng(37.5665, 126.9780),
                  zoom: 15,
                ),
                locationButtonEnable: true,
                mapType: _toNMapType(settings.mapType),
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
            color: cardColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCard(
                  '거리',
                  '${formatDistance(ride.totalDistance, useKmh)} ${distanceUnit(useKmh)}',
                  Icons.straighten,
                  textColor,
                ),
                _divider(dividerColor),
                _statCard(
                  '시간',
                  ride.formattedDuration,
                  Icons.timer,
                  textColor,
                ),
                _divider(dividerColor),
                _statCard(
                  '최고속도',
                  '${formatSpeed(ride.maxSpeed, useKmh)} ${speedUnit(useKmh)}',
                  Icons.speed,
                  textColor,
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _updateLocationMarker(NLatLng latLng) {
    _locationOverlay?.setPosition(latLng);
  }

  Future<void> _drawPath(List<Position> positions) async {
    if (_mapController == null) return;

    if (_pathOverlayAdded) {
      await _mapController!.deleteOverlay(
        const NOverlayInfo(type: NOverlayType.polylineOverlay, id: 'ride_path'),
      );
      _pathOverlayAdded = false;
    }

    if (positions.length < 2) return;

    final coords = positions
        .map((p) => NLatLng(p.latitude, p.longitude))
        .toList();

    final polyline = NPolylineOverlay(
      id: 'ride_path',
      coords: coords,
      color: Colors.blue,
      width: 5,
    );

    await _mapController!.addOverlay(polyline);
    _pathOverlayAdded = true;
  }

  Widget _statCard(String label, String value, IconData icon, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: textColor,
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

  Widget _divider(Color color) {
    return Container(height: 40, width: 1, color: color);
  }
}