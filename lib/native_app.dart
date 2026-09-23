import 'package:flutter/material.dart';

import 'app_state.dart';
import 'theme/app_theme.dart';
import 'screens/tabs_shell.dart';
import 'screens/onboarding_screen.dart';

/// MGD-DevOS als Tab-Browser für lokale Projekt-Dashboards: Tab 0 ist die
/// Übersicht (Projektauswahl, Agentic Control Panel, Einstellungen), weitere
/// Tabs zeigen die `index.html` (`/dashboard`) einzelner Projekte.
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
      theme: buildTheme(Brightness.light, accent),
      darkTheme: buildTheme(Brightness.dark, accent),
      home: appState.isLoading
          ? const _SplashScreen()
          : appState.onboardingDone
              ? TabsShell(appState: appState)
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
