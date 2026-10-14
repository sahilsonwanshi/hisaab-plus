import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'hive_backup_service.dart';

class LocalStorageBackupService {
  static final LocalStorageBackupService instance =
      LocalStorageBackupService._internal();
  LocalStorageBackupService._internal();

  /// Export local data to a JSON file and trigger native Share Sheet / Save
  Future<String> exportAndShareBackup() async {
    final jsonString = HiveBackupService.instance.exportAllBoxesToJson();
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final fileName = 'hisaab_plus_backup_$dateStr.json';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Hisaab+ Backup Data ($fileName)',
      subject: 'Hisaab+ Offline Backup',
    );

    return file.path;
  }

  /// Pick and import a backup JSON file from device local storage
  Future<Map<String, dynamic>?> pickAndReadLocalBackup() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (files.isEmpty) return null;

      final pickedFile = files.first;
      final bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) return null;

      final content = utf8.decode(bytes);
      final dynamic decoded = jsonDecode(content);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid backup format: root must be a JSON object');
      }

      return decoded;
    } catch (e) {
      debugPrint('Error picking local backup: $e');
      rethrow;
    }
  }
}
