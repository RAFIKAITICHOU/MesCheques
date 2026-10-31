import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/checks_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/home_screen.dart';
import 'services/auto_backup_service.dart';
import 'services/cleanup_service.dart';
import 'utils/constants.dart';
import 'widgets/lock_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize and load saved locale from SharedPreferences
  final localeProvider = LocaleProvider();
  await localeProvider.load();

  // Initialize AuthProvider (reads secure storage, checks if PIN is set, applies FLAG_SECURE)
  final authProvider = AuthProvider();
  await authProvider.init();

  final checksProvider = ChecksProvider();

  // Defer database initialization & cleanup service until unlocked
  authProvider.onAuthenticated = () {
    checksProvider.refreshAll();
    CleanupService().run();
    AutoBackupService.instance.initialize();
  };

  // If already unlocked (e.g. during session or development), load data
  if (authProvider.hasPinSet && !authProvider.isLocked) {
    checksProvider.refreshAll();
    CleanupService().run();
    AutoBackupService.instance.initialize();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: checksProvider),
        ChangeNotifierProvider.value(value: AutoBackupService.instance),
      ],
      child: const MesChequesApp(),
    ),
  );
}

class MesChequesApp extends StatelessWidget {
  const MesChequesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(isArabic: localeProvider.isArabic),
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('fr'),
        Locale('ar', 'MA'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LockGate(
        child: HomeScreen(),
      ),
    );
  }
}

