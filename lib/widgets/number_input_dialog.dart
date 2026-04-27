import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberInputDialog extends StatefulWidget {
  final String title;
  final num? initialValue;
  final String unit;
  final int maxDigits;
  final bool allowEmpty;
  final bool allowDecimal;

  static const double clearValue = -1;

  const NumberInputDialog({
    super.key,
    required this.title,
    this.initialValue,
    required this.unit,
    this.maxDigits = 4,
    this.allowEmpty = false,
    this.allowDecimal = false,
  });

  static Future<double?> show(
    BuildContext context, {
    required String title,
    num? initialValue,
    required String unit,
    int maxDigits = 4,
    bool allowEmpty = false,
    bool allowDecimal = false,
  }) {
    return showDialog<double>(
      context: context,
      builder: (_) => NumberInputDialog(
        title: title,
        initialValue: initialValue,
        unit: unit,
        maxDigits: maxDigits,
        allowEmpty: allowEmpty,
        allowDecimal: allowDecimal,
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
    final v = widget.initialValue;
    if (v == null) {
      _input = '';
    } else if (widget.allowDecimal && v % 1 != 0) {
      _input = v.toString();
    } else {
      _input = v.toInt().toString();
    }
  }

  double? get _currentValue => double.tryParse(_input);

  bool get _isValid {
    if (_input.isEmpty) return widget.allowEmpty;
    if (_input.endsWith('.')) return false;
    final v = _currentValue;
    return v != null && v > 0;
  }

  void _onDigit(String digit) {
    setState(() {
      if (widget.allowDecimal) {
        final dotIdx = _input.indexOf('.');
        if (dotIdx >= 0) {
          // 소수점 이하 최대 2자리
          if (_input.length - dotIdx - 1 >= 2) return;
        } else {
          // 정수 부분: 선행 0 방지 ("05" → 불가)
          if (_input == '0') return;
          if (_input.isEmpty && digit == '0') {
            _input = '0';
            return;
          }
          if (_input.length >= widget.maxDigits) return;
        }
      } else {
        if (_input.isEmpty && digit == '0') return;
        if (_input.length >= widget.maxDigits) return;
      }
      _input += digit;
    });
  }

  void _onDecimalPoint() {
    setState(() {
      if (!widget.allowDecimal) return;
      if (_input.contains('.')) return;
      if (_input.isEmpty) _input = '0';
      _input += '.';
    });
  }

  void _onBackspace() {
    setState(() {
      if (_input.isNotEmpty) {
        _input = _input.substring(0, _input.length - 1);
      }
    });
  }

  void _confirm() {
    if (!_isValid) return;
    if (_input.isEmpty) {
      Navigator.pop(context, NumberInputDialog.clearValue);
    } else {
      Navigator.pop(context, _currentValue!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _input.isEmpty;

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

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isEmpty ? '--' : _input,
                  style: TextStyle(
                    color: isEmpty ? Colors.grey[600] : Colors.white,
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
            const SizedBox(height: 24),

            _buildKeypad(),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      SystemSound.play(SystemSoundType.click);
                      Navigator.pop(context);
                    },
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
                    onTap: _isValid ? () {
                      SystemSound.play(SystemSoundType.click);
                      _confirm();
                    } : null,
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
                              color: _isValid
                                  ? Colors.white
                                  : Colors.grey[600],
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
            Expanded(
              child: widget.allowDecimal
                  ? _keyButton(
                      '.',
                      onTap: _onDecimalPoint,
                      textColor: _input.contains('.')
                          ? Colors.grey[700]!
                          : Colors.blue,
                    )
                  : const SizedBox(),
            ),
            const SizedBox(width: 6),
            Expanded(child: _keyButton('0', onTap: () => _onDigit('0'))),
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
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        onTap();
      },
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
