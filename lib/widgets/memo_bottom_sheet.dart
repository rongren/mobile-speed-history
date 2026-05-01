import 'package:flutter/material.dart';

Future<void> showMemoBottomSheet(
  BuildContext context, {
  required TextEditingController controller,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (bsCtx) => _MemoSheet(outerController: controller),
  );
}

class _MemoSheet extends StatefulWidget {
  final TextEditingController outerController;

  const _MemoSheet({required this.outerController});

  @override
  State<_MemoSheet> createState() => _MemoSheetState();
}

class _MemoSheetState extends State<_MemoSheet> {
  late final TextEditingController _ctrl;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.outerController.text);
    _focusNode = FocusNode();
    // 바텀시트 애니메이션(~300ms)이 끝난 뒤 키보드를 띄워
    // 배경 다이얼로그가 키보드에 반응해 올라가는 것을 배리어가 가린 상태에서 처리
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // viewPaddingOf는 키보드 변화에 반응하지 않으므로 이 위젯은 키보드 애니메이션 중 rebuild 없음.
    // 키보드 높이 추적은 _KeyboardInsetPadding이 단독 처리 → TextField/Column은 안정적.
    final navBarHeight = MediaQuery.viewPaddingOf(context).bottom;

    return _KeyboardInsetPadding(
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + navBarHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('메모',
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              focusNode: _focusNode,
              autofocus: false,
              maxLength: 80,
              maxLines: 5,
              minLines: 3,
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: '메모를 남겨보세요',
                hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                counterStyle:
                    TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  widget.outerController.text = _ctrl.text;
                  Navigator.pop(context);
                },
                child: const Text('완료',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// viewInsets(키보드)만 구독하는 분리 위젯.
// 키보드 애니메이션 중 이 위젯만 rebuild되고, child(Container/Column/TextField)는 rebuild 없음.
class _KeyboardInsetPadding extends StatelessWidget {
  final Widget child;

  const _KeyboardInsetPadding({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: child,
    );
  }
}
