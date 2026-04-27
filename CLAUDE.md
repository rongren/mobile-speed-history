# CLAUDE.md

이 파일은 Claude Code(claude.ai/code)가 이 저장소에서 작업할 때 참고하는 가이드입니다.

## 작업 방침

- **CLAUDE.md 동기화**: 기능 추가·구조 변경 등 큰 작업을 마친 후 CLAUDE.md를 자동으로 업데이트해 현재 프로젝트 상태와 일치시킨다.
- **토큰 절약**: 파일은 필요한 부분만 읽고, 불필요한 전체 탐색은 피한다.
- **컨벤션/리팩토링 금지**: 명시적으로 요청받기 전까지 전체 코드를 훑어 컨벤션 정리나 리팩토링을 하지 않는다.

## 앱 개발 규칙

### 클릭 이벤트 시스템 음
모든 클릭/탭 이벤트에는 반드시 시스템 음을 출력한다.
```dart
SystemSound.play(SystemSoundType.click);
```
Flutter의 일부 위젯(예: `Switch`, `Checkbox`, `Radio`)은 자체적으로 시스템 음을 출력하므로 별도 처리가 필요 없다. 그 외 `GestureDetector`, `InkWell` 등 커스텀 탭 영역에는 반드시 명시적으로 추가한다.

### 플랫폼 대응
현재 Android 기반으로 개발 중이지만, 추후 iOS 지원을 목표로 한다. 플랫폼 분기가 필요한 경우 `Platform.isAndroid` / `Platform.isIOS`로 처리하고, Android 전용 API를 무분별하게 사용하지 않는다. (예: `LocationService`의 `AndroidSettings` / `AppleSettings` 분기 참고)

### 공통화·유틸화
억지로 묶지 않되, 동일한 로직이나 UI 패턴이 여러 곳에서 반복된다고 판단되면 `lib/utils/` 또는 `lib/widgets/`로 분리한다. 현재 공통 자산:
- `lib/utils/format_utils.dart` — 속도·거리·시간·숫자 포맷, 단위 변환, 칼로리 계산
- `lib/widgets/` — 재사용 위젯 모음

## 명령어

```bash
# 연결된 기기/에뮬레이터에서 실행
flutter run

# APK 빌드
flutter build apk --release

# 정적 분석 (lint)
flutter analyze

# 전체 테스트 실행
flutter test

# 단일 테스트 파일 실행
flutter test test/some_test.dart

# 런처 아이콘 재생성 (assets/icon/icon.png 변경 후)
dart run flutter_launcher_icons

# 스플래시 화면 재생성
dart run flutter_native_splash:create
```

## 아키텍처

Android를 주 타겟으로 하는 자전거 속도계 앱. 상태관리는 **Provider**, 로컬 저장소는 **sqflite**를 사용한다.

### 상태 레이어 — 두 개의 Provider

**`RideProvider`** (`lib/providers/ride_provider.dart`) — 앱의 핵심 런타임 상태 머신. GPS 스트림 구독, 200ms 보간 타이머, 거리 누적, 자동 일시정지 로직, 속도 알림 진동을 담당한다. `startRide()`로 스트림을 열고, `stopRide()`로 취소하고 DB에 기록을 저장한다. 최소 거리/시간 조건 미달 시 `null`을 반환하며 `stopFailReason`에 원인(`'distance'` 또는 `'duration'`)을 설정한다.

**`SettingsProvider`** (`lib/providers/settings_provider.dart`) — 모든 사용자 설정을 `SharedPreferences`로 영속화하는 래퍼. 앱 시작 시 `main()`에서 `settings.load()`를 호출한다. 각 setter는 `notifyListeners()` 후 즉시 `await prefs.set*()`으로 기록한다.

두 Provider는 `main.dart`의 루트 `MultiProvider`에서 제공된다.

### 내비게이션

`MainScreen`은 `IndexedStack` + `NavigationBar`로 구성된 탭 5개짜리 구조다: 속도계 → 지도 → 기록 → 목표 → 설정. `IndexedStack`이므로 탭 전환 시 서브트리가 유지된다(상태 초기화 없음).

### 데이터 레이어

`DatabaseHelper` (`lib/db/database_helper.dart`) — sqflite를 감싸는 싱글턴. DB 파일명 `bike_speedometer.db`, 버전 4. 테이블: `ride_records` (`id, year, month, day, totalDistance, maxSpeed, avgSpeed, duration, pathPoints(JSON), createdAt(ms epoch), memo`).

`RideRecord` (`lib/models/ride_record.dart`) — `toMap()`/`fromMap()`을 가진 불변 데이터 클래스.

GPS 경로 좌표는 `pathPoints` 컬럼에 `[{lat, lng}, ...]` 형태의 JSON 문자열로 저장된다.

### 서비스

- **`LocationService`** — `geolocator` 래퍼. 플랫폼별 설정(Android: `AndroidSettings`, iOS: `AppleSettings`)으로 `Stream<Position>`을 반환한다.
- **`ForegroundServiceHelper`** — `flutter_local_notifications`로 주행 중 상태 알림을 관리한다. 주행 시작 시 `start()`, 종료 시 `stop()` 호출.

### GPS 필터링 (`RideProvider._onPositionUpdate`)

GPS 업데이트마다 아래 세 필터를 순서대로 적용한다:
1. 정확도 게이트: `accuracy > 25m`이면 무시
2. 속도 급등 필터: 이전 속도 대비 3배 이상 급등하고 20 km/h 초과이면 무시
3. 드리프트 게이트: 이전 위치와의 거리가 3m 미만이면 거리 누적 안 함

화면에 표시되는 속도는 이전 GPS 속도와 새 속도 사이를 5단계로 선형 보간(200ms × 5 = 1초)하여 바늘이 부드럽게 움직이도록 한다.

### 테마

테마는 `SettingsProvider.appTheme`(`'dark'` 또는 `'light'`)으로 전적으로 제어된다. **`ThemeData` 교체 방식을 사용하지 않는다** — 모든 화면과 위젯이 `isDark = settings.appTheme == 'dark'`를 읽어 색상을 직접 계산한다. 새 UI 추가 시 이 패턴을 따라야 한다.

### 단위 변환

내부 값은 모두 **km/h**(속도), **km**(거리)로 저장·계산한다. `lib/utils/format_utils.dart`의 `formatSpeed`, `formatDistance`, `speedUnit`, `distanceUnit`, `convertSpeed`, `convertDistance`를 사용해 표시 시점에만 변환한다. 저장 시점에 변환하지 않는다.

### 네이버 지도

`flutter_naver_map`은 `main()`에서 클라이언트 ID `ua4rpblyze`로 초기화된다. 지도 타입(basic/satellite/hybrid)은 `SettingsProvider.mapType`에 저장된다.

### 주요 설계 제약

- 설정 화면의 `'백업 / 내보내기'` 타일은 플레이스홀더 — `onTap: null`로 의도적으로 비활성화되어 있다.
- `개발` 섹션(데이터 제거 / 데이터 생성)은 릴리즈 빌드에 그대로 남아있는 디버그 도구다.
- `wakelock_plus`로 주행 중 화면이 꺼지지 않도록 한다. `startRide()`에서 활성화, `stopRide()`에서 비활성화.
