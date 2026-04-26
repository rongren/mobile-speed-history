import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyUseKmh = 'use_kmh';
  static const _keyGpsHighAccuracy = 'gps_high_accuracy';
  static const _keyMinRecordDistance = 'min_record_distance';
  static const _keyAutoPause = 'auto_pause';
  static const _keyDefaultGaugeSpeed = 'default_gauge_speed';
  static const _keyShowDistance = 'show_distance';
  static const _keyShowDuration = 'show_duration';
  static const _keyShowMaxSpeed = 'show_max_speed';
  static const _keyShowAvgSpeed = 'show_avg_speed';

  bool _useKmh = true;
  bool _gpsHighAccuracy = true;
  double _minRecordDistanceKm = 0.1;
  bool _autoPause = false;
  int _defaultGaugeSpeed = 60;
  bool _showDistance = true;
  bool _showDuration = true;
  bool _showMaxSpeed = true;
  bool _showAvgSpeed = true;

  bool get useKmh => _useKmh;
  bool get gpsHighAccuracy => _gpsHighAccuracy;
  double get minRecordDistanceKm => _minRecordDistanceKm;
  bool get autoPause => _autoPause;
  int get defaultGaugeSpeed => _defaultGaugeSpeed;
  bool get showDistance => _showDistance;
  bool get showDuration => _showDuration;
  bool get showMaxSpeed => _showMaxSpeed;
  bool get showAvgSpeed => _showAvgSpeed;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _useKmh = prefs.getBool(_keyUseKmh) ?? true;
    _gpsHighAccuracy = prefs.getBool(_keyGpsHighAccuracy) ?? true;
    _minRecordDistanceKm = prefs.getDouble(_keyMinRecordDistance) ?? 0.1;
    _autoPause = prefs.getBool(_keyAutoPause) ?? false;
    _defaultGaugeSpeed = prefs.getInt(_keyDefaultGaugeSpeed) ?? 60;
    _showDistance = prefs.getBool(_keyShowDistance) ?? true;
    _showDuration = prefs.getBool(_keyShowDuration) ?? true;
    _showMaxSpeed = prefs.getBool(_keyShowMaxSpeed) ?? true;
    _showAvgSpeed = prefs.getBool(_keyShowAvgSpeed) ?? true;
    notifyListeners();
  }

  Future<void> setUseKmh(bool value) async {
    _useKmh = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseKmh, value);
  }

  Future<void> setGpsHighAccuracy(bool value) async {
    _gpsHighAccuracy = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGpsHighAccuracy, value);
  }

  Future<void> setMinRecordDistanceKm(double value) async {
    _minRecordDistanceKm = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMinRecordDistance, value);
  }

  Future<void> setAutoPause(bool value) async {
    _autoPause = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoPause, value);
  }

  Future<void> setDefaultGaugeSpeed(int value) async {
    _defaultGaugeSpeed = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultGaugeSpeed, value);
  }

  Future<void> setShowDistance(bool value) async {
    _showDistance = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowDistance, value);
  }

  Future<void> setShowDuration(bool value) async {
    _showDuration = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowDuration, value);
  }

  Future<void> setShowMaxSpeed(bool value) async {
    _showMaxSpeed = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowMaxSpeed, value);
  }

  Future<void> setShowAvgSpeed(bool value) async {
    _showAvgSpeed = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowAvgSpeed, value);
  }
}
