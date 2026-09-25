# Architektur

```
lib/
  main.dart                 Einstieg
  native_app.dart           MaterialApp, Theme, Sperrbildschirm/Onboarding/Tabs
  app_state.dart            ChangeNotifier: Einstellungen, PIN-Status, Metadaten, Projekte, Tabs
  models/                   MgdProject, PlatformInfo, AgenticEntity, DashboardTab
  services/
    project_scanner.dart    ProjectScanner: Projektordner eine Ebene tief, Dokumente, MGD_PLATFORM.yml
    agentic_scanner.dart    AgenticScanner: AGENTS.md und catalog/*.json
    settings_store.dart     SettingsStore: Theme, Akzentfarbe, Projektordner, Onboarding (SharedPreferences)
    pin_service.dart        PinService: PIN-Sichtschutz (PBKDF2-Hash, Fehlversuche, Wartezeit)
    meta_service.dart       AppMeta: Version, Versions-Timeline und Credits aus assets/meta
  screens/                  Onboarding, LockScreen, TabsShell, HomeShell, Projekte, Agentic Panel,
                            Einstellungen, DashboardTabView, DocumentViewer
  widgets/                  StatusBar (mit PoweredByPill), PoweredByFooter, AgenticGraph, UI-Bausteine
  theme/                    Design-Tokens
```

- **Zustand:** ein `AppState` (ChangeNotifier), Listen werden ersetzt statt verändert.
- **Persistenz:** `SettingsStore` und `PinService` über SharedPreferences (siehe
  [Sicherheit und Datenschutz](Sicherheit-und-Datenschutz.md)).
- **Lesen statt schreiben:** Scanner sind rein lesend. Einzige Schreibstelle in Projektordnern ist der
  Grundregeln-Editor (`GRUNDREGELN.md`, nach Rückfrage).
- **Metadaten:** `assets/meta/version.json` ist die einzige Versionsquelle für App und Skill;
  `scripts/sync_meta.py` überträgt sie (siehe [Release-Prozess](Release-Prozess.md)).
- **Lizenz:** `LICENSE` wird als Asset mitgeliefert und in Einstellungen › Lizenz angezeigt.

Plattform-Runner (`macos/`, `windows/`, `linux/`) sind Standard-Flutter mit Produktname „MGD-DevOS".
MGD-DevOS ist eine reine Desktop-App: Der Ordner `web/` stammt aus `flutter create`, wird weder gebaut noch
ausgeliefert, und die App läuft im Browser nicht (sie braucht Dateizugriff über `dart:io`).
