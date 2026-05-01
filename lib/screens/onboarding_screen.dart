import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _PageData {
  final IconData icon;
  final String title;
  final String description;

  const _PageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  bool _neverShowAgain = true;

  static const _pages = [
    _PageData(
      icon: Icons.speed,
      title: '실시간 속도계',
      description: 'GPS로 현재 속도를 실시간으로 측정해요.\n최고속도 범위를 자유롭게 조절할 수 있어요.',
    ),
    _PageData(
      icon: Icons.route,
      title: '주행 기록',
      description: '주행을 마치면 거리·시간·속도가 자동 저장돼요.\n경로를 지도에서 다시 확인할 수도 있어요.',
    ),
    _PageData(
      icon: Icons.emoji_events,
      title: '목표 & 통계',
      description: '연간·월간 거리 목표를 설정하고\n달성률과 스트릭을 확인해보세요.',
    ),
    _PageData(
      icon: Icons.check_circle_outline,
      title: '준비 완료!',
      description: '이제 첫 주행을 시작해볼까요?',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goPrev() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _start() async {
    await context
        .read<SettingsProvider>()
        .completeOnboarding(neverShowAgain: _neverShowAgain);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(page.icon, size: 96, color: Colors.blue),
                        const SizedBox(height: 36),
                        Text(
                          page.title,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 15,
                            height: 1.7,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // 페이지 인디케이터
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? Colors.blue : cs.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // 다시 보지 않기 (마지막 페이지)
                  if (_isLastPage) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _neverShowAgain,
                          onChanged: (v) =>
                              setState(() => _neverShowAgain = v ?? true),
                          activeColor: Colors.blue,
                        ),
                        GestureDetector(
                          onTap: () {
                            SystemSound.play(SystemSoundType.click);
                            setState(() => _neverShowAgain = !_neverShowAgain);
                          },
                          child: Text(
                            '다시 보지 않기',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    const SizedBox(height: 20),

                  const SizedBox(height: 16),

                  // 이전 / 다음·시작하기 버튼
                  Row(
                    children: [
                      if (_currentPage > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _goPrev,
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: cs.outlineVariant),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('이전',
                                style: TextStyle(color: cs.onSurface)),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLastPage ? _start : _goNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _isLastPage ? '시작하기' : '다음',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
