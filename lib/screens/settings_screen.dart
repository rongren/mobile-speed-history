import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../db/database_helper.dart';
import '../db/sample_data.dart';
import '../providers/ride_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/number_input_dialog.dart';
import '../utils/backup_utils.dart';
import '../utils/gpx_utils.dart';
import '../widgets/loading_overlay.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _kAppName = '모바일 속도계';
  static const _kUpdateDate = '2026-04-29';
  static const _kDeveloperName = '김정훈';
  static const _kDeveloperEmail = 'kimjunghun816@gmail.com';

  bool _isDeleting = false;
  bool _isGenerating = false;
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isSharingExport = false;
  bool _isExportingGpx = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = info.version);
    }
  }

  void _showAppInfoDialog() {
    final cs = Theme.of(context).colorScheme;
    final textColor = cs.onSurface;
    final subColor = cs.onSurfaceVariant;
    final divColor = cs.outlineVariant;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.speed, color: Colors.blue, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                _kAppName,
                style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _appVersion.isEmpty ? '-' : 'v$_appVersion',
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Divider(color: divColor, height: 1),
              const SizedBox(height: 16),
              _infoRow('업데이트', _kUpdateDate, textColor, subColor),
              const SizedBox(height: 16),
              Divider(color: divColor, height: 1),
              const SizedBox(height: 16),
              _infoRow('개발자', _kDeveloperName, textColor, subColor),
              const SizedBox(height: 12),
              _infoRow('이메일', _kDeveloperEmail, textColor, subColor),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('닫기', style: TextStyle(color: subColor, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color textColor, Color subColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: subColor, fontSize: 13)),
        Text(value, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데이터 제거 확인'),
        content: const Text('모든 기록을 삭제합니다.\n되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    await DatabaseHelper.instance.deleteAllRecords();
    if (mounted) {
      await context.read<RideProvider>().loadRecords();
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 기록이 삭제되었습니다'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showBackupSheet() {
    final cs = Theme.of(context).colorScheme;
    final textColor = cs.onSurface;
    final subColor = cs.onSurfaceVariant;
    final panelColor = cs.surfaceContainerHighest;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainer,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 32 + MediaQuery.of(ctx).viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('백업 / 내보내기',
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _backupOptionTile(
              icon: Icons.share_outlined,
              color: Colors.orange,
              title: '공유하기',
              subtitle: '카카오톡·메일 등 앱으로 전송',
              textColor: textColor,
              subColor: subColor,
              panelColor: panelColor,
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _isSharingExport = true);
                try {
                  await shareBackup();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('공유 실패: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isSharingExport = false);
                }
              },
            ),
            const SizedBox(height: 10),
            _backupOptionTile(
              icon: Icons.upload_file,
              color: Colors.teal,
              title: '파일로 저장',
              subtitle: '기기 내 원하는 위치에 JSON 저장',
              textColor: textColor,
              subColor: subColor,
              panelColor: panelColor,
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _isExporting = true);
                try {
                  final saved = await exportBackup();
                  if (mounted && saved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('백업 파일이 저장되었습니다'),
                        backgroundColor: Colors.teal,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('내보내기 실패: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isExporting = false);
                }
              },
            ),
            const SizedBox(height: 10),
            _backupOptionTile(
              icon: Icons.download,
              color: Colors.blue,
              title: '가져오기',
              subtitle: '백업 파일에서 기록 복원 (중복 제외)',
              textColor: textColor,
              subColor: subColor,
              panelColor: panelColor,
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _isImporting = true);
                try {
                  final path = await pickBackupFile();
                  if (path == null) return;
                  if (!mounted) return;

                  final count = await runWithLoading<int>(
                    context,
                    label: '불러오는 중...',
                    task: (setProgress) =>
                        importFromPath(path, onProgress: setProgress),
                  );

                  if (!mounted) return;
                  await context.read<RideProvider>().loadRecords();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(count > 0
                          ? '$count건 복원되었습니다'
                          : '새로 추가된 기록이 없습니다'),
                      backgroundColor: count > 0 ? Colors.teal : Colors.grey,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('가져오기 실패: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isImporting = false);
                }
              },
            ),
            const SizedBox(height: 10),
            _backupOptionTile(
              icon: Icons.route,
              color: Colors.deepPurple,
              title: 'GPX 내보내기',
              subtitle: '전체 기록을 GPX 파일로 공유 (Strava 등 호환)',
              textColor: textColor,
              subColor: subColor,
              panelColor: panelColor,
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _isExportingGpx = true);
                try {
                  await shareAllGpx();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('GPX 내보내기 실패: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isExportingGpx = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _backupOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subColor,
    required Color panelColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: subColor, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데이터 생성 확인'),
        content: const Text('기존 기록을 모두 지우고 임시 데이터를 생성합니다.\n되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('생성', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isGenerating = true);
    await SampleDataHelper.insertSampleData();
    if (mounted) {
      await context.read<RideProvider>().loadRecords();
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('임시 데이터 생성 완료'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;

    final panelColor = cs.surfaceContainer;
    final titleColor = cs.onSurface;
    final subtitleColor = cs.onSurfaceVariant;
    final sectionColor = cs.outline;
    final btnBgOff = cs.surfaceContainerHighest;
    final btnBorderOff = cs.outlineVariant;
    final btnTextOff = cs.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('테마', sectionColor),
            _themeSelector(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
            const SizedBox(height: 24),

            _sectionTitle('주행', sectionColor),
            _toggleTile(
              icon: Icons.speed,
              iconColor: Colors.blue,
              title: '단위',
              subtitle: '속도/거리 표시 단위',
              leftLabel: 'km/h',
              rightLabel: 'mph',
              isLeft: settings.useKmh,
              onToggle: (v) => settings.setUseKmh(v),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              btnBorderOff: btnBorderOff,
              btnTextOff: btnTextOff,
            ),
            const SizedBox(height: 10),
            _toggleTile(
              icon: Icons.gps_fixed,
              iconColor: Colors.green,
              title: 'GPS 정확도',
              subtitle: '고정밀 모드는 배터리를 더 소모해요',
              leftLabel: '고정밀',
              rightLabel: '배터리 절약',
              isLeft: settings.gpsHighAccuracy,
              onToggle: (v) => settings.setGpsHighAccuracy(v),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              btnBorderOff: btnBorderOff,
              btnTextOff: btnTextOff,
            ),
            const SizedBox(height: 10),
            _minDistanceTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
            const SizedBox(height: 10),
            _minDurationTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
            const SizedBox(height: 10),
            _switchTile(
              icon: Icons.pause_circle_outline,
              iconColor: Colors.orange,
              title: '자동 일시정지',
              subtitle: '정지 감지 시 타이머 자동 일시정지',
              value: settings.autoPause,
              onChanged: (v) => settings.setAutoPause(v),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 10),
            _switchTile(
              icon: Icons.directions_run,
              iconColor: Colors.deepOrange,
              title: '저속 모드',
              subtitle: '런닝·워킹용 — 느린 이동도 거리로 정확하게 측정',
              value: settings.lowSpeedMode,
              onChanged: (v) => settings.setLowSpeedMode(v),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 10),
            _speedAlertTile(settings, panelColor, titleColor, subtitleColor, btnBgOff),
            const SizedBox(height: 24),

            _sectionTitle('주행 화면', sectionColor),
            _gaugeSpeedTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
            const SizedBox(height: 10),
            _displayItemsTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
            const SizedBox(height: 10),
            _weightTile(settings, panelColor, titleColor, subtitleColor, btnBgOff),
            const SizedBox(height: 24),

            _sectionTitle('지도', sectionColor),
            _mapTypeTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
            const SizedBox(height: 24),

            _sectionTitle('데이터', sectionColor),
            _settingTile(
              icon: Icons.upload_file,
              iconColor: Colors.teal,
              title: '백업 / 내보내기',
              subtitle: '주행 기록을 파일로 저장 · 복원',
              onTap: () => _showBackupSheet(),
              isLoading: _isExporting || _isImporting || _isSharingExport || _isExportingGpx,
              loadingColor: Colors.teal,
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 24),

            _sectionTitle('앱 정보', sectionColor),
            _settingTile(
              icon: Icons.info_outline,
              iconColor: Colors.grey,
              title: '앱 정보',
              subtitle: _appVersion.isEmpty ? _kAppName : '$_kAppName  v$_appVersion',
              onTap: () => _showAppInfoDialog(),
              isLoading: false,
              loadingColor: Colors.grey,
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 24),

            if (kDebugMode) ...[
              _sectionTitle('개발', sectionColor),
              _settingTile(
                icon: Icons.delete_outline,
                iconColor: Colors.red,
                title: '데이터 제거',
                subtitle: '전체 기록 삭제',
                onTap: (_isDeleting || _isGenerating) ? null : _deleteAllData,
                isLoading: _isDeleting,
                loadingColor: Colors.red,
                panelColor: panelColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
              ),
              const SizedBox(height: 10),
              _settingTile(
                icon: Icons.add_chart,
                iconColor: Colors.blue,
                title: '데이터 생성',
                subtitle: '임시 샘플 데이터 삽입',
                onTap: (_isDeleting || _isGenerating) ? null : _generateSampleData,
                isLoading: _isGenerating,
                loadingColor: Colors.blue,
                panelColor: panelColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _gaugeSpeedTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    const speeds = [60, 120, 180, 240];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.speed, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('게이지 최대속도 기본값',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('속도계 실행 시 기본 최대 눈금',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: speeds.map((s) {
              final isSelected = settings.defaultGaugeSpeed == s;
              final isLast = s == speeds.last;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setDefaultGaugeSpeed(s);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: isLast ? 0 : 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : btnBorderOff,
                      ),
                    ),
                    child: Text(
                      '$s',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : btnTextOff,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _displayItemsTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    final items = [
      ('거리', settings.showDistance, settings.setShowDistance),
      ('시간', settings.showDuration, settings.setShowDuration),
      ('최고속도', settings.showMaxSpeed, settings.setShowMaxSpeed),
      ('평균속도', settings.showAvgSpeed, settings.setShowAvgSpeed),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dashboard_outlined,
                    color: Colors.indigo, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('주행 중 표시 항목',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('속도계 하단에 표시할 통계 선택',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final (label, isOn, setter) = e.value;
              final isLast = i == items.length - 1;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    setter(!isOn);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: isLast ? 0 : 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isOn ? Colors.indigo.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOn ? Colors.indigo : btnBorderOff,
                      ),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isOn ? Colors.indigo : btnTextOff,
                        fontSize: 12,
                        fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _weightTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_outline,
                    color: Colors.pink, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('체중',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('칼로리 추정에 사용됩니다',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  SystemSound.play(SystemSoundType.click);
                  settings.setWeightKg((settings.weightKg ?? 70) - 1);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: btnBgOff,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.remove, color: titleColor, size: 20),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () async {
                  SystemSound.play(SystemSoundType.click);
                  final result = await NumberInputDialog.show(
                    context,
                    title: '체중 입력',
                    initialValue: settings.weightKg,
                    unit: 'kg',
                    maxDigits: 3,
                    allowEmpty: true,
                    allowDecimal: true,
                  );
                  if (result == null) return;
                  if (result == NumberInputDialog.clearValue) {
                    settings.setWeightKg(null);
                  } else {
                    settings.setWeightKg(result.toDouble());
                  }
                },
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: btnBgOff,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    settings.weightKg != null
                        ? '${settings.weightKg!.toInt()} kg'
                        : '--',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: settings.weightKg != null ? titleColor : subtitleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  SystemSound.play(SystemSoundType.click);
                  settings.setWeightKg((settings.weightKg ?? 70) + 1);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: btnBgOff,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, color: titleColor, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String leftLabel,
    required String rightLabel,
    required bool isLeft,
    required void Function(bool) onToggle,
    required Color panelColor,
    required Color titleColor,
    required Color subtitleColor,
    required Color btnBgOff,
    required Color btnBorderOff,
    required Color btnTextOff,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _twoStateButton(leftLabel, isLeft, () => onToggle(true),
                    btnBgOff: btnBgOff, btnBorderOff: btnBorderOff, btnTextOff: btnTextOff),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _twoStateButton(rightLabel, !isLeft, () => onToggle(false),
                    btnBgOff: btnBgOff, btnBorderOff: btnBorderOff, btnTextOff: btnTextOff),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _twoStateButton(String label, bool isSelected, VoidCallback onTap, {
    required Color btnBgOff,
    required Color btnBorderOff,
    required Color btnTextOff,
  }) {
    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.15) : btnBgOff,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : btnBorderOff,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.blue : btnTextOff,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _minDistanceTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    const options = [0.0, 0.1, 0.5, 1.0];
    const labels = ['없음', '0.1 km', '0.5 km', '1.0 km'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.straighten, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('최소 기록 거리',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('미달 시 주행 종료 후 저장 안 됨',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(options.length, (i) {
              final isSelected = settings.minRecordDistanceKm == options[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setMinRecordDistanceKm(options[i]);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : btnBorderOff,
                      ),
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : btnTextOff,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _minDurationTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    const options = [0, 60, 180, 300, 600];
    const labels = ['없음', '1분', '3분', '5분', '10분'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timer_outlined, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('최소 기록 시간',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('미달 시 주행 종료 후 저장 안 됨',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(options.length, (i) {
              final isSelected = settings.minRecordDurationSec == options[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setMinRecordDurationSec(options[i]);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.teal : btnBorderOff,
                      ),
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.teal : btnTextOff,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _speedAlertTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff) {
    final inactiveTrackColor = Theme.of(context).colorScheme.outlineVariant;
    final isOn = settings.speedAlertKmh != null;
    final currentKmh = settings.speedAlertKmh?.toInt() ?? 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_outlined,
                    color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('속도 알림',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('설정 속도 초과 시 진동 알림',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: isOn,
                onChanged: (v) {
                  SystemSound.play(SystemSoundType.click);
                  if (v) {
                    settings.setSpeedAlertKmh(currentKmh.toDouble());
                  } else {
                    settings.setSpeedAlertKmh(null);
                  }
                },
                activeThumbColor: Colors.amber,
                activeTrackColor: Colors.amber.withOpacity(0.4),
                inactiveTrackColor: inactiveTrackColor,
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    final next = (currentKmh - 5).clamp(kDebugMode ? 0 : 1, 999);
                    settings.setSpeedAlertKmh(next.toDouble());
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.remove, color: titleColor, size: 20),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () async {
                    SystemSound.play(SystemSoundType.click);
                    final result = await NumberInputDialog.show(
                      context,
                      title: '속도 알림 기준',
                      initialValue: settings.speedAlertKmh,
                      unit: 'km/h',
                      maxDigits: 3,
                      allowEmpty: false,
                      allowDecimal: false,
                    );
                    if (result == null) return;
                    settings.setSpeedAlertKmh(result.toDouble());
                  },
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$currentKmh km/h',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    final next = (currentKmh + 5).clamp(kDebugMode ? 0 : 1, 999);
                    settings.setSpeedAlertKmh(next.toDouble());
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add, color: titleColor, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _mapTypeTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    const options = ['basic', 'satellite', 'hybrid'];
    const labels = ['기본', '위성', '하이브리드'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.map_outlined, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('지도 스타일',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('주행 지도 및 경로 지도에 적용',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(options.length, (i) {
              final isSelected = settings.mapType == options[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setMapType(options[i]);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.green : btnBorderOff,
                      ),
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.green : btnTextOff,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
    required Color panelColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final inactiveTrackColor = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(color: subtitleColor, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              SystemSound.play(SystemSoundType.click);
              onChanged(v);
            },
            activeThumbColor: Colors.blue,
            activeTrackColor: Colors.blue.withOpacity(0.4),
            inactiveTrackColor: inactiveTrackColor,
          ),
        ],
      ),
    );
  }

  Widget _themeSelector(SettingsProvider settings,
      Color panelColor, Color titleColor, Color subtitleColor,
      Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.palette_outlined,
                    color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('테마',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('속도계 화면 색상 테마',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _themeButton(settings, 'dark', Icons.dark_mode_outlined, 'Dark',
                      btnBgOff: btnBgOff, btnBorderOff: btnBorderOff, btnTextOff: btnTextOff)),
              const SizedBox(width: 6),
              Expanded(
                  child: _themeButton(settings, 'light', Icons.light_mode_outlined, 'Light',
                      btnBgOff: btnBgOff, btnBorderOff: btnBorderOff, btnTextOff: btnTextOff)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _themeButton(SettingsProvider settings, String theme, IconData icon, String label, {
    required Color btnBgOff,
    required Color btnBorderOff,
    required Color btnTextOff,
  }) {
    final isSelected = settings.appTheme == theme;
    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        settings.setAppTheme(theme);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.15) : btnBgOff,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : btnBorderOff,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.blue : btnTextOff, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : btnTextOff,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required bool isLoading,
    required Color loadingColor,
    required Color panelColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return GestureDetector(
      onTap: onTap == null ? null : () {
        SystemSound.play(SystemSoundType.click);
        onTap();
      },
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: loadingColor,
                      ),
                    )
                  : const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
