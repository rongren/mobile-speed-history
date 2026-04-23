import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ForegroundServiceHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initNotifications() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings =
    InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
    AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<bool> isAllowed() async {
    final result = await _plugin
        .resolvePlatformSpecificImplementation<
    AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return result ?? false;
  }

  static Future<void> start() async {
    const androidDetails = AndroidNotificationDetails(
      'bike_speedometer',
      '자전거 속도계',
      channelDescription: '주행 중 상태를 표시합니다',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      1000,
      '🚴 모바일 속도계',
      '측정 중...',
      details,
    );
  }

  static Future<void> stop() async {
    await _plugin.cancel(1000);
  }
}