---
description: Einen geprüften Dritt-Skill dauerhaft zum Startkatalog hinzufügen
---

# /projektstart-katalog-add

Quelle der Anweisungen: `SKILL.md` des Skills `mgd-devos` (global unter
`~/.claude/skills/mgd-devos/SKILL.md` bzw. `~/.codex/skills/mgd-devos/SKILL.md`,
projekt-lokal unter `.claude/skills/mgd-devos/SKILL.md` bzw. `.codex/skills/mgd-devos/SKILL.md`).
Lies dort zuerst den genannten Abschnitt und folge ihm vollständig.

Maßgeblich ist der Abschnitt „`/projektstart-katalog-add <repo-url> <kategorie>`“.

Argumente: $ARGUMENTS (`<repo-url> <kategorie>`). Metadaten nur aus `gh repo view` übernehmen, nichts erfinden;
neuer Eintrag mit `source: "third-party-curated"` und `requiresScan: true`. Vor dem Schreiben bestätigen lassen.
