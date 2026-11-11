# ai-sync

`ai_sync.py` hält Skills, Slash-Command-Wrapper, MCP-Server und Claude-Plugins für Claude Code und ChatGPT Codex
auf mehreren Macs anhand **einer Manifest-Datei** gleich. Version des Werkzeugs: 0.1.0.

## Voraussetzungen

- macOS mit Python 3 (`/usr/bin/python3` reicht, Python 3.9 genügt, nur Standardbibliothek).
- `git` und Netzzugriff auf GitHub (Skill-Repos werden flach geklont und im Cache gehalten).
- Je nach Manifest die CLIs `claude` (MCP-Server, Plugins) und `codex` (MCP-Server). Für Secrets mit
  `keychain:`-Verweis das macOS-Programm `security`.
- Für den optionalen Hintergrundlauf `launchctl` (LaunchAgent).

## Aufruf

```
python3 ai_sync.py <unterbefehl> [optionen]
```

Ohne Unterbefehl (oder wenn das erste Argument eine Option ist) läuft `plan`.

Gemeinsame Optionen aller Unterbefehle (außer dem internen `agent-run`, der sie ebenfalls kennt):

| Option | Bedeutung |
|---|---|
| `--manifest MANIFEST` | Pfad zur Manifest-Datei (sonst aus der Konfig) |
| `--config CONFIG` | Pfad zur Konfig-Datei (Standard: `<Status-Ordner>/config.json`) |

### Unterbefehle

| Unterbefehl | Wirkung | Weitere Optionen |
|---|---|---|
| `plan` | Trockenlauf (Standard): zeigt Status und geplante Aktion, ändert nichts | – |
| `apply` | führt nur sichere Aktionen aus | `--overwrite SELEKTOR` (lokal geänderten Eintrag mit Backup überschreiben), `--adopt SELEKTOR` (Stempel für identischen Eintrag setzen); beide Optionen sind wiederholbar, siehe Selektoren |
| `export` | Manifest-Entwurf aus dieser Installation (ohne Secrets, Datei mit Rechten 0600) | `--output OUTPUT` (Datei für den Entwurf, sonst Standardausgabe) |
| `report` | maschinenlesbarer JSON-Bericht | `--json DATEI` (Pflicht, Zieldatei) |
| `install-agent` | LaunchAgent anlegen | `--no-load` (nur die plist schreiben, nicht laden) |
| `uninstall-agent` | LaunchAgent entfernen | – |

`agent-run` wird nur vom LaunchAgent benutzt und erscheint nicht in der Hilfe.

### Selektoren für `--overwrite` und `--adopt`

Ein Selektor ist ein reiner Name (`alpha`) oder `kind:name[:target]` (`skill:alpha`, `mcp:svc`, `skill:alpha:claude`).
`kind` ist `skill`, `command`, `mcp` oder `plugin`. Ein Name, der in keinem Manifest-Eintrag vorkommt, ist ein Fehler
(Exit 2, nichts wird angewendet). Ein reiner Name, der auf mehrere Arten passt (z. B. Skill und MCP-Server `alpha`),
ist ebenfalls ein Fehler; dann `kind:name` angeben.

### Exit-Codes

| Code | Bedeutung |
|---|---|
| 0 | alles aktuell, nichts zu tun |
| 1 | Abweichungen, offene Aktionen oder Warnungen (auch Status `blockiert`). Der Status `offen` zählt nicht (Aktion nicht unterstützt, es gibt nichts zu tun) |
| 2 | Fehler (ungültiges Manifest oder Konfig, Netzwerk- oder CLI-Fehler, ungültiger Eintrag, nicht lesbare Konfigdatei, doppelter Manifest-Eintrag, unbekannter Selektor, unerwarteter Fehler) |
| 4 | ein anderer ai-sync-Lauf ist aktiv (Lock-Datei) |

## Manifest

