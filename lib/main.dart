import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/ride_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/speedometer_screen.dart';
import 'screens/map_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/goal_screen.dart';
import 'screens/settings_screen.dart';
import 'services/foreground_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  // 알림 초기화
  await ForegroundServiceHelper.initNotifications();

  // 네이버 지도 초기화
  await FlutterNaverMap().init(
      clientId: 'ua4rpblyze',
      onAuthFailed: (ex) {
        switch (ex) {
          case NQuotaExceededException(:final message):
            print("사용량 초과 (message: $message)");
            break;
          case NUnauthorizedClientException() ||
          NClientUnspecifiedException() ||
          NAnotherAuthFailedException():
            print("인증 실패: $ex");
            break;
        }
      });

  final settings = SettingsProvider();
  await settings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settings),
        ChangeNotifierProvider(create: (_) => RideProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // 1. 위치 권한
    LocationPermission locationPermission =
    await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }

    // 2. 알림 권한
    final isAllowed = await ForegroundServiceHelper.isAllowed();
    if (!isAllowed) {
      await ForegroundServiceHelper.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '모바일 속도계',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.black,
          indicatorColor: Colors.blue.withOpacity(0.2),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.blue);
            }
            return const IconThemeData(color: Colors.grey);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: Colors.blue, fontSize: 12);
            }
            return const TextStyle(color: Colors.grey, fontSize: 12);
          }),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) >
                const Duration(seconds: 2)) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('한 번 더 누르면 종료됩니다'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.grey,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            SpeedometerScreen(),
            MapScreen(),
            HistoryScreen(),
            GoalScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.black,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.speed),
              label: '속도계',
            ),
            NavigationDestination(
              icon: Icon(Icons.map),
              label: '지도',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              label: '기록',
            ),
            NavigationDestination(
              icon: Icon(Icons.flag),
              label: '목표',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }
}