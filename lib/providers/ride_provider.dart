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
  double _targetSpeed = 0.0;
  double _previousSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _totalDistance = 0.0;
  bool _isRiding = false;
  int _interpolationStep = 0;
  static const int _interpolationSteps = 5;

  DateTime? _startTime;
  int _lastDuration = 0;
  Timer? _durationTimer;

  List<Position> pathPoints = [];
  List<RideRecord> records = [];
  Position? _lastPosition;
  StreamSubscription<Position>? _positionSubscription;

  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  double get totalDistance => _totalDistance;
  bool get isRiding => _isRiding;

  int get duration {
    if (_isRiding && _startTime != null) {
      return DateTime.now().difference(_startTime!).inSeconds;
    }
    return _lastDuration;
  }

  String get formattedDuration {
    final totalSeconds = duration;
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
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
    _lastDuration = 0;
    _interpolationStep = 0;
    _startTime = DateTime.now();
    pathPoints.clear();
    _lastPosition = null;

    // GPS 스트림
    _positionSubscription =
        LocationService.getPositionStream().listen((position) {
          _onPositionUpdate(position);
        });

    // 0.2초마다 타이머 — 속도 보간 + UI 갱신
    _durationTimer =
        Timer.periodic(const Duration(milliseconds: 200), (_) {
          _interpolateSpeed();
          notifyListeners();
        });

    await ForegroundServiceHelper.start();
    notifyListeners();
  }

  void _onPositionUpdate(Position position) {
    double rawSpeed = position.speed * 3.6;
    if (rawSpeed < 0) rawSpeed = 0;

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

  void _interpolateSpeed() {
    if (_interpolationStep < _interpolationSteps) {
      _interpolationStep++;
      final t = _interpolationStep / _interpolationSteps;
      _currentSpeed =
          _previousSpeed + (_targetSpeed - _previousSpeed) * t;
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

    final durationSeconds = duration;
    final durationHours = durationSeconds / 3600;
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
      duration: durationSeconds,
      pathPoints: pathJson,
      createdAt: _startTime?.millisecondsSinceEpoch ??
          now.millisecondsSinceEpoch,
    );

    await DatabaseHelper.instance.insertRecord(record);
    await loadRecords();
    await ForegroundServiceHelper.stop();

    _lastDuration = durationSeconds;
    _startTime = null;
    notifyListeners();
  }

  Future<void> deleteRecord(int id) async {
    await DatabaseHelper.instance.deleteRecord(id);
    await loadRecords();
  }

  String _formatDuration(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
}