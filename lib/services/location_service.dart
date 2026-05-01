import 'dart:io';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Stream<Position> getPositionStream({bool highAccuracy = true}) {
    final accuracy =
        highAccuracy ? LocationAccuracy.high : LocationAccuracy.low;
    if (Platform.isAndroid) {
      return Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: accuracy,
          intervalDuration: const Duration(milliseconds: 1000),
          distanceFilter: 0,
          forceLocationManager: true,
        ),
      );
    } else {
      return Geolocator.getPositionStream(
        locationSettings: AppleSettings(
          accuracy: accuracy,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
          activityType: ActivityType.fitness,
        ),
      );
    }
  }

  static double calculateDistance(Position p1, Position p2) {
    return Geolocator.distanceBetween(
      p1.latitude, p1.longitude,
      p2.latitude, p2.longitude,
    );
  }
}