Siehe [`manifest.example.json`](manifest.example.json). Schlüssel, die mit `_` beginnen, sind Hinweise und werden
ignoriert. Das Manifest gehört am besten in ein privates Repo.

```json
{
  "skills":   [{"name": "...", "repo": "...", "path": "...", "targets": ["claude", "codex", "agents"]}],
  "commands": [{"name": "...", "repo": "...", "path": "....md", "targets": ["claude"]}],
  "mcp":      [{"name": "...", "command": "npx", "args": ["..."], "env": {"VAR": "keychain:dienst"}, "targets": ["claude", "codex"]}],
  "plugins":  {"claude": [{"marketplace": "owner/repo", "marketplaceName": "...", "name": "..."}]}
}
```

### Skills (`skills`)

| Feld | Bedeutung |
|---|---|
| `name` | Name des Eintrags (Buchstaben, Ziffern, `.`, `_`, `-`) |
| `repo` | GitHub-Repo, `name` oder `owner/name`; ohne Owner gilt `MichaelGahnDESIGN` |
| `path` | Ordner im Repo (Standard `.`) |
| `ref` | optional: Branch, Tag oder vollständiger Commit-SHA (40 Hex-Zeichen) |
| `targets` | `claude`, `codex`, `agents` (Ziele `~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills`) |
| `installName` | optional: Zielordnername, sonst `name` |

Zwei Einträge mit gleicher Kombination aus Art, `installName` und Ziel sind ungültig (der spätere wird abgelehnt).

### Befehls-Wrapper (`commands`)

Wie Skills, aber `path` zeigt auf eine `.md`-Datei, und erlaubte Ziele sind `claude` und `codex`. Installiert wird
nach `~/.claude/commands/<installName>.md`. Für das Ziel `codex` meldet ai-sync den Status `offen`, weil der
Codex-Prompt-Ort nicht verifiziert ist; Wrapper werden derzeit nur für Claude unterstützt.

### MCP-Server (`mcp`)

`name` (nur Buchstaben, Ziffern, `_`, `-`), `command`, `args`, `env`, `targets` (`claude`, `codex`). Claude-Server werden
mit `claude mcp add -s user` angelegt, Codex-Server mit `codex mcp add`; kennt die Codex-CLI `mcp add` nicht, ändert
ai-sync `~/.codex/config.toml` über einen Fallback-Editor (mit Backup; unbekannte Schlüssel und Kommentare des
vorhandenen Blocks bleiben, das Ergebnis wird nach dem Schreiben erneut geprüft und bei Fehler zurückgespielt).

Freigaben liegen nur in der lokalen Konfig, nie im Manifest:

- `command` muss in `allowedMcpCommands` stehen (Standard `npx`, `uvx`, `node`), sonst Status `blockiert`.
- Jeder `env`-Verweis muss in `allowedSecretRefs` für diesen MCP-Namen freigegeben sein, sonst Status `blockiert`;
  Schlüsselbund und Umgebung werden dann gar nicht gelesen.
- Vor dem Eintragen eines neuen oder geänderten Servers gibt `apply` Befehl und Argumente aus (nie Secret-Werte).
- `--overwrite` sichert den alten Eintrag; schlägt `remove` fehl, wird nichts geändert, schlägt `add` fehl, wird der
  alte Eintrag über die CLI wiederhergestellt und der Fehler gemeldet.
- Ein Codex-Server, dessen Eintrag in `config.toml` nicht gelesen werden kann, hat den Status `unbekannt` und wird nie
  automatisch ersetzt.

### Plugins (`plugins.claude`)

`marketplace` (`owner/repo`), `name`, optional `marketplaceName`. Installiert über `claude plugin marketplace add`
und `claude plugin install`. Ein Plugin gilt nur als vorhanden, wenn sein Marketplace auf das erwartete Repo zeigt
(erkannt wird die Ausgabe von `claude plugin marketplace list --json`, `source: "git"` mit `url` oder `repo`). Zeigt der
Marketplace-Name auf ein anderes Repo, ist der Status `abweichend` bzw. `blockiert` und nichts wird installiert.
Ein Marketplace wird je Lauf höchstens einmal hinzugefügt.

