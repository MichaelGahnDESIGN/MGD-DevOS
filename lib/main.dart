import 'package:flutter/material.dart';

import 'app_state.dart';
import 'native_app.dart';

/// MGD-DevOS: lokale Projektzentrale (Onboarding, Projekt-Scanner,
/// Tab-Browser für Projekt-Dashboards, lesendes Agentic Control Panel aus
/// echten lokalen Projektdateien).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(NativeMgdDevOsApp(appState: AppState()));
}
