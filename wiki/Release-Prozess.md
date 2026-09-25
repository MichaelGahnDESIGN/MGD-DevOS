# Release-Prozess

App und Projektmanager-Skill tragen **eine gemeinsame Version**. Einzige Quelle ist
[`assets/meta/version.json`](../assets/meta/version.json) (`version`, `stage`, `build`, `date`).

1. `assets/meta/version.json` anpassen (Schema 1.2.3: 1 = Hauptversion ab Release, 2 = neue Funktionen,
   3 = Patches), `build` erhöhen.
2. `CHANGELOG.md` ergänzen: Abschnitt `## X.Y.Z (Datum, Stage)`. Skill-Änderungen zusätzlich in
   `skill/CHANGELOG.md` unter derselben Versionsnummer.
3. `python3 scripts/sync_meta.py` ausführen. Das Skript schreibt die Version in `pubspec.yaml`, die
   Versions-Timeline (`assets/meta/versions.json`), die Metadaten im Dashboard (`skill/dashboard/index.html`),
   die Versionsangaben in `README.md`, `skill/README.md` und `skill/SKILL.md`, die Testanzahl in der README und
   kopiert `LICENSE` und `NOTICE` nach `skill/`. `python3 scripts/sync_meta.py --check` (läuft in der CI) schlägt
   fehl, wenn etwas davon veraltet ist oder `CHANGELOG.md` keinen Abschnitt für die Version hat.
4. Committen, Tag setzen und pushen: `git tag vX.Y.Z && git push origin vX.Y.Z`. Der Tag muss zur Version in
   `version.json` passen, sonst bricht der Release ab.
5. `release.yml` ruft zuerst die komplette CI auf (`ci.yml` per `workflow_call`: Analyse, Unit-Tests,
   `sync_meta.py --check`, Integrationstests auf macOS, Windows und Linux, Pakete). Nur wenn alles grün ist,
   hängt der Job „publish" DMG, Windows-ZIP, Linux-TAR.GZ, `MGD-DevOS-Skill.zip` (inklusive `LICENSE` und
   `NOTICE`) und `SHA256SUMS.txt` an das Release mit dem Titel **„MGD-DevOS X.Y.Z Stage"**, z. B.
   „MGD-DevOS 0.5.2 Pre-Alpha".
6. Prüfsummen vergleichen: `shasum -a 256 -c SHA256SUMS.txt`.

## Signierung

Aktuell **unsigniert**. macOS: Gatekeeper-Warnung (Rechtsklick, Öffnen). Notarisierung braucht
das Apple Developer Program. Windows: SmartScreen-Warnung ohne Zertifikat. Zertifikate gehören
ausschließlich als GitHub-Secrets in die Pipeline, nie ins Repository.

## Packages

GitHub Packages (npm/Container) ergibt für eine Desktop-App keinen Sinn. Verteilungsweg sind die
Release-Anhänge.
