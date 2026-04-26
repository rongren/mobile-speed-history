import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyUseKmh = 'use_kmh';
  static const _keyGpsHighAccuracy = 'gps_high_accuracy';
  static const _keyMinRecordDistance = 'min_record_distance';
  static const _keyAutoPause = 'auto_pause';
  static const _keyDefaultGaugeSpeed = 'default_gauge_speed';
  static const _keyWeightKg = 'weight_kg';
  static const _keyShowDistance = 'show_distance';
  static const _keyShowDuration = 'show_duration';
  static const _keyShowMaxSpeed = 'show_max_speed';
  static const _keyShowAvgSpeed = 'show_avg_speed';
  static const _keyAppTheme = 'app_theme';
  static const _keyMinRecordDuration = 'min_record_duration';
  static const _keySpeedAlertKmh = 'speed_alert_kmh';
  static const _keyMapType = 'map_type';

  bool _useKmh = true;
  bool _gpsHighAccuracy = true;
  double _minRecordDistanceKm = 0.1;
  bool _autoPause = false;
  int _defaultGaugeSpeed = 60;
  double? _weightKg;
  bool _showDistance = true;
  bool _showDuration = true;
  bool _showMaxSpeed = true;
  bool _showAvgSpeed = true;
  String _appTheme = 'dark';
  int _minRecordDurationSec = 0;
  double? _speedAlertKmh;
  String _mapType = 'basic';

  bool get useKmh => _useKmh;
  bool get gpsHighAccuracy => _gpsHighAccuracy;
  double get minRecordDistanceKm => _minRecordDistanceKm;
  bool get autoPause => _autoPause;
  int get defaultGaugeSpeed => _defaultGaugeSpeed;
  double? get weightKg => _weightKg;
  bool get showDistance => _showDistance;
  bool get showDuration => _showDuration;
  bool get showMaxSpeed => _showMaxSpeed;
  bool get showAvgSpeed => _showAvgSpeed;
  String get appTheme => _appTheme;
  int get minRecordDurationSec => _minRecordDurationSec;
  double? get speedAlertKmh => _speedAlertKmh;
  String get mapType => _mapType;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _useKmh = prefs.getBool(_keyUseKmh) ?? true;
    _gpsHighAccuracy = prefs.getBool(_keyGpsHighAccuracy) ?? true;
    _minRecordDistanceKm = prefs.getDouble(_keyMinRecordDistance) ?? 0.1;
    _autoPause = prefs.getBool(_keyAutoPause) ?? false;
    _defaultGaugeSpeed = prefs.getInt(_keyDefaultGaugeSpeed) ?? 60;
    _weightKg = prefs.getDouble(_keyWeightKg);
    _showDistance = prefs.getBool(_keyShowDistance) ?? true;
    _showDuration = prefs.getBool(_keyShowDuration) ?? true;
    _showMaxSpeed = prefs.getBool(_keyShowMaxSpeed) ?? true;
    _showAvgSpeed = prefs.getBool(_keyShowAvgSpeed) ?? true;
    _appTheme = prefs.getString(_keyAppTheme) ?? 'dark';
    _minRecordDurationSec = prefs.getInt(_keyMinRecordDuration) ?? 0;
    _speedAlertKmh = prefs.getDouble(_keySpeedAlertKmh);
    _mapType = prefs.getString(_keyMapType) ?? 'basic';
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

  Future<void> setWeightKg(double? value) async {
    _weightKg = value != null ? value.clamp(1.0, 999.0) : null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_weightKg != null) {
      await prefs.setDouble(_keyWeightKg, _weightKg!);
    } else {
      await prefs.remove(_keyWeightKg);
    }
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

  Future<void> setAppTheme(String value) async {
    _appTheme = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppTheme, value);
  }

  Future<void> setMinRecordDurationSec(int value) async {
    _minRecordDurationSec = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMinRecordDuration, value);
  }

  Future<void> setSpeedAlertKmh(double? value) async {
    _speedAlertKmh = value != null ? value.clamp(1.0, 999.0) : null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_speedAlertKmh != null) {
      await prefs.setDouble(_keySpeedAlertKmh, _speedAlertKmh!);
    } else {
      await prefs.remove(_keySpeedAlertKmh);
    }
  }

  Future<void> setMapType(String value) async {
    _mapType = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMapType, value);
  }
}
