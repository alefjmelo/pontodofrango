import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pontodofrango/screens/navigation_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pontodofrango/utils/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await initializeDateFormatting('pt_BR', null);
  runApp(MyApp());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'autoBackupTask') {
      final prefs = await SharedPreferences.getInstance();
      final frequency = prefs.getString('backupFrequency') ?? 'none';
      if (frequency == 'none') return true;

      final lastBackup = prefs.getInt('lastBackupTimestamp') ?? 0;
      final lastBackupDate = DateTime.fromMillisecondsSinceEpoch(lastBackup);
      final now = DateTime.now();

      bool shouldBackup = false;
      switch (frequency) {
        case 'daily':
          shouldBackup = now.difference(lastBackupDate).inDays >= 1;
          break;
        case 'weekly':
          shouldBackup = now.difference(lastBackupDate).inDays >= 7;
          break;
        case 'monthly':
          shouldBackup = now.difference(lastBackupDate).inDays >= 30;
          break;
        default:
          shouldBackup = false;
      }

      if (shouldBackup) {
        try {
          await BackupService().exportBackup(forceSignIn: false);
          await prefs.setInt('lastBackupTimestamp', now.millisecondsSinceEpoch);
          return true;
        } catch (e) {
          return false;
        }
      }
    }
    return true;
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: WelcomeScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/logo.svg',
              height: 200,
            ),
            SizedBox(height: 100),
            Text(
              'Olá! Pronto para começar? =)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 100),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NavigationScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.yellow[700],
                minimumSize: Size(200, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Iniciar',
                style: TextStyle(fontSize: 20),
              ),
            )
          ],
        ),
      ),
    );
  }
}
