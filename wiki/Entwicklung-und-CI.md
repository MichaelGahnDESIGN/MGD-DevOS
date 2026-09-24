# Entwicklung und CI

```bash
flutter pub get
flutter analyze
flutter test
```

## Tests

Unit-Tests für Scanner, Konfiguration, Tab-Logik und Navigationssperre; Widget-Tests für Onboarding
und Übersicht. Echte Webviews lassen sich headless nicht testen.

## Integrationstest (macOS)

```bash
flutter test integration_test -d macos
```

Startet die echte App, öffnet ein lokales Dashboard im eingebetteten Webview und prüft Laden, Speicher und
Navigationssperre. Lokal nötig: volles Xcode (einmalig `sudo xcodebuild -runFirstLaunch`) und CocoaPods.
Mit der System-Ruby 2.6 ließ sich CocoaPods 1.15.2 nur mit älteren Abhängigkeiten installieren
(`--user-install`, u. a. `activesupport ~> 6.1`, `concurrent-ruby 1.3.4`). In Tests nicht `pumpAndSettle` verwenden,
sondern feste Takte, weil die echte App nie vollständig „ruhig" meldet.

## GitHub Actions

`ci.yml` läuft bei Push und Pull Request: `analyze_test` (Ubuntu), dann `macos` (macos-14, Xcode
vorhanden, DMG), `windows`, `linux`. Artefakte hängen am jeweiligen Lauf.

## Stolperfallen

- Workflow-Dateien pushen braucht das `workflow`-Scope (`gh auth refresh -s workflow`).
- Blockierte Läufe mit „recent account payments have failed": Abrechnung des GitHub-Kontos prüfen.
- Private Repos verbrauchen Minuten (macOS zehnfach), öffentliche nicht.
- `flutter create --platforms=web .` legt eine unpassende `test/widget_test.dart` an, löschen.
- Lokal ohne Xcode kein macOS-Build; `scripts/package_macos.sh` bricht dann mit klarer Meldung ab.
