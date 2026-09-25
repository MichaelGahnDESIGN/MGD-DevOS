# Entwicklung und CI

```bash
flutter pub get
flutter analyze
flutter test
python3 scripts/sync_meta.py --check   # Version, Metadaten, Testanzahl, LICENSE/NOTICE im Skill aktuell?
```

## Tests

Unit-Tests für Scanner (inklusive MGD-Plattform-Erkennung), PIN-Dienst, Metadaten, Tab-Logik und Navigationssperre;
Widget-Tests für Onboarding, Sperrbildschirm, Übersicht und Einstellungen. Echte Webviews lassen sich headless nicht
testen, dafür gibt es den Integrationstest. Die aktuelle Anzahl steht in der README (von `sync_meta.py` gezählt).

## Integrationstest (macOS, Windows, Linux)

```bash
flutter test integration_test -d macos     # bzw. -d windows, unter Linux: xvfb-run -a flutter test integration_test -d linux
```

Die CI führt ihn auf allen drei Systemen aus: macOS (WebKit), Windows (WebView2) und Linux (Browser-Ausweichweg,
weil es dort kein eingebettetes WebView gibt). Er startet die echte App, öffnet ein lokales Dashboard im eingebetteten Webview und prüft Laden, Speicher und
Navigationssperre. Lokal nötig: volles Xcode (einmalig `sudo xcodebuild -runFirstLaunch`) und CocoaPods.
Mit der System-Ruby 2.6 ließ sich CocoaPods 1.15.2 nur mit älteren Abhängigkeiten installieren
(`--user-install`, u. a. `activesupport ~> 6.1`, `concurrent-ruby 1.3.4`). In Tests nicht `pumpAndSettle` verwenden,
sondern feste Takte, weil die echte App nie vollständig „ruhig" meldet.

## GitHub Actions

`ci.yml` läuft bei Push und Pull Request: `analyze_test` (Ubuntu: `sync_meta.py --check`, Analyse, Unit-Tests),
dann `macos` (macos-14, Integrationstest, DMG), `windows` (Integrationstest, ZIP) und `linux` (Integrationstest unter
`xvfb`, TAR.GZ). Artefakte hängen am jeweiligen Lauf. `release.yml` ruft `ci.yml` per `workflow_call` auf und
veröffentlicht nur nach grüner CI, siehe [Release-Prozess](Release-Prozess.md).

## Stolperfallen

- Workflow-Dateien pushen braucht das `workflow`-Scope (`gh auth refresh -s workflow`).
- Blockierte Läufe mit „recent account payments have failed": Abrechnung des GitHub-Kontos prüfen.
- Private Repos verbrauchen Minuten (macOS zehnfach), öffentliche nicht.
- `flutter create` legt eine unpassende `test/widget_test.dart` an, löschen. Die App ist reine Desktop-App; `web/`
  wird nicht gebaut.
- Lokal ohne Xcode kein macOS-Build; `scripts/package_macos.sh` bricht dann mit klarer Meldung ab.
