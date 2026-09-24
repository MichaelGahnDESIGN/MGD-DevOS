# /projektstart – Kompatibilitätsalias

Der bevorzugte Einstieg ist jetzt `/Dashboard`. Dieser Befehl bleibt als
Kompatibilitätsalias für das ausführliche Projektstart-Interview erhalten und
führt den mehrstufigen Assistenten gemäß [`SKILL.md`](../../SKILL.md) aus:

1. Projekt-Interview.
2. Installation der vier MGD-Kern-Skills nach Einzel-Bestätigung.
3. Optionales `mgd-platform init --preset <preset>` bei Backend-Bedarf.
4. Domain-Skill-Vorschläge aus `catalog/skills.json`, danach optionale Live-GitHub-Suche.
5. Pflicht-Sicherheits-Scan (SkillSpector/agentshield) jedes Dritt-Skills vor Installation.
6. Details in installierte Skills eintragen, Manifest `PROJEKT/.projektstart-manifest.json` fortschreiben.
7. Abschluss-Zusammenfassung.

Weitere Befehle: `/projektstart-update`, `/projektstart-katalog`, `/projektstart-katalog-add <repo-url> <kategorie>`.

Details: siehe `SKILL.md` im Repo-Root sowie `wiki/` für vertiefende Dokumentation.
