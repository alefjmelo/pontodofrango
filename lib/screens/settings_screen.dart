import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pontodofrango/utils/backup_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:pontodofrango/utils/showCustomOverlay.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService backupService = BackupService();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[700],
            ),
            child: const Text(
              'Configurações',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26),
            ),
          ),
        ),
        backgroundColor: Colors.grey[800],
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildBackupSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackupSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Backup',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading:
              const Icon(Icons.cloud_upload, color: Colors.yellow, size: 30),
          title: const Text(
            'Exportar Backup',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white),
          onTap: () async {
            try {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: SizedBox(
                    width: 250,
                    height: 250,
                    child: AlertDialog(
                      backgroundColor: Colors.grey[700],
                      contentPadding: const EdgeInsets.all(24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      content: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.yellow),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Exportando backup...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              await backupService.exportBackup(forceSignIn: true);

              if (!context.mounted) return;
              Navigator.pop(context); // Close loading dialog
              showCustomOverlay(context, 'Backup exportado com sucesso!');
            } catch (e) {
              if (!context.mounted) return;
              Navigator.pop(context); // Close loading dialog
              showCustomOverlay(context, 'Exportação cancelada');
            }
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading:
              const Icon(Icons.cloud_download, color: Colors.yellow, size: 30),
          title: const Text(
            'Importar Backup',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white),
          onTap: () async {
            try {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: SizedBox(
                    width: 250, // Fixed size
                    height: 250,
                    child: AlertDialog(
                      backgroundColor: Colors.grey[700],
                      contentPadding: const EdgeInsets.all(24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      content: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.yellow),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Buscando backups...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              final backups =
                  await backupService.getBackupFiles(forceSignIn: true);

              if (!context.mounted) return;
              Navigator.pop(context); // Close loading dialog

              if (backups == null || backups.isEmpty) {
                showCustomOverlay(context, 'Nenhum backup encontrado');
                return;
              }

              final selectedBackup = await showDialog<drive.File>(
                context: context,
                builder: (context) => BackupSelectionDialog(backups: backups),
              );

              if (!context.mounted || selectedBackup == null) return;

              // Show loading dialog for import
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[700],
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.yellow),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Importando backup...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );

              await backupService.importBackup(selectedBackup);

              if (!context.mounted) return;
              Navigator.pop(context); // Close loading dialog
              showCustomOverlay(context, 'Backup importado com sucesso!');
            } catch (e) {
              if (!context.mounted) return;
              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Close loading dialog if open
              }
              showCustomOverlay(
                  context, 'Falha na importação: ${e.toString()}');
            }
          },
        ),
      ],
    );
  }
}

class BackupSelectionDialog extends StatelessWidget {
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

// Fix date formatting method
  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return _dateFormatter.format(dateTime);
  }

  final List<drive.File> backups;

  BackupSelectionDialog({super.key, required this.backups});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text(
        'Selecione um Backup',
        style: TextStyle(color: Colors.white, fontSize: 22),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: backups.length,
          itemBuilder: (context, index) {
            final backup = backups[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, color: Colors.yellow),
              title: Text(
                backup.name!,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                _formatDate(backup.createdTime),
                style: TextStyle(color: Colors.grey[400]),
              ),
              onTap: () => Navigator.pop(context, backup),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
