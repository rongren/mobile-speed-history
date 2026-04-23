class RideRecord {
  final int? id;
  final int year;
  final int month;
  final int day;
  final double totalDistance;
  final double maxSpeed;
  final double avgSpeed;
  final int duration;
  final String pathPoints;
  final int createdAt;

  RideRecord({
    this.id,
    required this.year,
    required this.month,
    required this.day,
    required this.totalDistance,
    required this.maxSpeed,
    required this.avgSpeed,
    required this.duration,
    required this.pathPoints,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'day': day,
      'totalDistance': totalDistance,
      'maxSpeed': maxSpeed,
      'avgSpeed': avgSpeed,
      'duration': duration,
      'pathPoints': pathPoints,
      'createdAt': createdAt,
    };
  }

  factory RideRecord.fromMap(Map<String, dynamic> map) {
    return RideRecord(
      id: map['id'],
      year: map['year'],
      month: map['month'],
      day: map['day'],
      totalDistance: map['totalDistance'],
      maxSpeed: map['maxSpeed'],
      avgSpeed: map['avgSpeed'] ?? 0.0,
      duration: map['duration'],
      pathPoints: map['pathPoints'],
      createdAt: map['createdAt'],
    );
  }
}