### Erlaubte Quellen (Konfig)

Die Konfig-Datei (`config.json` im Status-Ordner oder per `--config`) kennt diese Schlüssel, Standardwerte in Klammern:

| Schlüssel | Bedeutung |
|---|---|
| `manifest` | Pfad als Text oder Objekt `{"repo": ..., "branch": ..., "path": "manifest.json", "commit": "<SHA>"}` für ein Manifest im GitHub-Repo (Standard: leer) |
| `manifest.commit` | optionaler Pin: vollständiger SHA (40 Hex-Zeichen). Gesetzt, wird genau dieser Stand benutzt (`branch` entfällt); weicht der Stand ab oder fehlt der Commit, bricht ai-sync ab |
| `allowedOwners` | erlaubte GitHub-Owner (`["MichaelGahnDESIGN"]`) |
| `allowedMarketplaces` | erlaubte Plugin-Marketplaces (`["anthropics/claude-plugins-official"]`) |
| `allowedMcpCommands` | erlaubte MCP-Befehle (`["npx", "uvx", "node"]`); andere ergeben Status `blockiert` |
| `allowedSecretRefs` | Objekt Verweis → Liste erlaubter MCP-Namen, z. B. `{"keychain:my-dienst": ["svc"]}` (Standard: leer, also keine Verweise erlaubt) |
| `autoApply` | der LaunchAgent wendet **nur Skills und Commands** an (`false`); MCP-Server und Plugins bleiben dort offene Aktionen und werden nur mit manuellem `apply` eingetragen |
| `notify` | macOS-Hinweis bei Abweichungen durch den LaunchAgent (`true`) |

Repos fremder Owner und Marketplaces außerhalb der Liste werden als `ungueltig` abgelehnt. Das Manifest kann diese
Listen nicht erweitern. `affaan-m/ECC` gehört nicht mehr zu den Standard-Marketplaces; wer das Plugin will, gibt es
ausdrücklich frei:

```json
{
  "manifest": {"repo": "mein-privates-manifest", "path": "manifest.json", "commit": "<vollständiger SHA>"},
  "allowedMarketplaces": ["anthropics/claude-plugins-official", "affaan-m/ECC"],
  "allowedMcpCommands": ["npx", "uvx", "node"],
  "allowedSecretRefs": {"keychain:my-dienst": ["svc"]},
  "autoApply": false
}
```

## Statuswerte

| Status | Bedeutung | geplante Aktion |
|---|---|---|
| `aktuell` | lokal gleich Quelle | keine |
| `fehlt` | lokal nicht vorhanden | installieren |
| `github-neuer` | lokal unverändert seit dem letzten Sync, Quelle ist neuer | aktualisieren |
| `lokal-geaendert` | lokal seit dem letzten Sync verändert | manuell (`--overwrite NAME`) |
| `unbekannt` | kein Stempel, Inhalt weicht ab (oder Ziel ist Symlink oder falscher Typ) | manuell (`--overwrite NAME`) |
| `adoptierbar` | Inhalt identisch, nur der Stempel fehlt | manuell (`--adopt NAME`) |
| `abweichend` | MCP-Server vorhanden, aber Befehl, Argumente oder env-Schlüssel weichen ab (oder Plugin über fremden Marketplace) | manuell (`--overwrite NAME`) |
| `blockiert` | MCP-Befehl oder Secret-Verweis nicht freigegeben, oder Marketplace-Name zeigt auf ein anderes Repo | keine |
| `offen` | Aktion nicht unterstützt (Wrapper für Codex) | keine |
| `warnung` | doppelter Skill-Name, veralteter bzw. verwaister Wrapper, verwaiste `.old-*`-Sicherung, zu offene Rechte einer Konfigdatei | manuell |
| `fehler` | z. B. Quelle nicht erreichbar, Pfad nicht im Repo, Ausführung fehlgeschlagen | keine |
| `ungueltig` | Manifest-Eintrag fehlerhaft oder nicht erlaubt | keine |

