# Release-Prozess

1. Version in `pubspec.yaml` erhöhen (SemVer), `CHANGELOG.md` ergänzen.
2. Tag setzen und pushen: `git tag v0.2.0 && git push origin v0.2.0`.
3. `release.yml` baut macOS (DMG), Windows (ZIP), Linux (TAR.GZ), erzeugt `SHA256SUMS.txt` und
   hängt alles an das GitHub Release.
4. Prüfsummen vergleichen: `shasum -a 256 -c SHA256SUMS.txt`.

## Signierung

Aktuell **unsigniert**. macOS: Gatekeeper-Warnung (Rechtsklick, Öffnen). Notarisierung braucht
das Apple Developer Program. Windows: SmartScreen-Warnung ohne Zertifikat. Zertifikate gehören
ausschließlich als GitHub-Secrets in die Pipeline, nie ins Repository.

## Packages

GitHub Packages (npm/Container) ergibt für eine Desktop-App keinen Sinn. Verteilungsweg sind die
Release-Anhänge.
