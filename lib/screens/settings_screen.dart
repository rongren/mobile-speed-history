import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../db/database_helper.dart';
import '../db/sample_data.dart';
import '../providers/ride_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/number_input_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDeleting = false;
  bool _isGenerating = false;
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

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e1e),
        title: const Text('데이터 제거 확인',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          '모든 기록을 삭제합니다.\n되돌릴 수 없어요.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
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

  Future<void> _generateSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e1e),
        title: const Text('데이터 생성 확인',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          '기존 기록을 모두 지우고 임시 데이터를 생성합니다.\n되돌릴 수 없어요.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
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
    final isDark = settings.appTheme == 'dark';

    final bgColor = isDark ? Colors.black : const Color(0xFFF2F4F7);
    final panelColor = isDark ? Colors.grey[900]! : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey : Colors.grey[600]!;
    final sectionColor = isDark ? Colors.grey : Colors.grey[500]!;
    final btnBgOff = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final btnBorderOff = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final btnTextOff = isDark ? Colors.grey : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('테마', sectionColor),
            _themeSelector(settings, isDark, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
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
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _speedAlertTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, isDark),
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
              subtitle: '주행 기록을 파일로 저장',
              onTap: null,
              isLoading: false,
              loadingColor: Colors.teal,
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 24),

            _sectionTitle('앱 정보', sectionColor),
            _infoTile(
              icon: Icons.info_outline,
              iconColor: Colors.grey,
              title: '버전',
              value: _appVersion.isEmpty ? '-' : 'v$_appVersion',
              panelColor: panelColor,
              titleColor: titleColor,
            ),
            const SizedBox(height: 24),

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
                  onTap: () => settings.setDefaultGaugeSpeed(s),
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
                  onTap: () => setter(!isOn),
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
                onTap: () => settings.setWeightKg((settings.weightKg ?? 70) - 1),
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
                  final result = await NumberInputDialog.show(
                    context,
                    title: '체중 입력',
                    initialValue: settings.weightKg?.toInt(),
                    unit: 'kg',
                    maxDigits: 3,
                    allowEmpty: true,
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
                onTap: () => settings.setWeightKg((settings.weightKg ?? 70) + 1),
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
      onTap: onTap,
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
                  onTap: () => settings.setMinRecordDistanceKm(options[i]),
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
                  onTap: () => settings.setMinRecordDurationSec(options[i]),
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
      Color titleColor, Color subtitleColor, Color btnBgOff, bool isDark) {
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
                  if (v) {
                    settings.setSpeedAlertKmh(currentKmh.toDouble());
                  } else {
                    settings.setSpeedAlertKmh(null);
                  }
                },
                activeThumbColor: Colors.amber,
                activeTrackColor: Colors.amber.withOpacity(0.4),
                inactiveTrackColor: isDark ? Colors.grey[700] : Colors.grey[300],
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
                    final next = (currentKmh - 5).clamp(1, 999);
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
                    final result = await NumberInputDialog.show(
                      context,
                      title: '속도 알림 기준',
                      initialValue: currentKmh,
                      unit: 'km/h',
                      maxDigits: 3,
                      allowEmpty: false,
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
                    final next = (currentKmh + 5).clamp(1, 999);
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
                  onTap: () => settings.setMapType(options[i]),
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
    required bool isDark,
  }) {
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
            onChanged: onChanged,
            activeThumbColor: Colors.blue,
            activeTrackColor: Colors.blue.withOpacity(0.4),
            inactiveTrackColor: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color panelColor,
    required Color titleColor,
  }) {
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
            child: Text(title,
                style: TextStyle(
                    color: titleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          Text(value,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _themeSelector(SettingsProvider settings, bool isDark,
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
      onTap: () => settings.setAppTheme(theme),
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
      onTap: onTap,
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
