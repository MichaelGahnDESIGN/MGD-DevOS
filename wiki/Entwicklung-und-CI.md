# Entwicklung und CI

```bash
flutter pub get
flutter analyze
flutter test
```

## Tests

Unit-Tests für Scanner, Konfiguration, Tab-Logik und Navigationssperre; Widget-Tests für Onboarding
und Übersicht. Echte Webviews lassen sich headless nicht testen.

## GitHub Actions

`ci.yml` läuft bei Push und Pull Request: `analyze_test` (Ubuntu), dann `macos` (macos-14, Xcode
vorhanden, DMG), `windows`, `linux`. Artefakte hängen am jeweiligen Lauf.

## Stolperfallen

- Workflow-Dateien pushen braucht das `workflow`-Scope (`gh auth refresh -s workflow`).
- Blockierte Läufe mit „recent account payments have failed": Abrechnung des GitHub-Kontos prüfen.
- Private Repos verbrauchen Minuten (macOS zehnfach), öffentliche nicht.
- `flutter create --platforms=web .` legt eine unpassende `test/widget_test.dart` an, löschen.
- Lokal ohne Xcode kein macOS-Build; `scripts/package_macos.sh` bricht dann mit klarer Meldung ab.
