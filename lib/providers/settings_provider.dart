import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyUseKmh = 'use_kmh';
  static const _keyGpsHighAccuracy = 'gps_high_accuracy';
  static const _keyMinRecordDistance = 'min_record_distance';
  static const _keyAutoPause = 'auto_pause';

  bool _useKmh = true;
  bool _gpsHighAccuracy = true;
  double _minRecordDistanceKm = 0.1;
  bool _autoPause = false;

  bool get useKmh => _useKmh;
  bool get gpsHighAccuracy => _gpsHighAccuracy;
  double get minRecordDistanceKm => _minRecordDistanceKm;
  bool get autoPause => _autoPause;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _useKmh = prefs.getBool(_keyUseKmh) ?? true;
    _gpsHighAccuracy = prefs.getBool(_keyGpsHighAccuracy) ?? true;
    _minRecordDistanceKm = prefs.getDouble(_keyMinRecordDistance) ?? 0.1;
    _autoPause = prefs.getBool(_keyAutoPause) ?? false;
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
}
