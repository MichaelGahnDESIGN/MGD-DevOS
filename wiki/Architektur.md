# Architektur

```
lib/
  main.dart                 Einstieg (Tab-Browser)
  native_app.dart           MaterialApp, Theme, Onboarding/Tabs
  app_state.dart            ChangeNotifier: Einstellungen, Projekte, Tabs
  models/                   MgdProject, AgenticEntity, DashboardTab, AppRemoteConfig
  services/                 ProjectScanner, AgenticScanner, SettingsStore, RemoteConfigService
  screens/                  Onboarding, TabsShell, HomeShell, Projekte, Panel, Einstellungen,
                            DashboardTabView, DocumentViewer, Webview-Wrapper (inaktiv)
```

- **Zustand:** ein `AppState` (ChangeNotifier), Listen werden ersetzt statt verändert.
- **Persistenz:** nur `SettingsStore` (SharedPreferences).
- **Lesen statt schreiben:** Scanner sind rein lesend.
- **Inaktiver Modus:** `webview_app.dart` zeigt eine externe URL aus einer öffentlichen JSON-Konfiguration.

Plattform-Runner (`macos/`, `windows/`, `linux/`, `web/`) sind Standard-Flutter mit Produktname „MGD-DevOS".
