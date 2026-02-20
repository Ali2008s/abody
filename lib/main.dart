import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/security_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization (requires google-services.json for Android)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Security Service (VPN & Anti-Tamper)
  await SecurityService().initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
      child: const AboudiTVApp(),
    ),
  );
}

class AboudiTVApp extends StatelessWidget {
  const AboudiTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<AppProvider>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'العبودي TV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // Arabic Support
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
