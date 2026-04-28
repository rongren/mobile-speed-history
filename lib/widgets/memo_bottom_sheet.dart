import 'package:flutter/material.dart';

Future<void> showMemoBottomSheet(
  BuildContext context, {
  required TextEditingController controller,
  required bool isDark,
}) async {
  final bsCtrl = TextEditingController(text: controller.text);
  final bgColor = isDark ? const Color(0xFF1e1e1e) : Colors.white;
  final textColor = isDark ? Colors.white : Colors.black87;
  final fillColor = isDark ? Colors.grey[900]! : Colors.grey[100]!;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (bsCtx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(bsCtx).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('메모',
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: bsCtrl,
              autofocus: true,
              maxLength: 80,
              maxLines: 5,
              minLines: 3,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: '메모를 남겨보세요',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                counterStyle: const TextStyle(color: Colors.grey, fontSize: 11),
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
    ),
  );
}
