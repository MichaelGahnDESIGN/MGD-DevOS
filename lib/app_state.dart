import 'package:flutter/material.dart';

import 'models/agentic_entity.dart';
import 'models/mgd_project.dart';
import 'services/agentic_scanner.dart';
import 'services/project_scanner.dart';
import 'services/settings_store.dart';

/// Zentraler, unveränderlich weitergereichter App-Zustand.
///
/// Zustandsänderungen erzeugen nie das Original neu mutiert, sondern setzen
/// neue Felder und rufen [notifyListeners]. Persistiert wird ausschließlich
/// über [SettingsStore] (keine Secrets, siehe dortige Dokumentation).
class AppState extends ChangeNotifier {
  AppState({
    SettingsStore? settingsStore,
    ProjectScanner? projectScanner,
    AgenticScanner? agenticScanner,
  })  : _settings = settingsStore ?? SettingsStore(),
        _projectScanner = projectScanner ?? ProjectScanner(),
        _agenticScanner = agenticScanner ?? AgenticScanner();

  final SettingsStore _settings;
  final ProjectScanner _projectScanner;
  final AgenticScanner _agenticScanner;

  bool isLoading = true;
  bool onboardingDone = false;
  ThemeMode themeMode = ThemeMode.system;
  Color accentColor = SettingsStore.defaultAccentColor;
  String? projectsRoot;

  List<MgdProject> projects = const [];
  List<AgenticEntity> agenticEntities = const [];
  DateTime? lastScan;
  String? lastScanError;

  Future<void> bootstrap() async {
    onboardingDone = await _settings.isOnboardingDone();
    themeMode = await _settings.getThemeMode();
    accentColor = await _settings.getAccentColor();
    projectsRoot = await _settings.getProjectsRoot();
    isLoading = false;
    notifyListeners();

    if (projectsRoot != null && projectsRoot!.isNotEmpty) {
      await rescan();
    }
  }

  Future<void> completeOnboarding(String chosenRoot) async {
    await _settings.setProjectsRoot(chosenRoot);
    await _settings.setOnboardingDone(true);
    projectsRoot = chosenRoot;
    onboardingDone = true;
    notifyListeners();
    await rescan();
  }

  Future<void> setProjectsRoot(String path) async {
    await _settings.setProjectsRoot(path);
    projectsRoot = path;
    notifyListeners();
    await rescan();
  }

  Future<void> rescan() async {
    final root = projectsRoot;
    if (root == null || root.isEmpty) return;
    try {
      final found = await _projectScanner.scan(root);
      final agentic = await _agenticScanner.scan(found);
      projects = found;
      agenticEntities = agentic;
      lastScan = DateTime.now();
      lastScanError = null;
    } catch (error) {
      lastScanError = error.toString();
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _settings.setThemeMode(mode);
    themeMode = mode;
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    await _settings.setAccentColor(color);
    accentColor = color;
    notifyListeners();
  }
}
