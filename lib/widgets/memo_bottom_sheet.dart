import 'package:flutter/material.dart';

Future<void> showMemoBottomSheet(
  BuildContext context, {
  required TextEditingController controller,
}) async {
  final bsCtrl = TextEditingController(text: controller.text);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (bsCtx) {
      final cs = Theme.of(bsCtx).colorScheme;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(bsCtx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(bsCtx).viewPadding.bottom),
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
                controller: bsCtrl,
                autofocus: true,
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
                  counterStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
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
                    controller.text = bsCtrl.text;
                    Navigator.pop(bsCtx);
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
    },
  );
}
