import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import 'database/bills_database.dart';
import 'database/client_database.dart';
import 'database/payment_history_database.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class BackupService {
  static const _scopes = [drive.DriveApi.driveFileScope];
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);
  static const _backupFolderName = 'Ponto do Frango - Backup';

  Future<drive.DriveApi?> _getDriveApi({bool forceSignIn = false}) async {
    try {
      // Always sign out to force account selection
      await _googleSignIn.signOut();
      final GoogleSignInAccount? user = await _googleSignIn.signIn();

      if (user == null) return null;

      final authHeaders = await user.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      return drive.DriveApi(client);
    } catch (e) {
      Logger().e("Erro ao obter DriveApi: $e");
      return null;
    }
  }

  Future<List<drive.File>?> getBackupFiles({bool forceSignIn = false}) async {
    final driveApi = await _getDriveApi(forceSignIn: forceSignIn);
    if (driveApi == null) return null;

    try {
      final folder = await _getOrCreateBackupFolder(driveApi);
      final response = await driveApi.files.list(
        q: "'${folder.id}' in parents",
        $fields: "files(id, name, createdTime)",
      );
      return response.files;
    } catch (e) {
      Logger().e("Error listing backups: $e");
      return null;
    }
  }

  // Helper class to authenticate HTTP requests

  Future<void> exportBackup({bool forceSignIn = false}) async {
    final driveApi = await _getDriveApi(forceSignIn: forceSignIn);
    if (driveApi == null) {
      throw Exception('Não foi possível conectar ao Google Drive');
    }

    try {
      final databases = [
        'client_database.db',
        'bill_database.db',
        'payment_history_database.db',
      ];

      // Create temporary directory for zip
      final tempDir = await Directory.systemTemp.createTemp('backup');
      final zipFile = File(
          '${tempDir.path}/backup_${DateTime.now().millisecondsSinceEpoch}.zip');

      // Create zip
      final encoder = ZipEncoder();
      final archive = Archive();

      // Add each database to the archive
      for (final dbName in databases) {
        final dbPath = await _getDatabasePath(dbName);
        if (dbPath == null) {
          Logger().e("Database $dbName not found.");
          continue;
        }

        final dbFile = File(dbPath);
        if (await dbFile.exists()) {
          final bytes = await dbFile.readAsBytes();
          archive.addFile(ArchiveFile(dbName, bytes.length, bytes));
        }
      }

      // Write zip file
      await zipFile.writeAsBytes(encoder.encode(archive));

      // Upload zip to Drive
      final folder = await _getOrCreateBackupFolder(driveApi);
      await _uploadFile(driveApi, zipFile, folder.id!);

      // Cleanup
      await zipFile.delete();
      await tempDir.delete(recursive: true);
    } catch (e) {
      Logger().e("Export error: $e");
      rethrow;
    }
  }

  Future<String?> _getDatabasePath(String dbName) async {
    try {
      final directory = await getDatabasesPath();
      return '$directory/$dbName';
    } catch (e) {
      Logger().e("Error getting path for $dbName: $e");
      return null;
    }
  }

  Future<void> importBackup(drive.File backupFile) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) throw Exception('Não conectado ao Google Drive');

    try {
      // Close all databases before importing
      await ClientDataBase().close();
      await BillDatabaseHelper().close();
      await PaymentHistoryDatabase.instance.close();

      final databasesPath = await getDatabasesPath();

      // Download zip file
      final response = await driveApi.files.get(
        backupFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await response.stream.fold<List<int>>(
        [],
        (previous, element) => previous..addAll(element),
      );

      // Decode zip
      final archive = ZipDecoder().decodeBytes(bytes);

      // Extract each file
      for (final file in archive) {
        if (file.isFile) {
          final data = file.content as List<int>;
          final dbFile = File(path.join(databasesPath, file.name));
          await dbFile.writeAsBytes(data);
        }
      }

      Logger().i('Backup restaurado com sucesso');
    } catch (e) {
      Logger().e("Erro na importação: $e");
      throw Exception('Falha ao restaurar backup');
    }
  }

  Future<drive.File> _getOrCreateBackupFolder(drive.DriveApi driveApi) async {
    try {
      final existing = await driveApi.files.list(
          q: "name = '$_backupFolderName' and mimeType = 'application/vnd.google-apps.folder'",
          $fields: "files(id,name)");

      if (existing.files != null && existing.files!.isNotEmpty) {
        return existing.files!.first;
      }
      return await driveApi.files.create(drive.File()
        ..name = _backupFolderName
        ..mimeType = 'application/vnd.google-apps.folder');
    } catch (e) {
      Logger().e("Erro ao obter ou criar pasta de backup");
      rethrow; // Re-lança o erro para ser tratado em chamadores superiores, se necessário.
    }
  }

  Future<void> _uploadFile(
      drive.DriveApi driveApi, File file, String folderId) async {
    try {
      final media = drive.Media(file.openRead(), file.lengthSync());
      await driveApi.files.create(
          drive.File()
            ..name = file.path.split('/').last
            ..parents = [folderId],
          uploadMedia: media);
      Logger().i('Arquivo ${file.path.split('/').last} enviado com sucesso!');
    } catch (e) {
      Logger().e("Erro ao enviar arquivo");
    }
  }
}
