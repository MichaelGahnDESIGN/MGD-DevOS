# Updater (`/projektstart-update`)

## Zweck

Skills, die einmal per `/projektstart` installiert wurden, veralten wie jeder andere Code auch — Quell-Repos bekommen Fixes, neue Features, Sicherheitsupdates. `/projektstart-update` prüft automatisiert, ob der lokal installierte Stand hinter dem Quell-Repo zurückliegt, und bietet eine gezielte Aktualisierung an.

## Grundlage: das Manifest

Jede Installation über `/projektstart` (Kern-Skills, Domain-Skills, künftig auch erneute Updates) schreibt einen Eintrag in `PROJEKT/.projektstart-manifest.json` (Beispielwerte):

```json
[
  {
    "skill": "MGD_DEV_SKILL",
    "sourceUrl": "https://github.com/MichaelGahnDESIGN/MGD_DEV_SKILL",
    "installedRef": "a1b2c3d",
    "installedDate": "2026-09-23",
    "installTarget": "global",
    "scanResult": "n/a"
  },
  {
    "skill": "dickwu/apple-design-skill",
    "sourceUrl": "https://github.com/dickwu/apple-design-skill",
    "installedRef": "9f8e7d6",
    "installedDate": "2026-09-23",
    "installTarget": "project-local",
    "scanResult": "clean"
  }
]
```

## Ablauf

1. Manifest einlesen.
2. Für jeden Eintrag den aktuellen Remote-Stand ermitteln:
   ```bash
   git ls-remote https://github.com/<owner>/<repo>.git HEAD
   gh api repos/<owner>/<repo>/commits/main --jq .sha
   gh release list --repo <owner>/<repo> --limit 1
   ```
3. Vergleichstabelle anzeigen.
4. Bei Updates: pro Skill (oder gesammelt "alle") nachfragen, mit Warnhinweis zu möglichen überschriebenen lokalen Anpassungen.
5. Bei Zustimmung: frischer `git clone`, erneutes Kopieren in dieselben Zielpfade wie bei Erstinstallation, Manifest-Eintrag aktualisieren.
6. Für Dritt-Skills (`requiresScan: true` im Katalog): der Sicherheits-Scan aus [Sicherheitskonzept.md](Sicherheitskonzept.md) wird beim Update erneut durchlaufen, bevor die neue Version übernommen wird — ein einmal als "clean" gescannter Skill wird bei jedem neuen Update-Stand erneut geprüft, da sich der Code seither geändert haben kann.

## Beispiel-Ausgabe

Alle Commit-Kürzel in diesem Beispiel sind **erfundene Beispielwerte** (gültiges Hex-Format, aber keine echten
Commits). In echten Läufen stammen sie aus `git ls-remote` bzw. der GitHub-API.

```
> /projektstart-update

Lese PROJEKT/.projektstart-manifest.json … 5 installierte Skills gefunden.
Prüfe aktuellen Stand der Quell-Repos …

| Skill                        | installierte Version   | aktuelle Version | Update verfügbar |
|-------------------------------|------------------------|-------------------|-------------------|
| MGD_DEV_SKILL                 | a1b2c3d (23.09.2026)    | f9e8d7c           | ja                |
| Fragenkatalog-Skill           | 4c5d6e7 (23.09.2026)    | 4c5d6e7           | nein              |
| MGD_Todo_SKILL                | 7e8f9a0 (23.09.2026)    | 7e8f9a0           | nein              |
| MGD_Living-Documentation      | b1c2d3e (23.09.2026)    | c4d5e6f           | ja                |
| dickwu/apple-design-skill     | 9f8e7d6 (23.09.2026)    | 2b3c4d5           | ja                |

3 Updates verfügbar. Aktualisieren? (alle/einzeln auswählen/keine)
> einzeln

MGD_DEV_SKILL aktualisieren? Hinweis: lokale Anpassungen an diesem Skill
können überschrieben werden. (ja/nein)
> ja
✓ MGD_DEV_SKILL aktualisiert auf f9e8d7c

dickwu/apple-design-skill aktualisieren? Dies ist ein Dritt-Skill — vor der
Übernahme wird erneut gescannt. (ja/nein)
> ja
→ Scan von 2b3c4d5 … keine CRITICAL/HIGH-Findings.
✓ dickwu/apple-design-skill aktualisiert auf 2b3c4d5

MGD_Living-Documentation aktualisieren? (ja/nein)
> nein
— übersprungen —

Fertig. 2 von 3 verfügbaren Updates übernommen.
```
