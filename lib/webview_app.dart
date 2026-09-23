import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'models/app_remote_config.dart';
import 'screens/linux_launch_screen.dart';
import 'screens/webview_home_screen.dart';
import 'services/remote_config_service.dart';

/// MGD-DevOS als nativer Desktop-Container (Webview-Wrapper) für ein
/// bestehendes Web-Projekt.
///
/// Lädt beim Start eine öffentliche JSON-Konfiguration (siehe
/// [RemoteConfigService]) und fällt bei jedem Fehler (offline, Timeout,
/// ungültiges JSON, private URL ohne Zugriff) auf einen eingebauten
/// Standardwert zurück, statt einen Fehlerzustand zu erzwingen.
class MgdDevOsWebviewApp extends StatefulWidget {
  const MgdDevOsWebviewApp({super.key, this.configService});

  final RemoteConfigService? configService;

  @override
  State<MgdDevOsWebviewApp> createState() => _MgdDevOsWebviewAppState();
}

class _MgdDevOsWebviewAppState extends State<MgdDevOsWebviewApp> {
  late final RemoteConfigService _configService =
      widget.configService ?? RemoteConfigService();

  AppRemoteConfig? _config;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _configService.load();
    if (!mounted) return;
    setState(() => _config = config);
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;

    return MaterialApp(
      title: config?.appTitle ?? RemoteConfigDefaults.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6FED),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: config == null
          ? const _LoadingScreen()
          : (defaultTargetPlatform == TargetPlatform.linux
              ? LinuxLaunchScreen(config: config)
              : WebviewHomeScreen(config: config)),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
