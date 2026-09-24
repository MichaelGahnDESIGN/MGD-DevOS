# Setup

## Voraussetzungen

- `git`
- [GitHub CLI `gh`](https://cli.github.com/), authentifiziert (`gh auth login`) — nötig für Live-Suche, Metadaten-Abfragen (`/projektstart-katalog-add`) und Update-Checks (`/projektstart-update`).
- Netzzugriff für Clone- und Scan-Schritte. Ohne Netzzugriff funktioniert `/projektstart` weiterhin, verlangt bei Dritt-Skills aber die explizite Ungeprüft-Bestätigung (siehe [Sicherheitskonzept.md](Sicherheitskonzept.md)).

## Installation für Claude Code

### Projekt-lokal (empfohlen, wenn dieser Skill nur in einem Projekt genutzt wird)

```bash
mkdir -p .claude/commands
git clone --depth 1 https://github.com/MichaelGahnDESIGN/MGD-DevOS.git /tmp/mgd-devos
cp /tmp/ai-projektstart-install/.claude/commands/projektstart.md .claude/commands/
cp -r /tmp/ai-projektstart-install/catalog .
cp /tmp/ai-projektstart-install/SKILL.md .
```

### Global (empfohlen, wenn `/projektstart` in jedem neuen Projekt verfügbar sein soll)

```bash
mkdir -p ~/.claude/skills/projektstart
git clone --depth 1 https://github.com/MichaelGahnDESIGN/MGD-DevOS.git /tmp/mgd-devos && cp -R /tmp/mgd-devos/skill ~/.claude/skills/mgd-devos
```

Claude Code erkennt `SKILL.md` in `~/.claude/skills/projektstart/` automatisch; der Slash-Befehl `/projektstart` steht danach in jedem Projekt zur Verfügung, sobald zusätzlich der Wrapper aus `.claude/commands/projektstart.md` global unter `~/.claude/commands/` abgelegt wird:

```bash
mkdir -p ~/.claude/commands
cp ~/.claude/skills/projektstart/.claude/commands/projektstart.md ~/.claude/commands/
```

## Installation für Codex

Analog, mit `.codex/`-Pfaden:

```bash
mkdir -p .codex/commands
cp /tmp/ai-projektstart-install/.codex/commands/projektstart.md .codex/commands/
```

Für eine globale Codex-Installation die entsprechenden globalen Codex-Skill-/Command-Verzeichnisse verwenden (siehe Codex-eigene Dokumentation zu Custom Commands).

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
