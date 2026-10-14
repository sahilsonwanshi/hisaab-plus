import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class DriveBackupFileItem {
  final String id;
  final String name;
  final int size;
  final DateTime modifiedTime;

  const DriveBackupFileItem({
    required this.id,
    required this.name,
    required this.size,
    required this.modifiedTime,
  });

  String get formattedSize {
    if (size <= 0) return '0 B';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

class DriveSyncService {
  static final DriveSyncService instance = DriveSyncService._internal();
  DriveSyncService._internal();

  static const String webClientId =
      '29432283078-cbjki80nseg6tnin7p6e6vifcimu3m6a.apps.googleusercontent.com';

  final ValueNotifier<GoogleSignInAccount?> currentUserNotifier =
      ValueNotifier<GoogleSignInAccount?>(null);

  bool _initialized = false;
  GoogleSignInAccount? _account;

  GoogleSignInAccount? get currentUser => currentUserNotifier.value;
  bool get isAuthenticated => currentUserNotifier.value != null;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await GoogleSignIn.instance.initialize(serverClientId: webClientId);
      _initialized = true;
    } catch (e) {
      debugPrint('DriveSyncService initialize error: $e');
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    await initialize();
    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: <String>[drive.DriveApi.driveFileScope],
      );
      _account = account;
      currentUserNotifier.value = account;
      return account;
    } catch (e) {
      debugPrint('DriveSyncService signIn error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('DriveSyncService signOut error: $e');
    } finally {
      _account = null;
      currentUserNotifier.value = null;
    }
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    if (_account == null) {
      await signIn();
    }
    if (_account == null) return null;

    final authHeaders = await _account!.authorizationClient.authorizationHeaders(
      <String>[drive.DriveApi.driveFileScope],
      promptIfNecessary: true,
    );

    if (authHeaders == null) return null;
    return drive.DriveApi(GoogleHttpClient(authHeaders));
  }

  /// List all Hisaab+ backup files stored in Google Drive
  Future<List<DriveBackupFileItem>> fetchHisaabBackups() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) throw Exception('Google account not connected');

    final fileList = await driveApi.files.list(
      spaces: 'drive',
      q: "name contains 'hisaab_plus_backup' and trashed = false",
      $fields: 'files(id, name, size, modifiedTime)',
      orderBy: 'modifiedTime desc',
      pageSize: 30,
    );

    final files = fileList.files ?? [];
    return files.map((f) {
      return DriveBackupFileItem(
        id: f.id ?? '',
        name: f.name ?? 'hisaab_plus_backup.json',
        size: int.tryParse(f.size ?? '0') ?? 0,
        modifiedTime: f.modifiedTime ?? DateTime.now(),
      );
    }).toList();
  }

  /// Upload or overwrite a Hisaab+ backup JSON file to Google Drive
  Future<DriveBackupFileItem> uploadBackupFile({
    required String jsonString,
    String? customFileName,
  }) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) throw Exception('Google account not connected');

    final fileName = customFileName ??
        'hisaab_plus_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final bytes = utf8.encode(jsonString);

    final mediaStream = Stream<List<int>>.value(bytes);
    final media = drive.Media(mediaStream, bytes.length);

    final driveFile = drive.File()
      ..name = fileName
      ..description = 'Hisaab+ Cloud Backup'
      ..mimeType = 'application/json';

    final result = await driveApi.files.create(
      driveFile,
      uploadMedia: media,
      $fields: 'id, name, size, modifiedTime',
    );

    return DriveBackupFileItem(
      id: result.id ?? '',
      name: result.name ?? fileName,
      size: int.tryParse(result.size ?? '') ?? bytes.length,
      modifiedTime: result.modifiedTime ?? DateTime.now(),
    );
  }

  /// Download and parse JSON string from a Google Drive file
  Future<String> downloadBackupFileString(String fileId) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) throw Exception('Google account not connected');

    final response = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    if (response is! drive.Media) {
      throw Exception('Could not read file media stream');
    }

    final List<int> byteStore = [];
    await for (final chunk in response.stream) {
      byteStore.addAll(chunk);
    }

    return utf8.decode(byteStore);
  }

  /// Delete a backup file from Google Drive
  Future<void> deleteBackupFile(String fileId) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) throw Exception('Google account not connected');

    await driveApi.files.delete(fileId);
  }
}
