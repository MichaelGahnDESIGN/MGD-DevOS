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
- Agentic Control Panel: liest `AGENTS.md`, `catalog/capabilities.json`,
  `catalog/integrations.json` und `catalog/skills.json` (inkl. Pflicht-
  Skills wie `MGD_AI-Thread`) aus den gescannten Projekten. Jeder Eintrag
  zeigt Quelle und Beobachtungszeitpunkt und trägt **nie** den Status
  "belegt aktiv", solange kein echter Codex-/Claude-Code-Adapter verbunden
  ist (siehe `lib/services/agentic_scanner.dart`).

**CI (`.github/workflows/ci.yml`):** baut und testet bei jedem Push/PR auf
main automatisch auf allen drei Zielplattformen (GitHub-Actions-Runner
bringen für macOS ein vollständiges Xcode mit – im Gegensatz zu diesem
lokalen Entwicklungsrechner):
- `analyze_test` (Ubuntu): `flutter analyze` + `flutter test`.
- `macos` (macos-14, volles Xcode): `scripts/package_macos.sh` →
  Artefakt `MGD-DevOS-macos` (`MGD-DevOS.dmg`, unsigniert/nicht notarisiert).
- `windows` (windows-latest): `flutter build windows --release` →
  Artefakt `MGD-DevOS-windows` (ZIP des Release-Ordners).
- `linux` (ubuntu-latest, GTK-Abhängigkeiten installiert): `flutter build
  linux --release` → Artefakt `MGD-DevOS-linux` (TAR.GZ des Bundles).

Artefakte liegen nach jedem Lauf unter dem jeweiligen Actions-Run auf
GitHub. Das ist eine echte Build-Verifikation auf allen drei Plattformen,
aber noch **keine signierte/notarisierte** Auslieferung.

**Noch nicht geprüft/verifiziert:**
- **Lokaler macOS-Build:** `flutter build macos` schlägt auf diesem
  Entwicklungsrechner fehl, weil nur die Xcode Command Line Tools
  installiert sind, nicht das volle Xcode (`xcodebuild` fehlt).
  Xcode-Installation über den App Store braucht eine Apple-ID-Anmeldung
  durch den Nutzer selbst. Nach Installation:
  ```
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -runFirstLaunch
  flutter doctor -v
  scripts/package_macos.sh
  ```
  Bis dahin liefert die GitHub-Actions-CI (siehe oben) die verifizierten
  macOS-Artefakte.
- Code-Signierung/Notarisierung, Live-Agenten-Adapter, App-Sperre/Secret-
  Verwaltung, lokale Bridge, Stripe-Spenden/Rechnungen: siehe die
  vollständige Restliste in der Projektübergabe (`docs/mgd-devos/` im
  Quellrepo `MGD_AI-Projektmanager`).

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
