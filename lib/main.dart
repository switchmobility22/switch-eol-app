import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'eol/screens/eol_login_screen.dart';
import 'eol/screens/eol_radar_screen.dart';
import 'eol/services/eol_auth_service.dart';
import 'eol/services/eol_ble_service.dart';
import 'eol/services/eol_local_storage_service.dart';
import 'eol/services/eol_sync_service.dart';
import 'eol/theme/eol_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (if not already initialized)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('ℹ️ Firebase initialization note: $e');
  }

  runApp(const EolApp());
}

class EolApp extends StatefulWidget {
  const EolApp({super.key});

  @override
  State<EolApp> createState() => _EolAppState();
}

class _EolAppState extends State<EolApp> {
  late final EolAuthService _authService;
  late final EolLocalStorageService _localStorage;
  late final EolSyncService _syncService;
  late final EolBleService _bleService;

  @override
  void initState() {
    super.initState();
    _authService = EolAuthService()..loadSavedSession();
    _localStorage = EolLocalStorageService();
    _syncService = EolSyncService(localStorage: _localStorage);
    _bleService = EolBleService();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authService),
        ChangeNotifierProvider.value(value: _localStorage),
        ChangeNotifierProvider.value(value: _syncService),
        ChangeNotifierProvider.value(value: _bleService),
      ],
      child: Builder(
        builder: (ctx) {
          final auth = ctx.watch<EolAuthService>();
          return MaterialApp(
            title: 'Powerpedal EOL Station',
            debugShowCheckedModeBanner: false,
            theme: EolTheme.themeData,
            home: auth.isLoggedIn
                ? const EolRadarScreen()
                : const EolLoginScreen(),
          );
        },
      ),
    );
  }
}
