import 'package:flutter/material.dart';

import 'app_state.dart';
import 'native_app.dart';

/// MGD-DevOS: lokale Projektzentrale (Onboarding, Projekt-Scanner,
/// lesendes Agentic Control Panel aus echten lokalen Projektdateien).
///
/// Das ist die aktuelle Hauptrichtung der App (Entscheidung vom
/// 23.09.2026). Ein alternativer Webview-Wrapper-Modus, der eine externe
/// Web-App in einem nativen Fenster anzeigt, liegt vollständig fertig in
/// `lib/webview_app.dart` im Repository und kann bei Bedarf reaktiviert
/// oder als zusätzlicher Modus eingebaut werden, sobald es eine erreichbare
/// Web-Version von MGD_AI-Projektmanager gibt.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(NativeMgdDevOsApp(appState: AppState()));
}
