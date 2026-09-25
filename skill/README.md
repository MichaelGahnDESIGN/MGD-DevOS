# MGD-DevOS

Die zentrale AI-Dev-OS-Projektzentrale für ChatGPT Codex, Claude Code und
kompatible Agenten.

> **Ein Projekt. Ein klarer Stand. Ein geführter nächster Schritt.**

Version <!-- mgd:version -->0.6.0 Pre-Alpha<!-- /mgd:version --> – gemeinsam mit der
[MGD-DevOS-App](../README.md), einzige Quelle ist `assets/meta/version.json`.

[Deutsch](README.md) · [English](docs/i18n/README.en.md) · [Español](docs/i18n/README.es.md) · [Français](docs/i18n/README.fr.md) · [Wiki](wiki/Home.md) · [Release](https://github.com/MichaelGahnDESIGN/MGD-DevOS/releases)

Der MGD-DevOS hilft dir, ein Projekt neu zu beginnen, ein
bestehendes Projekt sicher zu ordnen oder ein größeres Produkt wie Spiel,
Plattform, Website oder App langfristig zu steuern. Er verbindet Menschen,
Agenten und Spezial-Skills, ohne den Überblick, Datenschutz oder Tokenbudget zu
verlieren.

## Einrichten und Starten

Gib deinem Assistenten (Claude Code, ChatGPT Codex oder ein kompatibler
Agent) diesen Text:

```text
Einrichten und Starten: Installiere den Skill aus
https://github.com/MichaelGahnDESIGN/MGD-DevOS,
starte danach /projektstart und richte gemeinsam mit mir Projektordner, Todo,
Living Documentation und Skills ein. Öffne am Ende das Dashboard, lege nach
meiner Bestätigung eine Verknüpfung auf den Desktop und erkläre mir, wie ich
damit arbeite.
```

Install-Befehl (Claude Code, global) und Start:

```bash
git clone --depth 1 https://github.com/MichaelGahnDESIGN/MGD-DevOS.git /tmp/mgd-devos
mkdir -p ~/.claude/skills/mgd-devos ~/.claude/commands
cp -R /tmp/mgd-devos/skill/. ~/.claude/skills/mgd-devos/
cp ~/.claude/skills/mgd-devos/.claude/commands/*.md ~/.claude/commands/
```

Das installiert alle Befehle: `/projektstart`, `/projektstart-update`, `/projektstart-katalog`,
`/projektstart-katalog-add` und `/dashboard`. Start im Assistenten: `/projektstart` (Einrichtung), danach `/dashboard`.
Codex und projekt-lokale Variante: [wiki/Setup.md](wiki/Setup.md).

## In einer Minute verstehen

1. Starte mit `/dashboard`.
2. Der Assistent liest Regeln, Dokumentation und tatsächlichen Git-Stand.
3. Er zeigt verständlich, was bestätigt, offen oder riskant ist.
4. Er schlägt nur die Skills und MCPs vor, die zum Projekt passen.
5. Er arbeitet in kleinen Schritten, prüft Ergebnisse und dokumentiert Grenzen.

Du entscheidest weiterhin über Installationen, externe Verbindungen, Pushes,
Deployments und Löschungen.

**Projektstart mit MGD-DevOS: ein Assistent, der ein neues Projekt in einem Rutsch mit allen passenden MGD- und Dritt-Skills ausstattet — sicher vorgeprüft, nicht blind installiert.**

## Problem & Vision

Jedes neue Projekt beginnt mit denselben Fragen: Wie heißt es, was ist der Umfang, welche Skills braucht es (Design, Programmierung, Recht, Sicherheit), und wie richtet man Dokumentation und Todo-Struktur sauber ein? Meist wird das manuell, unvollständig und jedes Mal wieder neu gemacht. Dritt-Skills werden dabei oft ungeprüft installiert, weil eine Sicherheitsprüfung zusätzlicher Aufwand ist, den man beim Projektstart gerne überspringt.

`MGD-DevOS` löst das in einer geführten Projektzentrale:

1. Interview zu den Projektdaten.
2. Vier wählbare MGD-Skills und die Basis-Skills Autopilot und AI-Thread
   einrichten.
3. Empfehlung des eigenständigen [MGD-Plattform-Builders](https://github.com/MichaelGahnDESIGN/MGD-Plattform-Builder) bei Web- und Plattform-Projekten.
4. Vorschlag passender Domain-Skills — zuerst aus einem kuratierten Startkatalog, danach optional per Live-Suche auf GitHub.
5. **Pflicht-Sicherheits-Scan** jedes Dritt-Skills vor der Installation.
6. Automatisches Eintragen der Projektdetails in alle installierten Skills.
7. Abschluss-Zusammenfassung — und ein Updater (`/projektstart-update`), der später den Stand aller installierten Skills mit den Quell-Repos vergleicht.
8. Ein lokales Dashboard (`/dashboard`) als zentrale Sicht für Stand, Risiken,
   Skills und nächste Schritte.

`/projektstart` richtet ein Projekt ein, `/dashboard` ist die tägliche
Projektzentrale. Der Assistent arbeitet nach dem Autopilot-Prinzip: Vertrag,
Validierung nach Änderungen und harte Leitplanken. Details siehe
[SKILL.md](SKILL.md) und [wiki/Sicherheitskonzept.md](wiki/Sicherheitskonzept.md).

## Installation

Siehe [wiki/Setup.md](wiki/Setup.md) für die ausführliche Anleitung (Claude Code + Codex, projekt-lokal vs. global). Kurzfassung, global für Claude Code:

```bash
git clone --depth 1 https://github.com/MichaelGahnDESIGN/MGD-DevOS.git /tmp/mgd-devos
mkdir -p ~/.claude/skills/mgd-devos ~/.claude/commands
cp -R /tmp/mgd-devos/skill/. ~/.claude/skills/mgd-devos/
cp ~/.claude/skills/mgd-devos/.claude/commands/*.md ~/.claude/commands/
```

## Erste Schritte

```
/dashboard
```

öffnet oder erstellt die zentrale Projektzentrale. Sie erklärt am Ende in
einfachen Worten, wie die Skills im jeweiligen Projekt zusammenarbeiten.
`/projektstart` startet weiterhin das ausführliche Interview.

## Befehle

| Befehl | Zweck |
|---|---|
| `/dashboard` | Zentrale AI-Dev-OS-Ansicht: Stand, Risiken, Skills, nächste Schritte und Einstellungen |
| `/projektstart` | Geführter Assistent: Interview → MGD-Skills (inkl. Autopilot und AI-Thread) → MGD-Plattform-Builder bei Web-/Plattform-Projekten → Domain-Skills → Sicherheits-Scan → Details eintragen → Zusammenfassung → `/dashboard` |
| `/thread` | Belegte Übergabe an einen neuen Codex- oder Claude-Code-Thread; fertige Änderungen werden vorher gemäß Projektregeln gesichert und gepusht |
| `/projektstart-update` | Vergleicht installierte Skill-Stände (`PROJEKT/.projektstart-manifest.json`) mit dem aktuellen Stand der Quell-Repos und bietet gezielte Updates an |
| `/projektstart-katalog` | Zeigt den kuratierten Startkatalog formatiert an, mit Kategorie-Filter |
| `/projektstart-katalog-add <repo-url> <kategorie>` | Fügt einen manuell geprüften Dritt-Skill dauerhaft zum Startkatalog hinzu |

Details und Beispiel-Dialoge: [wiki/Befehle.md](wiki/Befehle.md).

## Dokumentation für GitHub und Gitea

Der enthaltene Skill
[`repository-documentation`](skills/repository-documentation/SKILL.md) erstellt
und pflegt professionelle READMEs, Wikis, Demos und Übersetzungen. Er arbeitet
mit GitHub- oder Gitea-Repositories, hält die Markdown-Quellen im Hauptprojekt
kanonisch und synchronisiert eine externe Wiki erst nach Link-, Sichtbarkeits-
und Secret-Prüfung.

## Dashboard, Farben und Einstellungen

Jedes vom Projektmanager erzeugte Dashboard hat oben rechts ein zugängliches
Zahnrad. Dort lassen sich Light-, Dark- oder Systemmodus, die Akzentfarbe und
der bevorzugte Öffnungsort wählen. Voreinstellungen sind **Codex Grün**,
**Claude Orange**, **Allgemein Blau** oder eine eigene Farbe. Die Darstellung
wird lokal im Browser gespeichert; die Einstellung für internen Browser,
Standardbrowser oder Rückfrage gehört zusätzlich in
`PROJEKT/.mgd-ai-projektmanager.json`.

Das Dashboard ist statisches HTML ohne CDN, Tracking oder Datenbank. In Codex
kann es – sofern die jeweilige Oberfläche das anbietet – als Site und in Claude
Code als Artefakt angezeigt werden. Die `index.html` im Projekt bleibt immer
die portable, kanonische Quelle.

## Sicheres Übernehmen bestehender Projekte

Der Projektmanager prüft Regeln, Git-Status, Dokumentation, vorhandene Skills,
`.gitignore` und bestehende Dashboards, bevor er etwas ergänzt. Er führt keine
parallele zweite Dokumentationswelt ein und entfernt keine Skills automatisch.
Der frühere `project-start-assistant` aus MGD Living Documentation ist deshalb
kein zweiter Projektmanager mehr: er verweist kompatibel auf dieses Repository.
Eine vollständige Migrations-Checkliste steht in [wiki/Migration.md](wiki/Migration.md).

Er legt außerdem `SECRETS/` und `USER CONCEPT/` mit passenden
`.gitignore`-Regeln an. `SECRETS/` ist ohne konkrete Pfadfreigabe tabu.
`USER CONCEPT/` bewahrt lokale Ideen; benötigte Dateien werden nur kopiert.

## Sicherheit: Kein blindes Installieren

Der Owner hat sich bewusst für **Live-GitHub-Suche** statt einer rein kuratierten Liste entschieden, um auch neue, nicht vorab bekannte Skills zu finden. Damit das nicht auf Kosten der Sicherheit geht, gilt für **jeden** Dritt-Skill (kuratiert oder live gefunden), der nicht aus `github.com/MichaelGahnDESIGN/*` stammt:

1. Der Skill wird in ein temporäres Verzeichnis geklont — **nicht** direkt ins Projekt.
2. Er wird mit [`NVIDIA/SkillSpector`](https://github.com/NVIDIA/SkillSpector) und/oder [`affaan-m/agentshield`](https://github.com/affaan-m/agentshield) gescannt (beide sind selbst Teil des kuratierten Katalogs).
3. Die Findings werden vollständig angezeigt.
4. Erst nach expliziter Bestätigung ("trotzdem installieren? ja/nein") wird tatsächlich installiert.
5. Ohne verfügbaren Scanner (z. B. kein Netzzugriff) installiert der Assistent **nicht automatisch** — er warnt ausdrücklich, dass ungeprüft installiert würde, und verlangt eine zusätzliche, gesonderte Bestätigung.

Innerhalb dieses Ablaufs wirkt der Autopilot-Mechanismus als Leitplanke: schlägt ein Scan fehl, wird der Sicherheits-Scan abgelehnt, oder landet eine erwartete Datei nicht korrekt im Projekt, bricht `/projektstart` den betroffenen Schritt sofort ab, statt mit einem unklaren Zwischenstand weiterzumachen. Ausführlich: [wiki/Sicherheitskonzept.md](wiki/Sicherheitskonzept.md).

## Katalog

### MGD-Kern-Skills (vier wählbar, zwei verbindlich)

| Skill | Beschreibung | Kategorie |
|---|---|---|
| [MGD_DEV_SKILL](https://github.com/MichaelGahnDESIGN/MGD_DEV_SKILL) | Release/Sync/Backup/Cleanup/Tests/Wissensdokumentation | core |
| [Fragenkatalog-Skill](https://github.com/MichaelGahnDESIGN/Fragenkatalog-Skill) | Interaktiver Design-Fragenkatalog mit KI-Antworten aus wählbarer Experten-Perspektive, inkl. Recht-Kategorie mit ⚖️-Disclaimer | core |
| [MGD_Todo_SKILL](https://github.com/MichaelGahnDESIGN/MGD_Todo_SKILL) | Selbst-gehostete TODO.html mit Bearbeiten-Funktion und Dokument-Verknüpfung | core |
| [MGD_Living-Documentation](https://github.com/MichaelGahnDESIGN/MGD_Living-Documentation) | Lebendige Projektdokumentation (Entscheidungen, offene Punkte, Risiken, Testnachweise) | core |
| [MGD_Autopilot_SKILL](https://github.com/MichaelGahnDESIGN/MGD_Autopilot_SKILL) | KI-Agent arbeitet ein Projektziel unbeaufsichtigt ab und merkt selbst, wenn er danebenliegt — Vertrag vor Start, Validierung nach jeder Änderung, zehn Härtungsregeln, harte Sicherheitsleitplanken. Liefert das Prinzip, nach dem `/projektstart` selbst abläuft. | orchestrierung |
| [MGD_AI-Thread](https://github.com/MichaelGahnDESIGN/MGD_AI-Thread) | Schreibt mit `/thread` eine ehrliche Übergabe und sichert zuvor fertige, geprüfte Arbeit im vorgesehenen Git-Remote. | orchestrierung |

`MGD_DEV_SKILL`, Fragenkatalog, Todo und Living Documentation werden im
Interview angeboten. Autopilot und AI-Thread gehören standardmäßig zum
Projektstart; vorhandene Installationen werden zuerst geprüft.

### MGD-Plattform-Builder (eigene CLI, kein Sicherheits-Scan nötig)

| Skill | Beschreibung | Kategorie |
|---|---|---|
| [MGD-Plattform-Builder](https://github.com/MichaelGahnDESIGN/MGD-Plattform-Builder) | Empfohlen für Websites und Plattformen: Referenz-System mit Backoffice, Rechten, Rechtstexten und Versionierung, eigene CLI `mgd-platform` (`init --preset`, `validate`, `doctor`, `audit`, `release-check`, `module create`, `update`). Die MGD-DevOS-App zeigt Version und Status solcher Projekte (`MGD_PLATFORM.yml`, `version.json`) an. | platform |

### Optionale MGD-Fach-Skills

| Skill | Beschreibung | Kategorie |
|---|---|---|
| [MGD Blogpost Skill](https://github.com/MichaelGahnDESIGN/MGD_Blogpost-Skill) | Recherche, Faktencheck, SEO, Beitragsbild sowie Facebook- und Instagram-Entwürfe; WordPress-Schreibzugriff legt standardmäßig nur einen Entwurf an. | Content/WordPress |
| [MGD JTL OPC Skill](https://github.com/MichaelGahnDESIGN/MGD_JTL-OPC_SKILL) | Kontrollierte JTL-Shop-5-OnPage-Composer-Automation; eine Veröffentlichung ist eine Live-Aktion und benötigt Backup plus Freigabe. | E-Commerce/JTL |

### Dritt-Skills — kuratierter Startpunkt (Sicherheits-Scan vor Installation Pflicht)

| Repo | Beschreibung | Sterne | Kategorie |
|---|---|---|---|
| [Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) | Turn any codebase, with its docs, SQL schemas, configs, and PDFs, into a queryable knowledge graph. Lokale deterministische AST-Analyse, kein Vector-Store. | 120.740 | Code-Analyse/Dokumentation |
| [Klotzkette/claude-fuer-deutsches-recht](https://github.com/Klotzkette/claude-fuer-deutsches-recht) | Experimentelle Skill-Sammlung für deutsches Recht (Arbeits-, Gesellschafts-, Insolvenz-, Datenschutz-, Prozessrecht u.a.). Ausdrücklich KEINE Rechtsberatung; behandelt Mandatsgeheimnis, DSGVO, KI-VO. | 1.615 | Recht (Deutschland) |
| [dickwu/apple-design-skill](https://github.com/dickwu/apple-design-skill) | Cross-Platform UI/UX-Design-Reviewer nach Apple HIG. Funktioniert mit Flutter, Tauri, Electron, React Native. | 770 | Design/UI/UX |
| [affaan-m/agentshield](https://github.com/affaan-m/agentshield) | KI-Agenten-Sicherheitsscanner. Erkennt Schwachstellen in Agent-Konfigurationen, MCP-Servern und Tool-Berechtigungen. CLI, GitHub Action, ECC-Plugin. | 1.214 | Sicherheit |
| [affaan-m/ECC](https://github.com/affaan-m/ECC) | Agent-Harness-Performance-Optimierungssystem. Skills, Instincts, Memory, Security, research-first Development. | 265.856 | Agenten-Framework |
| [WorldFlowAI/everything-claude-code](https://github.com/WorldFlowAI/everything-claude-code) | Claude-Code-Toolkit — Agents, Commands, Skills, Rules und Hooks für produktive KI-gestützte Entwicklung. | 3.494 | Sammlung/Toolkit |
| [Jakeschincariol/promptmaster-skill](https://github.com/Jakeschincariol/promptmaster-skill) | Schreibt Prompts in ein optimiertes Format um, prüft auf 35 Credit-Verschwendungs-Muster. | 8 | Produktivität |
| [NVIDIA/SkillSpector](https://github.com/NVIDIA/SkillSpector) | Sicherheitsscanner für KI-Agenten-Skills. Erkennt Schwachstellen, bösartige Muster, Prompt-Injection, Datenexfiltration und Supply-Chain-Risiken in Claude-Code-/Codex-/MCP-Skills VOR der Installation. | 18.143 | Sicherheit (Skill-Vetting) |

Vollständige, maschinenlesbare Liste: [`catalog/skills.json`](catalog/skills.json). Formatierte, kommentierte Ansicht: [wiki/Skill-Katalog.md](wiki/Skill-Katalog.md).

## Kompetenz-Matrix für jedes Projekt

Neben einzelnen Skills nutzt der Projektmanager eine geführte
[Kompetenz-Matrix](wiki/Kompetenz-Matrix.md). Sie hilft, passende Fachbereiche
auszuwählen: Godot, Unity, Unreal, Affinity, Apple-Programme, Tabellen,
Datenbanken, Docker/Staging/Backups, WordPress, Divi 5, Plugin-Entwicklung,
AI-Knowledge, Graphify sowie Facebook und Instagram über freigegebene
Meta-Schnittstellen.

Der Katalog installiert oder verbindet nichts automatisch. Der Assistent
erklärt Nutzen, Berechtigungen, Datenschutz, Kosten und mögliche Risiken;
erst danach entscheidet der Nutzer. So wird der Manager mit dem Projekt
präziser, ohne zu einem unkontrollierbaren Sammelsurium zu werden.

## Content, Blog und E-Commerce

Der Projektmanager enthält mit
[`commerce-content`](skills/commerce-content/SKILL.md) eine geführte Auswahl
für WordPress-Blogs, Shopware 6, JTL-Shop 5, Shopify und WooCommerce. Der
[MGD Blogpost Skill](https://github.com/MichaelGahnDESIGN/MGD_Blogpost-Skill)
wird für Recherche, Faktencheck, SEO, Beitragsbild und Entwürfe für Facebook
und Instagram vorgeschlagen. Mit WordPress-Schreibzugriff wird dabei
standardmäßig nur ein Entwurf erstellt.

Für Shopware und JTL-Shop führt
[`catalog/integrations.json`](catalog/integrations.json) die passenden,
öffentlichen MGD-Plugins und den JTL-OPC-Skill mit ihren jeweiligen Grenzen.
Shopify und WooCommerce sind ebenfalls als Plattformpfade abgedeckt. Zum
aktuellen Katalogstand gibt es für beide jedoch kein eindeutig zuordenbares
öffentliches MGD-Skill-Repository; der Assistent prüft daher zuerst den
vorhandenen Shop statt eine unklare Erweiterung zu behaupten oder zu
installieren.

## MGD-DevOS-Desktop-App

Die [MGD-DevOS-App](../README.md) ist die lokale Flutter-Desktop-Anwendung für
macOS, Windows und Linux im selben Repository. Sie zeigt die Dashboards aller
Projekte in Tabs, ein Projektregister und einen Agentengraphen aus echten
Projektdateien. Sie ist keine zweite Agenten-Runtime; weitere Ansichten (Docker,
Backups, Live-Adapter) beschreibt der [Architekturentwurf](docs/mgd-devos/ARCHITEKTUR.md).

Sie arbeitet local-first ohne Telemetrie und hat einen optionalen
PIN-Sichtschutz beim Start (nur gegen neugierige Blicke, kein Zugriffsschutz). Secrets gehören in den Schlüsselbund des Betriebssystems,
nicht in Git oder eine Flutter-Datenbank. Die separate
[Stripe-Spendenkonzeption](docs/mgd-devos/STRIPE-SPENDEN.md) nutzt ausschließlich
Stripe-gehostete Zahlungsseiten; MGD-DevOS verarbeitet keine Kartendaten.

## Wiki

| Seite | Inhalt |
|---|---|
| [Home](wiki/Home.md) | Einstieg, Konzept-Übersicht |
| [Befehle](wiki/Befehle.md) | Alle Slash-Befehle im Detail mit Beispiel-Dialogen |
| [Sicherheitskonzept](wiki/Sicherheitskonzept.md) | Der Scan-vor-Installation-Workflow im Detail |
| [Skill-Katalog](wiki/Skill-Katalog.md) | Vollständige, kommentierte Katalog-Tabelle |
| [Setup](wiki/Setup.md) | Installationsanleitung Claude Code + Codex |
| [Updater](wiki/Updater.md) | Funktionsweise von `/projektstart-update` |
| [Beispiel-Ablauf](wiki/Beispiel-Ablauf.md) | Durchgespieltes Beispiel: Mobile-Game-Projekt |
| [Dashboard](wiki/Dashboard.md) | Farben, Einstellungen, `/dashboard` und Browser-Präferenz |
| [Migration](wiki/Migration.md) | Bestehende Projekte ohne doppelte Struktur übernehmen |
| [Kompetenz-Matrix](wiki/Kompetenz-Matrix.md) | Auswahl für Engines, Design, Office, Daten, CMS und Social Media |
| [Thread-Übergabe](wiki/Thread-Übergabe.md) | `/thread`, Git-Sicherung und Startprompt für den nächsten Agenten |
| [Commerce und Content](skills/commerce-content/SKILL.md) | Blog- und E-Commerce-Workflows mit klaren Live-Grenzen |
| [MGD-DevOS-Architektur](docs/mgd-devos/ARCHITEKTUR.md) | Lokale Flutter-Zentrale mit Agentic Control Panel und Datenschutzmodell |
| [Stripe-Spendenmodul](docs/mgd-devos/STRIPE-SPENDEN.md) | Sicheres Design für Spenden, Belege und Rechnungszugriff |

## Grenzen

- Die Live-GitHub-Suche findet nur öffentliche Repos und ist auf die Qualität der GitHub-Suche/`gh`-CLI angewiesen — sie ersetzt keine vollständige Marktübersicht.
- Der Sicherheits-Scan (SkillSpector/agentshield) ist eine Heuristik, kein Garant für Fehlerfreiheit — bei sicherheitskritischen Projekten wird zusätzlich eine manuelle Prüfung empfohlen.
- Rechts-Inhalte (z. B. aus `Klotzkette/claude-fuer-deutsches-recht` oder dem Fragenkatalog-Skill) sind ausdrücklich **keine Rechtsberatung**.
- `/projektstart-update` erkennt nur Skills, die über sein eigenes Manifest installiert wurden — manuell installierte oder fremd verwaltete Skills werden nicht erfasst.
- Ohne `gh`-CLI und Netzzugriff sind Live-Suche, Metadaten-Abfragen und Update-Checks nicht möglich.

## Verwandte MGD Projekte

| Projekt | Beschreibung |
|---|---|
| [MGD_DEV_SKILL](https://github.com/MichaelGahnDESIGN/MGD_DEV_SKILL) | Release/Sync/Backup/Cleanup/Tests/Wissensdokumentation für laufende Projekte |
| [Fragenkatalog-Skill](https://github.com/MichaelGahnDESIGN/Fragenkatalog-Skill) | Interaktiver Design-Fragenkatalog mit KI-Antworten aus wählbarer Experten-Perspektive |
| [MGD_Todo_SKILL](https://github.com/MichaelGahnDESIGN/MGD_Todo_SKILL) | Selbst-gehostete TODO.html mit Bearbeiten-Funktion und Dokument-Verknüpfung |
| [MGD_Living-Documentation](https://github.com/MichaelGahnDESIGN/MGD_Living-Documentation) | Lebendige Projektdokumentation (Entscheidungen, offene Punkte, Risiken, Testnachweise) |
| [MGD_Autopilot_SKILL](https://github.com/MichaelGahnDESIGN/MGD_Autopilot_SKILL) | Unbeaufsichtigtes Abarbeiten eines Projektziels mit Vertrag, Validierung nach jeder Änderung und Sicherheitsleitplanken |
| [MGD_AI-Thread](https://github.com/MichaelGahnDESIGN/MGD_AI-Thread) | Nachvollziehbare Übergabe zwischen Codex und Claude Code mit Git-Sicherung fertiger Arbeit |
| [MGD-Plattform-Builder](https://github.com/MichaelGahnDESIGN/MGD-Plattform-Builder) | Eigenständiges Referenz-System für Websites und Plattformen mit CLI `mgd-platform` |

## Release-Paket

Ein reproduzierbares ZIP-Paket mit SHA-256-Prüfsumme erzeugst du nach einem
Release-Commit mit `./scripts/build-release-package.sh <version>`. Das Paket
stammt aus `git archive`; lokale, ignorierte Dateien und Secrets werden nicht
aufgenommen. Thread-Übergaben unter `UEBERGABEN/` bleiben in der
Git-Historie nachvollziehbar, werden aber nicht ins allgemeine Release-ZIP
gepackt.

## Lizenz

MGD-Lizenz 1.0 — siehe [LICENSE](LICENSE) und [NOTICE](NOTICE). Das Label „powered by: Michael Gahn DESIGN" mit
Logo und Link in Dashboards bleibt immer erhalten. Frühere Versionen bleiben unter der Lizenz, unter der sie
veröffentlicht wurden.

## Impressum

Impressum des Herausgebers: [michael-gahn.de/impressum](https://michael-gahn.de/impressum).
[IMPRESSUM.md](IMPRESSUM.md) ist eine Vorlage mit Platzhaltern für dein eigenes Projekt.
