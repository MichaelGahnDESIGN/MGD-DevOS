# Einstellungen

Oben rechts (Zahnrad) oder `⌘/Strg ,`. Das Suchfeld filtert alle Bereiche; ohne Suche wählst du links einen Bereich.

| Bereich | Inhalt |
|---|---|
| Darstellung | System, Hell, Dunkel; Akzentfarbe |
| Projekte | Projektordner ändern, neu scannen |
| Grundregeln | `GRUNDREGELN.md` eines Projekts bearbeiten und nach Bestätigung speichern |
| Sicherheit | PIN-Sperre mit 4, 6 oder 8 Ziffern |
| Datenschutz | Was lokal gespeichert wird |
| Versionen | Timeline aller Versionen mit Versionshinweisen, filterbar nach Bereich |
| Über | Version, Lizenz, Link |
| Credits | Personen, KI-Systeme, Werkzeuge, Bibliotheken, Schriften, Icons mit Anbieter, Links und Lizenz |

## PIN-Sperre

- Beim Start fragt die App nach der PIN, der Sperrbildschirm zeigt die Version.
- Gespeichert wird nur ein PBKDF2-SHA-256-Hash mit Salz, nie die PIN.
- Ändern und Deaktivieren nur mit der aktuellen PIN. Nach 5 Fehlversuchen Wartezeit (30 s, verdoppelt, höchstens 1 h).
- **PIN notieren.** Ohne PIN kommst du nur durch Löschen der App-Einstellungen wieder hinein.
- Grenze: schützt vor Blicken am Bildschirm, ersetzt nicht die Anmeldung am Rechner und verschlüsselt keine Dateien.

Das Dashboard hat dieselbe PIN-Funktion für den Browser (Einstellungen → Sicherheit). Dort gilt zusätzlich: Die Inhalte
stehen im Klartext in der HTML-Datei.

## Versionen und Credits pflegen

- Version: `assets/meta/version.json`, danach `python3 scripts/sync_meta.py` (CI prüft mit `--check`).
- Versionshinweise: `CHANGELOG.md` (Abschnitte `## x.y.z (Datum)`).
- Credits: `assets/meta/credits.json`. Im Dashboard lassen sie sich zusätzlich lokal bearbeiten.
