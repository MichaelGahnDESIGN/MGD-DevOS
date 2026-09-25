# Projekt-Scanner

Der Scanner geht **eine Ebene tief** durch den gewählten Projektordner und liest nur, er ändert nichts.

## Wann ist ein Ordner ein Projekt?

Mindestens eines: `.git`, `README.md`, `AGENTS.md`, `pubspec.yaml`, `package.json`,
`PROJEKT/.mgd-ai-projektmanager.json` oder `MGD_PLATFORM.yml`. Versteckte Ordner (Punkt am Anfang) werden übersprungen.

## Was wird erkannt?

Git, Living Docs (`docs/`), Dashboard-Konfiguration, `AGENTS.md`, `catalog/capabilities.json`,
`catalog/integrations.json`, `catalog/skills.json`, `index.html` (Dashboard).

## Projekte des MGD-Plattform-Builders

Liegt `MGD_PLATFORM.yml` im Projektordner, gilt das Projekt als Plattform des
[MGD-Plattform-Builders](https://github.com/MichaelGahnDESIGN/MGD-Plattform-Builder). Version und Status liest der
Scanner aus `version.json` (Felder `version` im Format `X.Y.Z` und `status`, z. B. `pre-alpha`) und zeigt sie als
Badge in der Projektkarte, z. B. „Plattform 0.0.1 Pre-Alpha". Fehlt `version.json` oder ist sie ungültig, steht dort
nur „MGD-Plattform", es wird keine Version erfunden. Eine `version.json` ohne `MGD_PLATFORM.yml` wird ignoriert.

## Dokumente

README, CHANGELOG, AGENTS, GRUNDREGELN, PROJEKTREGELN, SKILL, MGD_PLATFORM.yml und die DevOS-Dokumente
unter `docs/mgd-devos/`, sofern vorhanden. Sie öffnen in einer Textansicht oder im Standardprogramm.
