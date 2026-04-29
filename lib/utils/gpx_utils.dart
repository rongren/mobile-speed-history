import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database_helper.dart';
import '../models/ride_record.dart';

String _trkSegment(RideRecord record) {
  final points = jsonDecode(record.pathPoints) as List<dynamic>;
  final m = record.month.toString().padLeft(2, '0');
  final d = record.day.toString().padLeft(2, '0');
  final buf = StringBuffer()
    ..write('  <trk>\n')
    ..write('    <name>${record.year}-$m-$d</name>\n')
    ..write('    <trkseg>\n');
  for (final pt in points) {
    buf.write('      <trkpt lat="${pt['lat']}" lon="${pt['lng']}"/>\n');
  }
  buf
    ..write('    </trkseg>\n')
    ..write('  </trk>\n');
  return buf.toString();
}

String buildGpxString(RideRecord record) {
  final startTime = DateTime.fromMillisecondsSinceEpoch(record.createdAt).toUtc();
  final m = record.month.toString().padLeft(2, '0');
  final d = record.day.toString().padLeft(2, '0');
  final name = '${record.year}-$m-$d';
  return '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<gpx version="1.1" creator="Speed Mobile" '
      'xmlns="http://www.topografix.com/GPX/1/1">\n'
      '  <metadata>\n'
      '    <name>$name</name>\n'
      '    <time>${startTime.toIso8601String()}</time>\n'
      '  </metadata>\n'
      '${_trkSegment(record)}'
      '</gpx>';
}

String _gpxFileName(RideRecord record) {
  final m = record.month.toString().padLeft(2, '0');
  final d = record.day.toString().padLeft(2, '0');
  final t = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
  final h = t.hour.toString().padLeft(2, '0');
  final min = t.minute.toString().padLeft(2, '0');
  return 'ride_${record.year}$m${d}_$h$min.gpx';
}

Future<void> shareGpx(RideRecord record) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${_gpxFileName(record)}');
  await file.writeAsString(buildGpxString(record));
  await Share.shareXFiles([XFile(file.path)], subject: _gpxFileName(record));
}

Future<void> shareAllGpx() async {
  final records = await DatabaseHelper.instance.getAllRecords();
  if (records.isEmpty) return;

  records.sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final buf = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8"?>\n')
    ..write('<gpx version="1.1" creator="Speed Mobile" '
        'xmlns="http://www.topografix.com/GPX/1/1">\n');
  for (final r in records) {
    buf.write(_trkSegment(r));
  }
  buf.write('</gpx>');

  final now = DateTime.now();
  final fileName =
      'speed_all_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.gpx';
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(buf.toString());
  await Share.shareXFiles([XFile(file.path)], subject: fileName);
}
