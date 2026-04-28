import 'package:flutter/material.dart';

class StatDetailItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color textColor;

  const StatDetailItem({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        if (unit.isNotEmpty)
          Text(unit, style: const TextStyle(color: Colors.blue, fontSize: 11)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}

class StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final bool labelBlue;

  const StatItem({
    super.key,
    required this.label,
    required this.value,
    required this.textColor,
    this.labelBlue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: labelBlue ? Colors.blue : Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
