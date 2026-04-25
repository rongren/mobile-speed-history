import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/ride_record.dart';
import '../db/database_helper.dart';
import '../services/location_service.dart';
import '../services/foreground_service.dart';
import '../utils/format_utils.dart';

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

  // 자동 일시정지
  bool _autoPauseEnabled = false;
  bool _isAutoPaused = false;
  DateTime? _autoPausedAt;
  int _totalPausedMs = 0;
  int _lowSpeedCount = 0;
  static const double _autoPauseSpeedThreshold = 2.0;
  static const int _autoPauseCountThreshold = 3;

  List<Position> pathPoints = [];
  List<RideRecord> records = [];
  Position? _lastPosition;
  StreamSubscription<Position>? _positionSubscription;

  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  double get totalDistance => _totalDistance;
  bool get isRiding => _isRiding;
  bool get isAutoPaused => _isAutoPaused;

  int get duration {
    if (_isRiding && _startTime != null) {
      final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;
      var paused = _totalPausedMs;
      if (_isAutoPaused && _autoPausedAt != null) {
        paused += DateTime.now().difference(_autoPausedAt!).inMilliseconds;
      }
      return ((elapsed - paused) / 1000).floor().clamp(0, 999999);
    }
    return _lastDuration;
  }

  String get formattedDuration => formatDuration(duration);

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

  Future<void> startRide({
    bool gpsHighAccuracy = true,
    bool autoPause = false,
  }) async {
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

    _autoPauseEnabled = autoPause;
    _isAutoPaused = false;
    _autoPausedAt = null;
    _totalPausedMs = 0;
    _lowSpeedCount = 0;

    // GPS 스트림
    _positionSubscription =
        LocationService.getPositionStream(highAccuracy: gpsHighAccuracy)
            .listen((position) {
          _onPositionUpdate(position);
        });

    // 0.2초마다 타이머 — 속도 보간 + UI 갱신
    _durationTimer =
        Timer.periodic(const Duration(milliseconds: 200), (_) {
          _interpolateSpeed();
          notifyListeners();
        });

    await WakelockPlus.enable();
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

    // 자동 일시정지
    if (_autoPauseEnabled) {
      if (rawSpeed < _autoPauseSpeedThreshold) {
        _lowSpeedCount++;
        if (_lowSpeedCount >= _autoPauseCountThreshold && !_isAutoPaused) {
          _isAutoPaused = true;
          _autoPausedAt = DateTime.now();
        }
      } else {
        _lowSpeedCount = 0;
        if (_isAutoPaused) {
          _isAutoPaused = false;
          _totalPausedMs +=
              DateTime.now().difference(_autoPausedAt!).inMilliseconds;
          _autoPausedAt = null;
        }
      }
    }
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

  // 저장됐으면 true, 최소거리 미달로 스킵됐으면 false
  Future<bool> stopRide({double minRecordDistanceKm = 0.0}) async {
    final durationSeconds = duration; // _isRiding 변경 전에 캡처
    _isRiding = false;
    _isAutoPaused = false;
    _positionSubscription?.cancel();
    _durationTimer?.cancel();

    final startedAt = _startTime?.millisecondsSinceEpoch;
    await WakelockPlus.disable();
    await ForegroundServiceHelper.stop();
    _lastDuration = durationSeconds;
    _startTime = null;

    // 최소 기록 거리 미달 시 저장 안 함
    if (_totalDistance < minRecordDistanceKm) {
      notifyListeners();
      return false;
    }

    final pathJson = jsonEncode(
      pathPoints.map((p) => {
        'lat': p.latitude,
        'lng': p.longitude,
      }).toList(),
    );
    final durationHours = durationSeconds / 3600.0;
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
      createdAt: startedAt ?? now.millisecondsSinceEpoch,
    );

    await DatabaseHelper.instance.insertRecord(record);
    await loadRecords();
    notifyListeners();
    return true;
  }

  Future<void> deleteRecord(int id) async {
    await DatabaseHelper.instance.deleteRecord(id);
    await loadRecords();
  }

}