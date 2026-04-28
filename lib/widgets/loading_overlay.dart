import 'package:flutter/material.dart';

/// 비동기 작업 실행 중 전화면 터치 차단 오버레이를 표시한다.
/// [setProgress]에 0.0~1.0 을 전달하면 진행률 바로 전환, null 이면 무한 스피너.
Future<T> runWithLoading<T>(
  BuildContext context, {
  required Future<T> Function(void Function(double?) setProgress) task,
  String label = '처리 중...',
}) async {
  final progressNotifier = ValueNotifier<double?>(null);

  final entry = OverlayEntry(
    builder: (_) => _LoadingOverlay(notifier: progressNotifier, label: label),
  );

  Overlay.of(context).insert(entry);

  try {
    return await task((p) => progressNotifier.value = p);
  } finally {
    entry.remove();
    progressNotifier.dispose();
  }
}

class _LoadingOverlay extends StatelessWidget {
  final ValueNotifier<double?> notifier;
  final String label;

  const _LoadingOverlay({required this.notifier, required this.label});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AbsorbPointer(
        child: Container(
          color: Colors.black54,
          child: Center(
            child: ValueListenableBuilder<double?>(
              valueListenable: notifier,
              builder: (context2, progress, child) =>
                  _LoadingCard(progress: progress, label: label),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final double? progress;
  final String label;

  const _LoadingCard({required this.label, this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1e1e1e),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progress == null)
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                  color: Colors.teal, strokeWidth: 3),
            )
          else ...[
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation(Colors.teal),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Text(
              '${(progress! * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
