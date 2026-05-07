import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 포그라운드 서비스 진입점 — 별도 isolate에서 실행됨
@pragma('vm:entry-point')
void _foregroundEntryPoint() {
  FlutterForegroundTask.setTaskHandler(_RideTaskHandler());
}

// 서비스 keepalive 역할만 수행하는 최소 핸들러
class _RideTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

class ForegroundServiceHelper {
  // 거리 알림 전용 (flutter_local_notifications)
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initNotifications() async {
    // 거리 알림 채널 초기화
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: darwinSettings),
    );

    final android = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.deleteNotificationChannel('bike_speedometer');
    await android?.deleteNotificationChannel('bike_speedometer_ride');

    // Android 포그라운드 서비스 초기화
    if (Platform.isAndroid) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'bike_speedometer_fg',
          channelName: '모바일 속도계',
          channelDescription: '주행 중 백그라운드 GPS 유지',
          channelImportance: NotificationChannelImportance.HIGH,
          priority: NotificationPriority.HIGH,
          enableVibration: false,
          playSound: false,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
          autoRunOnBoot: false,
          allowAutoRestart: false,
          allowWakeLock: true,
          allowWifiLock: false,
        ),
      );
    }
  }

  static Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      // 배터리 최적화 예외 요청 — 없으면 Doze 모드에서 서비스가 제한될 수 있음
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<bool> isAllowed() async {
    if (Platform.isAndroid) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return result ?? false;
    }
    return true;
  }

  static Future<void> start() async {
    if (Platform.isAndroid) {
      await FlutterForegroundTask.startService(
        serviceId: 1000,
        notificationTitle: '🚴 모바일 속도계',
        notificationText: '측정 중...',
        callback: _foregroundEntryPoint,
      );
    } else {
      // iOS: 백그라운드 위치는 Info.plist UIBackgroundModes + geolocator 설정으로 동작
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );
      await _notifications.show(
        1000,
        '🚴 모바일 속도계',
        '측정 중...',
        const NotificationDetails(iOS: darwinDetails),
      );
    }
  }

  static Future<void> stop() async {
    if (Platform.isAndroid) {
      await FlutterForegroundTask.stopService();
    } else {
      try {
        await _notifications.cancel(1000);
      } catch (_) {}
    }
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
    await _notifications.show(
      2000,
      '📍 $km km 달성!',
      '목표 거리에 도달했어요. 계속 달리세요!',
      details,
    );
  }
}