Fehlt bei einem MCP-Server ein Secret, steht die Aktion auf `blockiert` und nichts wird installiert. Im Agent-Lauf
(LaunchAgent) sind `env:`-Verweise nicht verfügbar und werden so gemeldet; dort geht nur `keychain:`.

## Secrets

Secrets stehen nie im Manifest. In `env` sind nur Verweise erlaubt:

- `keychain:<dienst>` liest das Secret aus dem macOS-Schlüsselbund (`security find-generic-password -s <dienst>`),
- `env:<VAR>` liest die Umgebungsvariable `VAR`.

Alles andere lehnt ai-sync als ungültig ab. Aufgelöste Werte gehen nur an die offiziellen CLIs und werden aus
Ausgaben, Berichten und Logs entfernt. Jeder Verweis muss zusätzlich in `allowedSecretRefs` für den MCP-Namen
freigegeben sein. `export` schreibt für MCP-Variablen nur `env:<NAME>`-Verweise; MCP-Einträge, deren Argumente nach
Secret aussehen (`key`, `token`, `secret`, `password`, `bearer`, lange Hex-/Base64-Werte, `://user:pw@`), landen ohne
Wertausgabe unter `_nichtZugeordnet`.

### Bekannte Grenzen

- Die offiziellen CLIs bekommen Secrets als Argument (`claude mcp add -e KEY=wert`, `codex mcp add --env KEY=wert`);
  für die Dauer des Aufrufs sind sie in der Prozessliste sichtbar.
- `~/.claude.json` und `~/.codex/config.toml` enthalten eingetragene Secrets im Klartext (so speichern die CLIs).
  ai-sync prüft nach dem Schreiben die Rechte dieser Dateien und meldet eine Warnung, wenn sie nicht 0600 sind; es
  ändert sie nicht.
- Backups des Skill- und Codex-Bestands liegen im Status-Ordner (Rechte 0700/0600). Je Ziel bleiben die letzten 5
  Backups von ai-sync; fremde Dateien dort werden nicht gelöscht.

## Was nie überschrieben wird

- Lokal geänderte oder unbekannte Skills und Wrapper werden nicht angefasst, bis du ausdrücklich `--overwrite NAME`
  angibst. Auch dann entsteht vorher ein Backup unter `<Status-Ordner>/backups/<Datum>/`.
- Abweichende MCP-Server werden nur mit `--overwrite NAME` ersetzt.
- Ist ein Ziel ein Symlink oder hat den falschen Typ (Datei statt Ordner), fasst ai-sync es nicht an.
- `--adopt NAME` setzt nur den Stempel und nur, wenn der Inhalt identisch ist.
- Ein Eintrag aus dem Manifest, der lokal zusätzlich vorhanden ist, wird nie gelöscht; ai-sync entfernt nichts.
- Ein Lock verhindert parallele Läufe (Exit 4).
- Schlägt eine Skill-Aktualisierung mittendrin fehl, wird das alte Ziel zurückbenannt. Bleibt nach einem Abbruch ein
  `.<name>.old-<pid>` liegen, meldet der nächste Lauf es; `apply` stellt es wieder her, wenn das Ziel fehlt.
- Ein kaputtes `command-stamps.json` führt zum Abbruch (Exit 2) statt zum Überschreiben.
- `__pycache__` und `*.pyc` werden bei Skills ignoriert.

Jeder Skill-Ordner erhält eine Stempeldatei `.mgd-ai-sync.json` (Repo, Commit, Datei-Hashes), mit der lokale
Änderungen erkannt werden; Wrapper-Stempel liegen in `<Status-Ordner>/command-stamps.json`.

