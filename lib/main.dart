import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MgdDevOsApp(appState: AppState()));
}

/// MGD-DevOS: lokale Projektzentrale.
///
/// Diese erste Version läuft komplett lokal, macht keine Netzwerkzugriffe
/// und speichert keine Zugangsdaten (siehe SettingsStore und die Restliste
/// in `docs/mgd-devos/`).
class MgdDevOsApp extends StatefulWidget {
  const MgdDevOsApp({super.key, required this.appState});

  final AppState appState;

  @override
  State<MgdDevOsApp> createState() => _MgdDevOsAppState();
}

class _MgdDevOsAppState extends State<MgdDevOsApp> {
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
