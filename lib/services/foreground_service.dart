import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ForegroundServiceHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _plugin.initialize(initSettings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.deleteNotificationChannel('bike_speedometer');
    await android?.deleteNotificationChannel('bike_speedometer_ride');
  }

  static Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<bool> isAllowed() async {
    if (Platform.isAndroid) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return result ?? false;
    } else if (Platform.isIOS) {
      // iOS는 requestPermissions 호출로 런타임에서 권한 요청
      return true;
    }
    return false;
  }

  static Future<void> start() async {
    final NotificationDetails details;
    if (Platform.isAndroid) {
      final androidDetails = AndroidNotificationDetails(
        'bike_speedometer_ride',
        '모바일 속도계',
        channelDescription: '주행 시작 및 측정 중 상태',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300]),
      );
      details = NotificationDetails(android: androidDetails);
    } else {
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );
      details = const NotificationDetails(iOS: darwinDetails);
    }
    await _plugin.show(1000, '🚴 모바일 속도계', '측정 중...', details);
  }

  static Future<void> stop() async {
    try {
      await _plugin.cancel(1000);
    } catch (_) {}
  }

  static Future<void> showDistanceAlert(int km) async {
    final NotificationDetails details;
    if (Platform.isAndroid) {
      final androidDetails = AndroidNotificationDetails(
        'distance_alert',
        '거리 알림',
        channelDescription: '설정 거리 도달 시 알림',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
      );
      details = NotificationDetails(android: androidDetails);
    } else {
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );
      details = const NotificationDetails(iOS: darwinDetails);
    }
    await _plugin.show(
      2000,
      '📍 $km km 달성!',
      '목표 거리에 도달했어요. 계속 달리세요!',
      details,
    );
  }
}