## Orte

| Was | Pfad |
|---|---|
| Status-Ordner | `~/Library/Application Support/MGD-DevOS/ai-sync` (Rechte 0700, überschreibbar mit der Umgebungsvariable `MGD_AI_SYNC_HOME`) |
| Konfig | `<Status-Ordner>/config.json` |
| Backups | `<Status-Ordner>/backups/` |
| Logs | `<Status-Ordner>/logs/` (`ai-sync.log`, `agent.log`) |
| letzter Agent-Bericht | `<Status-Ordner>/last-report.json` |
| Repo-Cache | `~/Library/Caches/MGD-DevOS/ai-sync` |
| LaunchAgent | `~/Library/LaunchAgents/de.michael-gahn.devos.ai-sync.plist` |

## Einrichtung auf einem zweiten Mac

1. Skill `mgd-devos` bzw. dieses Repo auf den Mac holen (`git` und Python 3 vorhanden, `claude` und `codex`
   nach Bedarf installiert und angemeldet).
2. Manifest bereitstellen: entweder die Datei des ersten Macs kopieren oder dort einen Entwurf erzeugen:
   `python3 ai_sync.py export --output manifest.json`. Entwurf prüfen, nicht gewünschte Einträge entfernen,
   `env:`-Verweise kontrollieren und Einträge unter `_nichtZugeordnet` von Hand klären.
3. Secrets auf dem zweiten Mac anlegen, die das Manifest per `keychain:<dienst>` oder `env:<VAR>` erwartet.
4. Optional eine `config.json` im Status-Ordner anlegen und dort `manifest` setzen (und bei fremden Quellen
   `allowedOwners` bzw. `allowedMarketplaces` ergänzen). Alternativ bei jedem Aufruf `--manifest` angeben.
5. Trockenlauf: `python3 ai_sync.py plan --manifest manifest.json`.
6. Sichere Aktionen ausführen: `python3 ai_sync.py apply --manifest manifest.json`. Für bereits vorhandene,
   identische Einträge ohne Stempel einmalig `--adopt NAME`.
7. Optional täglicher Abgleich: `python3 ai_sync.py install-agent --manifest manifest.json` (bzw. `--config`, wird
   in die plist übernommen). Der LaunchAgent läuft täglich um 09:30 und bei der Anmeldung und führt nur `plan` aus,
   außer `autoApply` ist `true` (dann nur Skills und Commands). Entfernen mit `python3 ai_sync.py uninstall-agent`.

   `install-agent` verweigert die Installation, wenn `ai_sync.py` unter `~/.claude/skills`, `~/.codex/skills` oder
   `~/.agents/skills` liegt, weil ai-sync diese Ordner selbst aktualisiert. Weg: Skript an einen festen Ort
   außerhalb kopieren (z. B. `~/Library/Application Support/MGD-DevOS/ai-sync/bin/ai_sync.py`) und von dort
   `install-agent` aufrufen. In der plist stehen ein fester PATH aus den absoluten Ordnern von `git`, `claude`,
   `codex` plus `/usr/bin:/bin`; liegt einer dieser Ordner für Gruppe oder Welt beschreibbar, bricht die Installation
   ab. `security`, `osascript` und `launchctl` werden mit absolutem Pfad aufgerufen.

## Testaufruf

Hilfe und Trockenlauf, ohne etwas zu verändern:

```
python3 ai_sync.py --help
python3 ai_sync.py plan --manifest manifest.example.json
```

Die Offline-Tests (temporäres HOME, lokale Git-Repos als Fake-GitHub, Fake-CLIs) liegen in
`tests/test_ai_sync.py`:

```
python3 -m unittest discover -s tests
```

Befehl im Agenten: `/ai-sync` (Wrapper in `.claude/commands/ai-sync.md` und `.codex/commands/ai-sync.md`).
