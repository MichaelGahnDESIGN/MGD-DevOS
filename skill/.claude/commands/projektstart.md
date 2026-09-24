---
description: Startet den ultimativen Projektstart-Assistenten (Interview, Skill-Installation mit Sicherheits-Vetting, Einrichtung)
---

# /projektstart – Kompatibilitätsalias

Kompatibilitätsbefehl für den `MGD-DevOS`. Führt den in `SKILL.md`
beschriebenen mehrstufigen Assistenten aus. Für die Projektzentrale zuerst
`/Dashboard` verwenden:

1. Projekt-Interview (Name, Typ, Zielplattform, Zielgruppe, Umfang, Backend-Bedarf, Sprache).
2. Installation der vier MGD-Kern-Skills (MGD_DEV_SKILL, Fragenkatalog-Skill, MGD_Todo_SKILL, MGD_Living-Documentation) nach Bestätigung.
3. Optionales Angebot des Projekt-Plattform-Systems (`mgd-platform init --preset <preset>`) bei erkanntem Backend-Bedarf.
4. Vorschlag passender Domain-Skills aus `catalog/skills.json`, danach optionale Live-Suche via `gh search repos` / `gh search code`.
5. **Pflicht-Sicherheits-Check** jedes Dritt-Skills mit NVIDIA/SkillSpector und/oder affaan-m/agentshield vor jeder Installation — siehe `wiki/Sicherheitskonzept.md`.
6. Eintragen der Projektdetails in installierte Skills (`/fragenkatalog-setup`, `/todo-add`, Living-Documentation-Einstiegsseite) und Fortschreiben von `PROJEKT/.projektstart-manifest.json`.
7. Abschluss-Zusammenfassung (installiert / eingerichtet / offen).

Verwandte Befehle: `/projektstart-update`, `/projektstart-katalog`, `/projektstart-katalog-add`.

Vollständige Logik: siehe [`SKILL.md`](../../SKILL.md) im Repo-Root.
