import 'package:flutter/material.dart';

class NumberInputDialog extends StatefulWidget {
  final String title;
  final int initialValue;
  final String unit;
  final int min;
  final int max;

  const NumberInputDialog({
    super.key,
    required this.title,
    required this.initialValue,
    required this.unit,
    required this.min,
    required this.max,
  });

  /// 다이얼로그를 띄우고 입력값을 반환. 취소 시 null.
  static Future<int?> show(
    BuildContext context, {
    required String title,
    required int initialValue,
    required String unit,
    required int min,
    required int max,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) => NumberInputDialog(
        title: title,
        initialValue: initialValue,
        unit: unit,
        min: min,
        max: max,
      ),
    );
  }

  @override
  State<NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<NumberInputDialog> {
  late String _input;

  @override
  void initState() {
    super.initState();
    _input = widget.initialValue.toString();
  }

  int get _currentValue => int.tryParse(_input) ?? 0;

  bool get _isValid =>
      _currentValue >= widget.min && _currentValue <= widget.max;

  void _onDigit(String digit) {
    setState(() {
      if (_input == '0') {
        _input = digit;
      } else if (_input.length < 4) {
        _input += digit;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_input.length > 1) {
        _input = _input.substring(0, _input.length - 1);
      } else {
        _input = '0';
      }
    });
  }

  void _confirm() {
    if (_isValid) Navigator.pop(context, _currentValue);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1e1e1e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 숫자 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _input,
                  style: TextStyle(
                    color: _isValid ? Colors.white : Colors.red,
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    widget.unit,
                    style: const TextStyle(color: Colors.grey, fontSize: 22),
                  ),
                ),
              ],
            ),

            Text(
              '${widget.min} ~ ${widget.max} ${widget.unit}',
              style: TextStyle(
                  color: _isValid ? Colors.grey : Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 24),

            // 키패드
            _buildKeypad(),
            const SizedBox(height: 20),

            // 취소 / 확인
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('취소',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _isValid ? _confirm : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isValid ? Colors.blue : Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '확인',
                          style: TextStyle(
                              color: _isValid ? Colors.white : Colors.grey[600],
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _keyRow(['1', '2', '3']),
        _keyRow(['4', '5', '6']),
        _keyRow(['7', '8', '9']),
        Row(
          children: [
            // 빈 칸
            Expanded(child: const SizedBox()),
            const SizedBox(width: 6),
            Expanded(
              child: _keyButton('0', onTap: () => _onDigit('0')),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _keyButton('⌫',
                  onTap: _onBackspace,
                  textColor: Colors.orange,
                  fontSize: 22),
            ),
          ],
        ),
      ],
    );
  }

  Widget _keyRow(List<String> digits) {
    return Row(
      children: digits.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: e.key < digits.length - 1 ? 6 : 0,
              bottom: 6,
            ),
            child: _keyButton(e.value, onTap: () => _onDigit(e.value)),
          ),
        );
      }).toList(),
    );
  }

  Widget _keyButton(
    String label, {
    required VoidCallback onTap,
    Color? textColor,
    double fontSize = 20,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
