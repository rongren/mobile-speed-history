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
- `lib/widgets/number_input_dialog.dart` — 숫자 키패드 입력 다이얼로그. `allowDecimal: true`로 소수점 입력 활성화 가능. 반환 타입 `double?`, 빈 확인 시 `clearValue(-1)` 반환
- `lib/widgets/memo_bottom_sheet.dart` — 메모 입력 바텀시트. `showMemoBottomSheet(context, controller: ctrl, isDark: isDark)` 호출. 완료 시 `controller.text`에 값이 쓰여 반환되므로 호출 후 직접 읽으면 된다.
- `lib/widgets/stat_item.dart` — 통계 표시 위젯 2종:
  - `StatDetailItem(label, value, unit, textColor)` — 값(16px 굵게) + 단위(파란색, 선택) + 라벨(회색 11px). 주행 상세/요약 행에 사용.
  - `StatItem(label, value, textColor, {labelBlue})` — 값(13px 굵게) + 라벨(기본 회색, `labelBlue: true`이면 파란색). 목록 카드 내 통계 행에 사용.
- `lib/utils/backup_utils.dart` — 백업/복원 유틸. `shareBackup()` : 임시 파일 생성 후 공유 시트 표시. `exportBackup()` : `FilePicker.saveFile(bytes:)`로 저장 위치 선택 → `true`=저장완료/`false`=취소. `pickBackupFile()` : 파일 선택 다이얼로그만 표시 → 선택한 경로 반환 (`null`=취소). `importFromPath(path, {onProgress})` : 경로에서 파싱·삽입 → 새로 추가된 건수 반환. 진행률 콜백은 0.0~1.0 범위. 가져오기 후 반드시 `ride.loadRecords()` 호출로 Provider 갱신.
- `lib/widgets/loading_overlay.dart` — 전화면 터치 차단 로딩 오버레이. `runWithLoading<T>(context, task: (setProgress) async { ... }, label: '...')` 호출. `setProgress(0.0~1.0)` 전달 시 진행률 바 표시, `null` 전달 시 무한 스피너. `AbsorbPointer`로 오버레이 뒤 모든 터치 차단.
- `lib/widgets/` — 재사용 위젯 모음

### 시스템 네비게이션 바 패딩
Android 제스처 내비게이션 또는 버튼 내비게이션 바가 화면 하단을 가린다. `showModalBottomSheet`를 사용할 때는 반드시 아래 두 가지를 적용한다:
1. `useSafeArea: true` — 네비게이션 바 영역을 자동으로 피함
2. 컨텐츠 하단 패딩에 `MediaQuery.of(ctx).viewPadding.bottom` 추가 — 내부 여백도 네비게이션 바 높이만큼 확보

키보드 대응(`viewInsets.bottom`)과 네비게이션 바 대응(`viewPadding.bottom`)은 별개다. 키보드가 올라올 때 잘리는 경우는 `viewInsets.bottom`, 네비게이션 바에 잘리는 경우는 `viewPadding.bottom`을 사용한다.

```dart
showModalBottomSheet(
  useSafeArea: true,
  isScrollControlled: true, // 키보드 대응 시 필요
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), // 키보드
    child: Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).viewPadding.bottom), // 네비게이션 바
    ),
  ),
);
```

### 색상 인덱스 주의
`Colors.grey`의 유효 인덱스는 50·100·200·300·400·500·600·700·800·**850**·**900**까지다. `Colors.grey[950]` 등 존재하지 않는 인덱스는 `null`을 반환하므로 `!` 연산자와 함께 쓰면 런타임 에러가 발생한다.

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

**`SettingsProvider`** (`lib/providers/settings_provider.dart`) — 모든 사용자 설정을 `SharedPreferences`로 영속화하는 래퍼. 앱 시작 시 `main()`에서 `settings.load()`를 호출한다. 각 setter는 `notifyListeners()` 후 즉시 `await prefs.set*()`으로 기록한다. 목표 관련 설정(`yearlyGoalKm`, `monthlyGoalKm`, `goalMaxSpeedKmh`, `goalMaxDistanceKm`, `goalMaxDurationMin`)도 이 Provider에서 관리한다.

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

### 목표 화면 (`GoalScreen`)

`RideProvider.records`와 `SettingsProvider` 목표값만으로 동작하며 별도 DB 없음. 구성:
- **거리 목표** (올해/이번달) — 진행률 바, 달성 시 초록 체크. 목표값은 내부적으로 km 저장, 표시는 useKmh 단위 변환
- **도전 목표** (최고속도/최장거리/최장시간) — 현재 기록 대비 목표 표시. 최장시간은 분 단위 입력, 초 단위 저장
- **스트릭** — 설정 없음. records 날짜로 현재 연속일·역대 최장 계산. 오늘 또는 어제 주행이 있으면 스트릭 유지

### 주요 설계 제약

- 설정 화면의 `'백업 / 내보내기'` 타일은 플레이스홀더 — `onTap: null`로 의도적으로 비활성화되어 있다.
- `개발` 섹션(데이터 제거 / 데이터 생성)은 릴리즈 빌드에 그대로 남아있는 디버그 도구다.
- `wakelock_plus`로 주행 중 화면이 꺼지지 않도록 한다. `startRide()`에서 활성화, `stopRide()`에서 비활성화.
