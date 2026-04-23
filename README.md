# speed_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

모바일 속도계 Flutter 앱
앱 개요
자전거 주행 기록 앱. GPS로 속도/거리/시간을 측정하고 네이버 지도로 경로를 표시하며 주행 기록을 로컬 DB에 저장한다.
기술 스택

Framework: Flutter
지도: flutter_naver_map
GPS: geolocator
로컬 DB: sqflite
상태관리: provider
알림: flutter_local_notifications
달력: table_calendar
언어 설정: intl

화면 구성 (바텀 네비게이션 5개)
1. 속도계 (speedometer_screen.dart)

자동차 속도계 스타일 CustomPainter 원형 게이지
상단 최고속도 범위 선택 (60 / 120 / 180 / 240 km/h)
속도에 따라 호 색상 변경 (파랑 → 초록 → 주황 → 빨강)
하단 거리 / 시간 / 최고속도 통계
시작 / 정지 버튼
시작 시 알림창에 측정 중 표시, 종료 시 알림 제거
백그라운드/잠금 상태에서도 시간 정확히 측정 (시작시간 기준 계산)
속도 보간 처리 (0.2초마다 부드럽게 변화)

2. 지도 (map_screen.dart)

네이버 지도
앱 진입 시 현재 위치로 자동 이동 (애니메이션 없음)
내 위치 오버레이 표시
주행 중 실시간 경로 파란 선으로 표시
하단 거리 / 시간 / 최고속도 실시간 표시
IndexedStack 으로 탭 전환 시 상태 유지

3. 기록 (history/history_screen.dart)
탭 6개로 구성
평균 (history_average_screen.dart)

1회 평균 (거리, 시간, 최고속도, 평균속도)
전체 누적 (총 횟수, 총 거리, 총 시간, 최고속도)

연도별 (history_yearly_screen.dart)

막대 그래프 (거리/시간/최고속도/평균속도 선택)
막대 탭하면 해당 연도 상세 (요약 카드 + 월별 breakdown)
그래프 평균선 표시 (주황 점선)
다시 탭하면 상세 숨김

월별 (history_monthly_screen.dart)

막대 그래프
막대 탭하면 해당 월 상세 (요약 카드 + 달력 히트맵 + 주차별 통계)
히트맵: 많이 탄 날일수록 진한 파란색

일별 (history_daily_screen.dart)

상단 기간 필터 (전체/7일/30일/90일/180일/365일) — 오렌지 스타일
안 탄 날도 그래프에 표시 (빈 막대)
막대 탭하면 해당 날 상세 (요약 카드 + 회차별 목록)
하단 요일별 평균 거리 막대 (접기/펼치기)
회차별 목록에서 경로 보기 가능

상세 (history_detail_screen.dart)

날짜 선택 (이전/다음 화살표, 셀렉트박스, 달력)
달력에 기록 있는 날 주황색 점 표시 (table_calendar)
해당 날짜 주행 목록 표시
각 기록 탭하면 지도에서 경로 확인

전체 (history_total_screen.dart)

연/월/일 필터 (선택 안 해도 됨, 우측 초기화 버튼)
정렬 기능 (날짜/거리/속도 오름차순·내림차순)
각 기록에 경로 보기 버튼
기록 삭제 기능 (- 버튼으로 삭제 준비, 음영 처리, 하단 삭제/취소 버튼)
최고 기록 뱃지 (최장거리/최고속도/최장시간)

4. 목표 (goal_screen.dart)

미구현 (추후 월 목표 거리 설정 예정)

5. 설정 (settings_screen.dart)

미구현 (추후 테마 설정 등 예정)

데이터 구조 (ride_record.dart)
ride_records
├── id (자동증가)
├── year
├── month
├── day
├── totalDistance (km)
├── maxSpeed (km/h)
├── avgSpeed (km/h)
├── duration (초)
├── pathPoints (경로 JSON)
└── createdAt (timestamp)
공통 위젯

bar_chart_widget.dart — 가로 스크롤 막대 그래프 (CustomPainter, 보이는 영역 기준 최대값, 애니메이션, 평균선, 선택 강조)
record_badges.dart — 최고 기록 뱃지 (최장거리/최고속도/최장시간)

기타

뒤로가기 2번 누르면 앱 종료
앱 시작 시 위치 권한 → 알림 권한 순서로 요청
한글 로케일 설정
스플래시 화면 (검정 배경 + 속도계 아이콘)
앱 아이콘 (속도계 모양)
앱 이름: 모바일 속도계
DB 버전 관리로 스키마 변경 시 자동 마이그레이션
