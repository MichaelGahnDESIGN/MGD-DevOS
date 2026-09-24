# Skill-Katalog (vollständig)

Diese Seite spiegelt `catalog/skills.json` in lesbarer Form. Maßgeblich für den Assistenten ist immer die JSON-Datei — diese Seite ist die kommentierte Referenz dazu.

## Datenstruktur (`catalog/skills.json`)

Jeder Eintrag ist ein Objekt mit mindestens `{name, url, description, category, stars, source, requiresScan, mandatory}`. `source` ist `"mgd"` oder `"third-party-curated"`. `mandatory: true` markiert die verbindlichen Basis-Skills Autopilot und AI-Thread. Vier weitere MGD-Kern-Skills werden im Interview zur Auswahl angeboten; Fach-Skills sind ebenfalls optional.

## MGD-Kern-Skills (vier wählbar, zwei verbindlich; kein Dritt-Skill-Scan)

| Name | Kategorie | Quelle | Installationsziele | Slash-Commands | Abfrage vor Installation |
|---|---|---|---|---|---|
| [MGD_DEV_SKILL](https://github.com/MichaelGahnDESIGN/MGD_DEV_SKILL) | core | mgd | `.claude/commands/`, `.codex/commands/`, `dev/SKILL.md` | `/dev`, `/dev-fast`, `/dev-changelog` | Ja/Nein |
| [Fragenkatalog-Skill](https://github.com/MichaelGahnDESIGN/Fragenkatalog-Skill) | core | mgd | `.claude/commands/fragenkatalog.md`, `.codex/commands/fragenkatalog.md`, `SKILL.md` | `/fragenkatalog-setup` | Ja/Nein |
| [MGD_Todo_SKILL](https://github.com/MichaelGahnDESIGN/MGD_Todo_SKILL) | core | mgd | `.claude/commands/todo.md`, `SKILL.md`, `todo/TODO.template.html` | `/todo-setup`, `/todo-add`, `/todo-edit`, `/todo-link` | Ja/Nein |
| [MGD_Living-Documentation](https://github.com/MichaelGahnDESIGN/MGD_Living-Documentation) | core | mgd | `.claude/skills/living-documentation/` bzw. `~/.claude/skills/living-documentation/` | — (automatische Erkennung) | Ja/Nein |
| [MGD_Autopilot_SKILL](https://github.com/MichaelGahnDESIGN/MGD_Autopilot_SKILL) | orchestrierung | mgd | `.claude/commands/`, `autopilot/`, `~/.claude/skills/autopilot/` | — (wirkt intern auf `/projektstart`) | **keine — verbindlich** |
| [MGD_AI-Thread](https://github.com/MichaelGahnDESIGN/MGD_AI-Thread) | orchestrierung | mgd | `.claude/skills/thread/SKILL.md`, `.claude/commands/thread.md`, `.codex/skills/thread/SKILL.md`, `.codex/commands/thread.md` | `/thread` | **keine — verbindlich** |

Im JSON stehen die vier wählbaren Skills auf `mandatory: false` und Autopilot
sowie AI-Thread auf `mandatory: true`. Der Projektmanager prüft vorhandene
Installationen, bevor er Dateien kopiert.

## Plattform-System (`mandatory: false`, eigene CLI, keine Datei-Kopie, kein Sicherheits-Scan nötig)

| Name | Kategorie | Quelle | Installationsart |
|---|---|---|---|
| [Projekt-Plattform-System](https://github.com/MichaelGahnDESIGN/Projekt-Plattform-System) | platform | mgd | `mgd-platform init --preset <preset> --target <pfad>` |

## Optionale MGD-Fach-Skills (`mandatory: false`)

| Name | Kategorie | Zweck | Wichtige Grenze |
|---|---|---|---|
| [MGD Blogpost Skill](https://github.com/MichaelGahnDESIGN/MGD_Blogpost-Skill) | content-marketing-wordpress | Recherche, Faktencheck, SEO, Beitragsbild und Social-Entwürfe | WordPress standardmäßig nur als Entwurf; Veröffentlichung und Social-Post separat freigeben |
| [MGD JTL OPC Skill](https://github.com/MichaelGahnDESIGN/MGD_JTL-OPC_SKILL) | ecommerce-jtl | JTL-Shop-5-OnPage-Composer automatisieren und prüfen | Publishing ist live; vorher Backup, Zielbereich und Freigabe prüfen |

Die ergänzenden Shopware- und JTL-Shop-Plugins stehen absichtlich nicht in
dieser Skill-Liste: Sie sind installierbare Shop-Komponenten, keine
Agent-Skills. Ihre Quellen und Grenzen stehen im
[`Integrationskatalog`](../catalog/integrations.json).

## Dritt-Skills — kuratierter Startpunkt (`mandatory: false`, Sicherheits-Scan vor jeder Installation Pflicht)

| Name | Beschreibung | Sterne | Kategorie |
|---|---|---|---|
| [Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) | Turn any codebase, with its docs, SQL schemas, configs, and PDFs, into a queryable knowledge graph. Lokale deterministische AST-Analyse, kein Vector-Store. | 120.740 | Code-Analyse/Dokumentation |
| [Klotzkette/claude-fuer-deutsches-recht](https://github.com/Klotzkette/claude-fuer-deutsches-recht) | Experimentelle Skill-Sammlung für deutsches Recht (Arbeits-, Gesellschafts-, Insolvenz-, Datenschutz-, Prozessrecht u.a.). Ausdrücklich KEINE Rechtsberatung; behandelt Mandatsgeheimnis, DSGVO, KI-VO. | 1.615 | Recht (Deutschland) |
| [dickwu/apple-design-skill](https://github.com/dickwu/apple-design-skill) | Cross-Platform UI/UX-Design-Reviewer nach Apple HIG. Funktioniert mit Flutter, Tauri, Electron, React Native. | 770 | Design/UI/UX |
| [affaan-m/agentshield](https://github.com/affaan-m/agentshield) | KI-Agenten-Sicherheitsscanner. Erkennt Schwachstellen in Agent-Konfigurationen, MCP-Servern und Tool-Berechtigungen. CLI, GitHub Action, ECC-Plugin. | 1.214 | Sicherheit (auch selbst Vetting-Tool) |
| [affaan-m/ECC](https://github.com/affaan-m/ECC) | Agent-Harness-Performance-Optimierungssystem. Skills, Instincts, Memory, Security, research-first Development. | 265.856 | Agenten-Framework |
| [WorldFlowAI/everything-claude-code](https://github.com/WorldFlowAI/everything-claude-code) | Claude-Code-Toolkit — Agents, Commands, Skills, Rules und Hooks für produktive KI-gestützte Entwicklung. | 3.494 | Sammlung/Toolkit |
| [Jakeschincariol/promptmaster-skill](https://github.com/Jakeschincariol/promptmaster-skill) | Schreibt Prompts in ein optimiertes Format um, prüft auf 35 Credit-Verschwendungs-Muster. | 8 | Produktivität |
| [NVIDIA/SkillSpector](https://github.com/NVIDIA/SkillSpector) | Sicherheitsscanner für KI-Agenten-Skills. Erkennt Schwachstellen, bösartige Muster, Prompt-Injection, Datenexfiltration und Supply-Chain-Risiken in Claude-Code-/Codex-/MCP-Skills VOR der Installation. | 18.143 | Sicherheit (Skill-Vetting, auch selbst Vetting-Tool) |

Alle Beschreibungen und Sternzahlen sind per GitHub-API zum Stand 2026-09-23 geprüft und werden unverändert übernommen — der Assistent erfindet keine zusätzlichen Fakten zu diesen acht Repos.

## Katalog erweitern

Neue, vom Nutzer selbst geprüfte Dritt-Skills werden über `/projektstart-katalog-add <repo-url> <kategorie>` dauerhaft ergänzt (siehe [Befehle.md](Befehle.md)). Beschreibung und Sternzahl werden dabei live per `gh repo view` abgerufen, nicht frei erfunden.
