# Changelog

## 0.1.2 (2026-09-23)

- Fix macOS: Ordner-Auswahl („Wählen") funktionierte nicht und der Standardpfad zeigte in den
  Sandbox-Container. Die App-Sandbox ist jetzt aus, damit MGD-DevOS gewählte Projektordner und
  deren `index.html` lesen kann (keine App-Store-Verteilung).

## 0.1.1 (2026-09-23)

- Erste Version mit Installern: macOS (DMG), Windows (ZIP), Linux (TAR.GZ), gebaut über GitHub Actions.
- Logo, App-Icons (macOS, Windows, Linux-Fenster, Web) und Pflicht-Fußzeile „supported by: Michael Gahn DESIGN".
- Lizenz PolyForm Noncommercial 1.0.0, NOTICE, CONTRIBUTING.
- Laufzeit-Konfiguration liegt jetzt unter `config/` in diesem Repo.
- Fix: Windows-Build mit Visual Studio 18 (flutter_inappwebview).
- Bekannt: unsigniert/nicht notarisiert; Dashboard-`file://` im Webview noch nicht auf echtem Gerät geprüft.

## 0.1.0 (2026-09-23, Vorabversion)

- Native Flutter-Desktop-App: Onboarding, Projektregister, Dokumentenansicht.
- Tab-Browser für lokale Projekt-Dashboards (`index.html`), Übersicht als Tab 0.
- Agentic Control Panel aus `AGENTS.md` und `catalog/*.json`, ohne erfundenen Live-Status.
- Hell/Dunkel/System-Theme mit Akzentfarbe.
- CI- und Release-Workflows, Wiki.
- Bekannt: keine geprüften Installer, unsigniert, Dashboard-`file://` auf macOS/Windows ungeprüft.
