# Projekt-Scanner

Der Scanner geht **eine Ebene tief** durch den gewählten Projektordner und liest nur, er ändert nichts.

## Wann ist ein Ordner ein Projekt?

Mindestens eines: `.git`, `README.md`, `AGENTS.md`, `pubspec.yaml`, `package.json` oder
`PROJEKT/.mgd-ai-projektmanager.json`. Versteckte Ordner (Punkt am Anfang) werden übersprungen.

## Was wird erkannt?

Git, Living Docs (`docs/`), Dashboard-Konfiguration, `AGENTS.md`, `catalog/capabilities.json`,
`catalog/integrations.json`, `catalog/skills.json`, `index.html` (Dashboard).

## Dokumente

README, CHANGELOG, AGENTS, GRUNDREGELN, PROJEKTREGELN, SKILL und die DevOS-Dokumente
unter `docs/mgd-devos/`, sofern vorhanden. Sie öffnen in einer Textansicht oder im Standardprogramm.
