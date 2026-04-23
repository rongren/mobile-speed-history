import 'package:flutter/material.dart';

class RecordBadges extends StatelessWidget {
  final int? recordId;
  final Map<String, int?> bestIds;

  const RecordBadges({
    super.key,
    required this.recordId,
    required this.bestIds,
  });

  @override
  Widget build(BuildContext context) {
    if (recordId == null) return const SizedBox();

    final badges = <Widget>[];

    if (bestIds['distance'] == recordId) {
      badges.add(_badge('최장거리', Colors.blue));
    }
    if (bestIds['speed'] == recordId) {
      badges.add(_badge('최고속도', Colors.red));
    }
    if (bestIds['duration'] == recordId) {
      badges.add(_badge('최장시간', Colors.green));
    }

    if (badges.isEmpty) return const SizedBox();

    return Wrap(
      spacing: 4,
      children: badges,
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events,
              color: color, size: 10),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}