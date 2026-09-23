# MGD-DevOS

Lokale Flutter-Desktop-Projektzentrale für Projekte, Living Documentation,
Skills, MCP-Verbindungen und Agenten. Läuft komplett auf dem eigenen Rechner,
macht keine Netzwerkzugriffe und speichert keine Zugangsdaten.

Diese erste Version deckt Abschnitt 3 der Projektübergabe vom 23.09.2026 ab:
Onboarding, Projektregister, Dokumentenöffnung, Light/Dark/System-Modus mit
Akzentfarbe und einen **lesenden** Agentic-Control-Panel-Graphen aus echten
lokalen Projektinformationen.

## Status (ehrlich, Stand 23.09.2026)

**Läuft:**
- `flutter analyze` ohne Befunde, `flutter test` grün (Unit- und Widget-Tests).
- Onboarding mit Ordnerauswahl für den Projekt-Root.
- Projektregister: scannt den gewählten Root eine Ebene tief nach echten
  Projektordnern (erkannt an `.git`, `README.md`, `AGENTS.md`,
  `pubspec.yaml`, `package.json` oder `PROJEKT/.mgd-ai-projektmanager.json`)
  und öffnet gefundene Dokumente (README, Living Docs, AGENTS.md, ...).
- Einstellungen: Light/Dark/System-Theme und Akzentfarbe, persistiert lokal.
- Agentic Control Panel: liest `AGENTS.md`, `catalog/capabilities.json` und
  `catalog/integrations.json` aus den gescannten Projekten. Jeder Eintrag
  zeigt Quelle und Beobachtungszeitpunkt und trägt **nie** den Status
  "belegt aktiv", solange kein echter Codex-/Claude-Code-Adapter verbunden
  ist (siehe `lib/services/agentic_scanner.dart`).

**Noch nicht geprüft/verifiziert:**
- **macOS-Build:** `flutter build macos` schlägt auf diesem Rechner fehl,
  weil nur die Xcode Command Line Tools installiert sind, nicht das volle
  Xcode (`xcodebuild` fehlt). Xcode-Installation über den App Store braucht
  eine Apple-ID-Anmeldung durch den Nutzer selbst. Nach Installation:
  ```
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -runFirstLaunch
  flutter doctor -v
  flutter build macos
  ```
- **Windows- und Linux-Build:** noch nicht auf den jeweiligen Plattformen
  geprüft (siehe Restliste, Abschnitt „Release und Betrieb“).
- Live-Agenten-Adapter, App-Sperre/Secret-Verwaltung, lokale Bridge, Stripe-
  Spenden/Rechnungen, CI und signierte Installer: siehe die vollständige
  Restliste in der Projektübergabe (`docs/mgd-devos/` im Quellrepo
  `MGD_AI-Projektmanager`).

## Standardpfad für die lokale Entwicklung

Diese erste Installation liegt standardmäßig unter `~/Developer/MGD-DevOS`.
Ein Nutzer soll den Installationsort später frei wählen können; das ist
noch nicht umgesetzt.

## Entwicklung

```bash
flutter pub get
flutter analyze
flutter test
flutter build macos   # erst nach vollständiger Xcode-Installation
```

## Sicherheit

- Es werden ausschließlich Darstellung (Theme, Akzentfarbe) und der
  Projekt-Root-Pfad lokal gespeichert (`shared_preferences`).
- Keine Zugangsdaten, keine Secrets, keine Telemetrie, keine
  Netzwerkzugriffe in dieser Version.
- Der Projektscanner liest nur Dateien innerhalb des vom Nutzer gewählten
  Projekt-Root und verändert nichts.
