# Changelog

## 0.3.2 (2026-09-25)

- Integrationstest mit der echten App läuft jetzt in der CI auf macOS, Windows (WebView2) und Linux
  (Browser-Ausweichweg): Dashboard lädt, Speicher, Navigationssperre, Control-Plane-Dashboard.

## 0.3.1 (2026-09-25)

- Fix (Sicherheit): Die Navigationssperre im Dashboard-Tab war wirkungslos, weil `flutter_inappwebview`
  `shouldOverrideUrlLoading` nur mit `useShouldOverrideUrlLoading: true` aufruft. Externe Links öffneten dadurch im
  Webview statt im Systembrowser. Dateien außerhalb des Projektordners blockierte WebKit bereits vorher.
- Dashboard-Tab mit Adressleiste (Pfad), Ladeanzeige, „Neu laden", „Im Browser öffnen", Hinweis bei blockierter
  Navigation und Fehlerseite mit „Erneut versuchen".
- Integrationstest auf macOS (echte App): lokale `index.html` lädt, Browser-Speicher funktioniert, Unterseiten im
  Projekt erlaubt, Dateien außerhalb und fremde Schemata gesperrt, Control-Plane-Dashboard inkl. Einstellungen
  über Neuladen. Läuft jetzt auch in der CI.

## 0.3.0 (2026-09-24)

- Programm-Oberfläche im Stil einer Control Plane: schmale Icon-Leiste links, Titelleiste mit Statusanzeigen
  („Lokal", „Adapter aus"), Statusleiste unten (Projekte, letzter Scan, offene Dashboards, Pflicht-Hinweis
  „supported by: Michael Gahn DESIGN").
- Agentic Control Panel als echter Graph: Projekt → Gruppe → Eintrag mit Verbindungslinien, verschieb- und
  zoombar, Gruppen ein-/ausklappbar, große Gruppen starten eingeklappt; Inspektor rechts mit Status, Quelle und
  Zeitpunkt. Umschaltbar auf Liste.
- Tastenkürzel (⌘ auf macOS, Strg auf Windows/Linux): 1/2/3 Bereiche, „," Einstellungen, W Tab schließen,
  R neu scannen, ⇧[ / ⇧] Tab wechseln.
- Mindestfenstergröße 960 × 620 auf macOS, Windows und Linux; Startgröße 1280 × 800.
- Fix: Leerzustände überliefen bei kleinen Fenstern.

## 0.2.0 (2026-09-23)

- Neues Design: ruhiges, flaches Developer-Tool-Design mit Slate-Neutraltönen und MGD-Rot als Akzent,
  Schrift Inter (lokal eingebettet, SIL OFL), einheitliche Outline-Icons, dezente Übergänge
  (150–200 ms, respektiert „Bewegung reduzieren").
- Onboarding mit Markenbereich und Live-Vorschau, wie viele Projekte im gewählten Ordner erkannt werden.
- Browser-Tab-Leiste mit Einstellungen oben rechts, Seitenleiste für Projekte, Agentic Control Panel, Einstellungen.
- Projekte als Kachelraster mit Suche, Kennzahlen, Dokumentmenü und Hinweis auf ausgeblendete Ordner.
- Agentic Control Panel mit Kennzahlen, Filter-Chips, Suche und aufklappbaren Details (Quelle, Zeitpunkt).
- Einstellungen in Abschnittskarten; MGD-Rot ist neue Standard-Akzentfarbe.
- Kontrast im Dunkelmodus: Akzent-Text wird aufgehellt (mind. 4,5:1).
- Fix: verlinkte Projektordner (Symlinks) werden erkannt.

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
