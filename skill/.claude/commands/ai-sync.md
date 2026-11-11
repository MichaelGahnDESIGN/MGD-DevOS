---
description: Skills, Commands, MCP-Server und Plugins zwischen Macs abgleichen (ai-sync)
---

# /ai-sync

Quelle der Anweisungen: `SKILL.md` des Skills `mgd-devos` (global unter
`~/.claude/skills/mgd-devos/SKILL.md` bzw. `~/.codex/skills/mgd-devos/SKILL.md`,
projekt-lokal unter `.claude/skills/mgd-devos/SKILL.md` bzw. `.codex/skills/mgd-devos/SKILL.md`).
Lies dort zuerst den genannten Abschnitt und folge ihm vollständig.

Maßgeblich ist der Abschnitt „`/ai-sync`“ sowie `ai-sync/README.md` des Skills.

Starte mit dem Trockenlauf `python3 ai-sync/ai_sync.py plan` (Pfad relativ zum Skill-Ordner) und zeige den Status.
Führe `apply` nur nach Bestätigung aus, nutze `--overwrite` und `--adopt` nur auf ausdrückliche Anweisung,
und gib nie Secrets aus.
Argumente: $ARGUMENTS (z. B. `plan`, `apply` oder `export --output manifest.json`).
