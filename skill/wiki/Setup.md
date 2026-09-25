# Setup

## Voraussetzungen

- `git`
- [GitHub CLI `gh`](https://cli.github.com/), authentifiziert (`gh auth login`) — nötig für Live-Suche, Metadaten-Abfragen (`/projektstart-katalog-add`) und Update-Checks (`/projektstart-update`).
- Netzzugriff für Clone- und Scan-Schritte. Ohne Netzzugriff funktioniert `/projektstart` weiterhin, verlangt bei Dritt-Skills aber die explizite Ungeprüft-Bestätigung (siehe [Sicherheitskonzept.md](Sicherheitskonzept.md)).

Der Skill liegt im Ordner `skill/` des Repositorys
[MGD-DevOS](https://github.com/MichaelGahnDESIGN/MGD-DevOS) (alternativ als `MGD-DevOS-Skill.zip` im Release).
Installationsort ist immer ein Ordner namens `mgd-devos`. Mitgeliefert werden fünf Befehle:
`/projektstart`, `/projektstart-update`, `/projektstart-katalog`, `/projektstart-katalog-add` und `/dashboard`.

Quelle einmal holen:

```bash
git clone --depth 1 https://github.com/MichaelGahnDESIGN/MGD-DevOS.git /tmp/mgd-devos
```

## Installation für Claude Code

### Global (empfohlen: Befehle in jedem Projekt verfügbar)

```bash
mkdir -p ~/.claude/skills/mgd-devos ~/.claude/commands
cp -R /tmp/mgd-devos/skill/. ~/.claude/skills/mgd-devos/
cp ~/.claude/skills/mgd-devos/.claude/commands/*.md ~/.claude/commands/
```

Claude Code erkennt `SKILL.md` in `~/.claude/skills/mgd-devos/` automatisch; die Befehle liegen danach in
`~/.claude/commands/`. Dieselben Befehle aktualisieren eine bestehende Installation.

### Projekt-lokal (nur für ein Projekt)

Im Projektordner ausführen:

```bash
mkdir -p .claude/skills/mgd-devos .claude/commands
cp -R /tmp/mgd-devos/skill/. .claude/skills/mgd-devos/
cp .claude/skills/mgd-devos/.claude/commands/*.md .claude/commands/
```

## Installation für Codex

Analog mit `.codex/`-Pfaden, global:

```bash
mkdir -p ~/.codex/skills/mgd-devos ~/.codex/commands
cp -R /tmp/mgd-devos/skill/. ~/.codex/skills/mgd-devos/
cp ~/.codex/skills/mgd-devos/.codex/commands/*.md ~/.codex/commands/
```

oder projekt-lokal:

```bash
mkdir -p .codex/skills/mgd-devos .codex/commands
cp -R /tmp/mgd-devos/skill/. .codex/skills/mgd-devos/
cp .codex/skills/mgd-devos/.codex/commands/*.md .codex/commands/
```

Wo deine Codex-Version eigene Befehle erwartet, steht in der Codex-Dokumentation zu Custom Prompts; die Dateien in
`.codex/commands/` sind kurze Prompts, die auf den passenden Abschnitt in `SKILL.md` verweisen.

## `/thread` als Bestandteil des Projektstarts

`/projektstart` prüft, ob
[MGD_AI-Thread](https://github.com/MichaelGahnDESIGN/MGD_AI-Thread)
bereits installiert ist. Falls nicht, richtet er dessen `SKILL.md` und
Command-Wrapper für die gewählte Zielumgebung ein und vermerkt den Stand im
Projektmanifest. Bei einer vorhandenen Installation werden lokale Anpassungen
nicht ungefragt überschrieben. `/thread` sichert später abgeschlossene Arbeit
und erzeugt eine Übergabedatei für Codex oder Claude Code; die Regeln stehen
unter [Thread-Übergabe.md](Thread-Übergabe.md).

## Erste Schritte nach Installation

1. `/projektstart` ausführen und das Interview durchlaufen.
2. Bei Rückfragen zu Installationsort (projekt-lokal vs. global) pro Kern-Skill einzeln entscheiden — siehe [SKILL.md](../SKILL.md#schritt-2--kern-skills-installieren).
3. Nach Abschluss `PROJEKT/.projektstart-manifest.json` prüfen — sie ist die Grundlage für spätere `/projektstart-update`-Läufe.
4. Im Alltag `/dashboard` verwenden.
