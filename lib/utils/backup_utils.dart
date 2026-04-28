import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database_helper.dart';
import '../models/ride_record.dart';

Future<void> shareBackup() async {
  final records = await DatabaseHelper.instance.getAllRecords();
  final json = jsonEncode(records.map((r) => r.toMap()).toList());

  final now = DateTime.now();
  final name =
      'speed_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsString(json);

  await Share.shareXFiles([XFile(file.path)], subject: name);
}

// 반환: true=저장됨, false=취소됨
Future<bool> exportBackup() async {
  final records = await DatabaseHelper.instance.getAllRecords();
  final json = jsonEncode(records.map((r) => r.toMap()).toList());
  final bytes = Uint8List.fromList(utf8.encode(json));

  final now = DateTime.now();
  final name =
      'speed_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';

  final path = await FilePicker.platform.saveFile(
    dialogTitle: '백업 저장 위치 선택',
    fileName: name,
    bytes: bytes,
  );

  return path != null;
}

// 반환: 새로 추가된 건수, null=취소
Future<int?> importBackup() async {
  final path = await pickBackupFile();
  if (path == null) return null;
  return importFromPath(path);
}

// 파일 선택 다이얼로그만 표시. null=취소
Future<String?> pickBackupFile() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.any);
  if (result == null || result.files.isEmpty) return null;
  return result.files.single.path;
}

// 선택된 파일 경로에서 실제 임포트 수행. 진행률 콜백(0.0~1.0) 지원.
Future<int> importFromPath(
  String path, {
  void Function(double)? onProgress,
}) async {
  final content = await File(path).readAsString();
  final List<dynamic> list = jsonDecode(content);

  onProgress?.call(0.0);

  int imported = 0;
  for (int i = 0; i < list.length; i++) {
    final record =
        RideRecord.fromMap(Map<String, dynamic>.from(list[i] as Map));
    if (await DatabaseHelper.instance.insertRecordIfNotExists(record)) {
      imported++;
    }
    onProgress?.call((i + 1) / list.length);
  }
  return imported;
}
