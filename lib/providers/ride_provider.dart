import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ride_record.dart';
import '../db/database_helper.dart';
import '../services/location_service.dart';
import '../services/foreground_service.dart';

class RideProvider extends ChangeNotifier {
  double _currentSpeed = 0.0;
  double _targetSpeed = 0.0;      // GPS에서 받은 실제 속도
  double _previousSpeed = 0.0;    // 이전 GPS 속도
  double _maxSpeed = 0.0;
  double _totalDistance = 0.0;
  int _durationMs = 0;
  bool _isRiding = false;
  int _interpolationStep = 0;     // 보간 진행 단계
  static const int _interpolationSteps = 5; // 0.2초 * 5 = 1초

  List<Position> pathPoints = [];
  Position? _lastPosition;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _durationTimer;

  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  double get totalDistance => _totalDistance;
  int get duration => _durationMs ~/ 1000;
  bool get isRiding => _isRiding;

  // 기록 리스트 추가
  List<RideRecord> records = [];

  // getAllRecords 추가
  Future<void> loadRecords() async {
    records = await DatabaseHelper.instance.getAllRecords();
    notifyListeners();
  }

  Future<void> startRide() async {
    final hasPermission = await LocationService.requestPermission();
    if (!hasPermission) return;

    _isRiding = true;
    _currentSpeed = 0.0;
    _targetSpeed = 0.0;
    _previousSpeed = 0.0;
    _maxSpeed = 0.0;
    _totalDistance = 0.0;
    _durationMs = 0;
    _interpolationStep = 0;
    pathPoints.clear();
    _lastPosition = null;

    // GPS 스트림
    _positionSubscription = LocationService.getPositionStream().listen((position) {
      _onPositionUpdate(position);
    });

    // 0.2초마다 타이머 — 시간 + 속도 보간
    _durationTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _durationMs += 200;
      _interpolateSpeed();
      notifyListeners();
    });

    await ForegroundServiceHelper.start();
    print('포그라운드 서비스 시작됨');
    notifyListeners();
  }

  void _onPositionUpdate(Position position) {
    double rawSpeed = position.speed * 3.6;
    if (rawSpeed < 0) rawSpeed = 0;

    // GPS 값 받으면 보간 시작점 초기화
    _previousSpeed = _currentSpeed;
    _targetSpeed = rawSpeed;
    _interpolationStep = 0;

    if (rawSpeed > _maxSpeed) _maxSpeed = rawSpeed;

    if (_lastPosition != null) {
      double distanceInMeters = LocationService.calculateDistance(
        _lastPosition!, position,
      );
      _totalDistance += distanceInMeters / 1000;
    }

    pathPoints.add(position);
    _lastPosition = position;
  }

  // 0.2초마다 이전속도 → 목표속도 사이를 부드럽게 보간
  void _interpolateSpeed() {
    if (_interpolationStep < _interpolationSteps) {
      _interpolationStep++;
      final t = _interpolationStep / _interpolationSteps;
      // 선형 보간
      _currentSpeed = _previousSpeed + (_targetSpeed - _previousSpeed) * t;
    } else {
      _currentSpeed = _targetSpeed;
    }
  }

  Future<void> stopRide() async {
    _isRiding = false;
    _positionSubscription?.cancel();
    _durationTimer?.cancel();

    final pathJson = jsonEncode(
      pathPoints.map((p) => {
        'lat': p.latitude,
        'lng': p.longitude,
      }).toList(),
    );

    // 평균속도 계산 (거리 / 시간)
    final durationHours = (_durationMs / 1000) / 3600;
    final avgSpeed = durationHours > 0
        ? _totalDistance / durationHours
        : 0.0;

    final now = DateTime.now();
    final record = RideRecord(
      year: now.year,
      month: now.month,
      day: now.day,
      totalDistance: _totalDistance,
      maxSpeed: _maxSpeed,
      avgSpeed: avgSpeed,
      duration: _durationMs ~/ 1000,
      pathPoints: pathJson,
      createdAt: now.millisecondsSinceEpoch,
    );

    await DatabaseHelper.instance.insertRecord(record);
    await loadRecords();  // 추가
    await ForegroundServiceHelper.stop();
    notifyListeners();
  }

  String get formattedDuration {
    int totalSeconds = _durationMs ~/ 1000;
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  Future<void> deleteRecord(int id) async {
    await DatabaseHelper.instance.deleteRecord(id);
    await loadRecords();
  }

  Map<String, int?> get bestRecordIds {
    if (records.isEmpty) return {};

    final maxDistance = records.reduce((a, b) =>
    a.totalDistance > b.totalDistance ? a : b);
    final maxSpeed = records.reduce((a, b) =>
    a.maxSpeed > b.maxSpeed ? a : b);
    final maxDuration = records.reduce((a, b) =>
    a.duration > b.duration ? a : b);

    return {
      'distance': maxDistance.id,
      'speed': maxSpeed.id,
      'duration': maxDuration.id,
    };
  }
}