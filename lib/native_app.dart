import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';

/// Frühere native Variante von MGD-DevOS: lokale Projektzentrale mit
/// Onboarding, Projekt-Scanner und lesendem Agentic Control Panel aus
/// echten lokalen Projektdateien.
///
/// Seit dem Wechsel zum Webview-Wrapper (siehe `webview_app.dart` und
/// `main.dart`) ist dies nicht mehr der Standard-Einstiegspunkt, aber
/// vollständig erhalten und weiterhin durch Tests abgedeckt. Beide
/// Betriebsarten können bei Bedarf später kombiniert oder umschaltbar
/// gemacht werden.
class NativeMgdDevOsApp extends StatefulWidget {
  const NativeMgdDevOsApp({super.key, required this.appState});

  final AppState appState;

  @override
  State<NativeMgdDevOsApp> createState() => _NativeMgdDevOsAppState();
}

class _NativeMgdDevOsAppState extends State<NativeMgdDevOsApp> {
  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onStateChanged);
    widget.appState.bootstrap();
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final accent = appState.accentColor;

    return MaterialApp(
      title: 'MGD-DevOS',
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: accent),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: appState.isLoading
          ? const _SplashScreen()
          : appState.onboardingDone
              ? HomeShell(appState: appState)
              : OnboardingScreen(appState: appState),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
