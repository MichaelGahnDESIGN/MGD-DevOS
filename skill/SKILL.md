---
name: mgd-devos
description: Zentrale AI-Dev-OS-Projektzentrale für neue und bestehende Projekte. Verwenden für Projektstart, Migration, /dashboard, Skill-Audit, sichere Installation und Projektkoordination.
---

# MGD-DevOS

Version <!-- mgd:version -->0.6.0 Pre-Alpha<!-- /mgd:version --> – der Skill trägt dieselbe Version wie die
MGD-DevOS-App (einzige Quelle: `assets/meta/version.json` im Repository).

Der MGD-DevOS ist die zentrale Projektmanagement-Schicht für
ChatGPT Codex, Claude Code und kompatible Agenten. Er verbindet Projektstart,
Bestandsprojekt-Audit, Skill-Vetting, Living Documentation, Todo, Autopilot, Thread,
Release und ein lokales Dashboard zu einem nachvollziehbaren AI-Dev-OS.

`/projektstart` richtet ein Projekt ein. Die tägliche Projektzentrale ist
`/dashboard`. Alle Befehle werden kleingeschrieben: `/projektstart`,
`/projektstart-update`, `/projektstart-katalog`, `/projektstart-katalog-add`,
`/dashboard`.

## `/dashboard` – zentrale Projektzentrale

Beim Aufruf prüfe zuerst, ob im Projekt eine `index.html` und die Datei
`PROJEKT/.mgd-ai-projektmanager.json` vorhanden sind. Fehlen sie, richte sie
aus `dashboard/index.html` und `dashboard/settings.template.json` ein. Die
Datei im Projekt ist die kanonische, portable Dashboard-Quelle.

Das Dashboard zeigt mindestens Projektstand, offene Punkte, Risiken, aktive
Skills, nächste Schritte sowie die kurzen Sätze „So arbeitet dein Assistent“.
Es darf keine Secrets, personenbezogenen Daten oder privaten Serverdetails
anzeigen.

Die Vorlage ist eine Programm-Oberfläche mit Ansichten statt verlinkter
Unterseiten. Verlinke im Dashboard nur Dateien, die im Projekt wirklich
existieren (z. B. in `{{KANONISCHE_DOKUMENTATION}}`).

Zusätzliche Platzhalter der Vorlage (leer lassen, wenn nicht vorhanden; nie erfinden):
`{{ARBEITENDE_AGENTEN}}` (zuletzt beobachtete Agenten, kein Live-Status), `{{GRUNDREGELN}}` (Inhalt von
`GRUNDREGELN.md`), `{{TODO_DATEI}}`, `{{FRAGENKATALOG_DATEI}}`, `{{LIVING_DOKU_DATEI}}` (nur relative Pfade im
Projekt, z. B. `TODO.html`). Die Metadaten (Version, Versionen, Credits) setzt `scripts/sync_meta.py` im Repo, nicht der
Assistent. Den PIN-Sichtschutz im Dashboard (nur gegen neugierige Blicke, kein Zugriffsschutz) richtet nur der Nutzer selbst ein.

**Pflicht-Label:** Jede `index.html` (Dashboard) trägt unten das Label
„powered by: Michael Gahn DESIGN" mit Logo und Link auf https://michael-gahn.de,
der in einem neuen Tab öffnet (`target="_blank" rel="noopener noreferrer"`;
Element mit `data-mgd-powered-by`, in `dashboard/index.html` enthalten). Es ist
Bedingung der MGD-Lizenz (siehe `LICENSE`, Abschnitt 3). Der Assistent entfernt,
verdeckt oder verändert es nie. Fehlt es in einem bestehenden Dashboard oder
steht dort noch der alte Hinweis mit `data-mgd-supported-by`, ersetzt er ihn
durch das Label aus der Vorlage.

Ob es im internen Browser des Werkzeugs oder im Standardbrowser geöffnet wird, steuert
`dashboardOpenTarget` in der Projekt-Konfiguration. Respektiere die Einstellung:

- `internal`: sofern das jeweilige Tool einen sicheren internen Browser hat;
- `external`: nur auf ausdrücklichen Wunsch oder gemäß gespeicherter
  Einstellung im Standardbrowser;
- `ask`: die Präferenz einmal erfragen und anschließend in der Konfiguration
  dokumentieren.

Die Einstellungen oben rechts im Dashboard steuern Light/Dark/System-Modus,
Akzentfarbe pro Tool und die Browser-Präferenz. Sie werden lokal im Browser
gespeichert; für Agenten exportiert oder überträgt der Nutzer dieselbe Wahl in
die Projekt-Konfiguration. Der Agent ersetzt diese Konfiguration nicht
stillschweigend.

## Kein doppelter Projektmanager

Dieser Skill ist der **einzige** MGD-Einstieg für Projektstart, Migration und
Dashboard. `MGD_Living-Documentation` bleibt die kanonische Wissensbasis;
`MGD_DEV_SKILL` führt Releases und sichere Bereinigung aus; `MGD_Todo_SKILL`
verwaltet Aufgaben; `MGD_Autopilot_SKILL` steuert autonome Läufe;
`MGD_AI-Thread` sichert und übergibt den belegten Stand beim Threadwechsel. Diese Skills
werden nicht kopiert oder fachlich ersetzt, sondern über Manifest und Dashboard
koordiniert.

Bei Bestandsprojekten prüfe vorhandene ähnliche Start- oder Dashboard-Skills.
Empfehle eine Migration oder einen Kompatibilitätsverweis, aber entferne nie
Skills, Daten oder Konfigurationen ohne ausdrückliche Zustimmung.

## `/thread` – gesicherter Threadwechsel

Richte bei `/projektstart` den eigenständigen
[MGD_AI-Thread](https://github.com/MichaelGahnDESIGN/MGD_AI-Thread) als
verbindlichen Basis-Skill ein. Nutze seinen aktuellen `SKILL.md`-Ablauf bei
`/thread`, einem geplanten Wechsel zu Codex/Claude Code oder knappem Kontext.
Vor der Übergabe werden fertige und geprüfte Projektänderungen gemäß
Projektregeln selektiv committed und auf den vorgesehenen GitHub-/Gitea-Branch
gepusht. Prüfe danach den Remote-Stand. Die Übergabedatei selbst wird nur
versioniert, wenn Projektregeln und `.gitignore` es erlauben. Unfertige,
ungetestete, fremde oder sensible Arbeit wird nicht als fertig ausgegeben;
nenne ihren lokalen Status und die nächste konkrete Aufgabe im Startprompt.
Ein Git-Push ist kein Deployment auf eine produktive Website oder App.

## Kompetenz-Matrix und MCPs

Lies bei einer neuen fachlichen Anforderung zuerst `catalog/capabilities.json`.
Ordne Projektart, Zielplattform, Daten- und Veröffentlichungsrisiko einer
passenden Kompetenz zu. Für README, Wiki, Demos oder Übersetzungen nutze den
lokalen `repository-documentation`-Skill.

Bei Blog-, WordPress- oder E-Commerce-Aufgaben lies zusätzlich
`catalog/integrations.json` und nutze bei Bedarf den lokalen
`commerce-content`-Skill. Er trennt Agent-Skills, Shop-Plugins und
MCP-Verbindungen, damit ein Inhaltsentwurf nicht versehentlich zu einer
Live-Shop-Änderung wird.

MCPs und externe Programme sind Optionen, keine Voraussetzung. Vor einer
Verbindung nenne Zweck, angefragte Berechtigungen, Datenfluss, Kosten und eine
lokale Alternative. Verbinde oder installiere nur nach Zustimmung. Für Godot,
Unity, Unreal, Affinity, Apple-Programme, Tabellen, Datenbanken, WordPress,
Divi, Social Media und Wissenssysteme schlage nur die tatsächlich benötigte
Kompetenz vor; keine pauschale Komplettinstallation.

## Verbindliche Projektgrundstruktur

Ergänze bei neuen Projekten und konfliktfrei auch bei Bestandsprojekten im
Hauptverzeichnis `SECRETS/` und `USER CONCEPT/` sowie passende
`.gitignore`-Regeln. `SECRETS/` enthält ausschließlich lokale Vorlagen und
echte sensible Daten. Ohne ausdrückliche Zustimmung für einen konkreten Pfad
darf der Assistent nichts darin lesen, bearbeiten, kopieren, löschen oder
veröffentlichen. `USER CONCEPT/` sammelt Ideen und Rohmaterial; benötigte
Dateien werden bewusst kopiert, nie automatisch verschoben oder gelöscht.
Nutze dafür die geprüften Vorlagen aus `templates/SECRETS/`,
`templates/USER CONCEPT/` und `templates/project.gitignore`.

Ergänze `AGENT_GLOBAL_RULES.md`, ohne vorhandene Projektregeln zu
überschreiben. Die Datei regelt: sparsamste sinnvolle Modellwahl,
token-sparende Teilziele, Limits und ehrliche Abbruchbedingungen,
kontrollierte Delegation, regelmäßige Prüfung von Agenten und Prozessen,
Gegenprobe am realen Ziel sowie sichere Project-Clean-Inventur. Backups,
Secrets, Nutzerinhalte und unklare Dateien werden nie automatisiert bereinigt.

**Projektstart mit MGD-DevOS: ein Assistent, der ein neues Projekt in einem Rutsch mit allen passenden MGD- und Dritt-Skills ausstattet — sicher vorgeprüft, nicht blind installiert.**

Statt für jedes neue Projekt einzeln zu überlegen, welche Skills gebraucht werden, sie einzeln zu klonen, einzurichten und zu pflegen, übernimmt dieser Skill den kompletten Ablauf: Interview zum Projekt → vier optionale MGD-Kern-Skills und die verbindlichen Basis-Skills `MGD_Autopilot_SKILL` und `MGD_AI-Thread` → MGD-Plattform-Builder bei Web- und Plattform-Projekten → Vorschlag passender Domain-Skills aus einem kuratierten Startkatalog und der Live-Suche auf GitHub → **Sicherheits-Scan jedes Dritt-Skills vor der Installation** → Eintragen aller erhobenen Projektdetails in die frisch installierten Skills → Update-Mechanismus, der regelmäßig prüft, ob installierte Skills neuer sind als der lokale Stand.

Dieser Skill ist die zentrale, umfassendere Variante der "Companion-Skill-Check"-Logik, die MGD_DEV_SKILL, Fragenkatalog-Skill, MGD_Todo_SKILL und MGD_Living-Documentation bereits einzeln mitbringen (sie erkennen sich gegenseitig und bieten sich zur Installation an). MGD-DevOS deckt zusätzlich Domain-Skills (Design/Programmierung/Recht/Sicherheit) und optional ein Plattform-Gerüst mit dem MGD-Plattform-Builder ab — und ist der einzige der Skills, der aktiv auf GitHub nach zusätzlichen, zum Projekt passenden Skills sucht.

### `/projektstart` läuft selbst nach dem Autopilot-Prinzip ab

`/projektstart` ist selbst ein mehrstufiger, potenziell unbeaufsichtigt laufender Ablauf, der mehrere Skills installiert und Projektdateien verändert — genau die Situation, für die `MGD_Autopilot_SKILL` gebaut ist ("Ein KI-Agent arbeitet ein Projektziel unbeaufsichtigt ab — und merkt selbst, wenn er danebenliegt"). Deshalb wird `MGD_Autopilot_SKILL` als verbindlicher Basis-Skill installiert (siehe Schritt 2) und `/projektstart` wendet dessen Mechanik intern auf sich selbst an:

- **Vertrag**: die im Interview (Schritt 1) bestätigte und in Schritt 2 final abgestimmte Liste der zu installierenden und einzurichtenden Skills gilt als der Autopilot-Vertrag für diesen Lauf — er wird zu Beginn von Schritt 2 einmal zusammengefasst und nicht mehr stillschweigend erweitert.
- **Validierung nach jeder Änderung**: nach jeder einzelnen Skill-Installation (Kern-Skill, Plattform-Init, Domain-Skill) wird sofort geprüft, ob die erwarteten Dateien/Ordner tatsächlich angekommen sind, bevor der nächste Schritt beginnt.
- **Leitplanken**: schlägt eine Installation fehl, oder lehnt der Nutzer einen Pflicht-Sicherheits-Scan ab (siehe Schritt 5), bricht `/projektstart` den betroffenen Skill sofort ab und macht **nicht** unkontrolliert mit dem nächsten Schritt weiter — der Abbruch wird in der Abschluss-Zusammenfassung (Schritt 7) unter "offen" vermerkt.

## Grundprinzip: Sicherheit vor Bequemlichkeit

Dritt-Skills werden **nie blind installiert**. Jeder Skill-Kandidat, der nicht aus dem MGD-eigenen GitHub-Konto (`MichaelGahnDESIGN`) stammt, durchläuft vor der endgültigen Installation einen Scan mit `NVIDIA/SkillSpector` und/oder `affaan-m/agentshield`. Details siehe Abschnitt "Sicherheits-Check" unter `/projektstart` Schritt 5 sowie [wiki/Sicherheitskonzept.md](wiki/Sicherheitskonzept.md).

---

## Befehle

### `/projektstart`

Der zentrale, mehrstufige Assistent für einen neuen Projektstart. Läuft als geführter Dialog in sieben Schritten.

#### Schritt 1 — Projekt-Interview

Der Assistent stellt der Reihe nach folgende Fragen (kompakt, mit Vorschlägen/Beispielen, überspringbar wenn bereits aus dem Kontext ersichtlich):

1. **Projektname** — wie soll das Projekt heißen?
2. **Projekttyp** — Spiel / App / Website / Business-Tool / Bibliothek / sonstiges (frei)?
3. **Zielplattform(en)** — Web, iOS, Android, Desktop (macOS/Windows/Linux), Server/Backend, mehrere?
4. **Zielgruppe** — grobe Beschreibung (z. B. "Hobbyprojekt für Freunde", "B2B-Kunden im Mittelstand", "öffentliche App-Store-Veröffentlichung")?
5. **Umfang** — Hobby/privat oder kommerziell (wichtig für Lizenz- und Rechts-Hinweise später)?
6. **Backend-Bedarf** — braucht das Projekt eigene Nutzerkonten, Rollen/Rechte, einen Admin-/Moderationsbereich, oder verarbeitet es DSGVO-relevante personenbezogene Daten? (ja/nein/unsicher — bei "unsicher" hilft der Assistent mit 2–3 Rückfragen)
7. **Sprache(n)** — in welcher Sprache soll Code/Doku/UI primär geführt werden?

Alle Antworten werden zwischengespeichert (im Dialogkontext und später in `PROJEKT/.projektstart-manifest.json`, siehe Schritt 6) und für die folgenden Schritte wiederverwendet.

#### Schritt 2 — Kern-Skills installieren

Vier MGD-Kern-Skills werden **einzeln kurz erklärt** und per Ja/Nein (oder "alle") abgefragt. `MGD_Autopilot_SKILL` und `MGD_AI-Thread` werden als zwei Basis-Skills verbindlich eingerichtet: Autopilot sichert den Ablauf, Thread den späteren Kontextwechsel. Bereits vorhandene Installationen werden geprüft und nicht blind überschrieben.

| Skill | Kurz-Erklärung | Slash-Commands nach Install | Abfrage |
|---|---|---|---|
| **MGD_DEV_SKILL** | Release/Sync/Backup/Cleanup/Tests/Wissensdokumentation | `/dev`, `/dev-fast`, `/dev-changelog` | Ja/Nein |
| **Fragenkatalog-Skill** | Interaktiver Design-Fragenkatalog mit KI-Antworten aus wählbarer Experten-Perspektive, inkl. Recht-Kategorie mit ⚖️-Disclaimer | `/fragenkatalog-setup` | Ja/Nein |
| **MGD_Todo_SKILL** | Selbst-gehostete TODO.html mit Bearbeiten-Funktion und Dokument-Verknüpfung | `/todo-setup`, `/todo-add`, `/todo-edit`, `/todo-link` | Ja/Nein |
| **MGD_Living-Documentation** | Lebendige Projektdokumentation (Entscheidungen, offene Punkte, Risiken, Testnachweise) | kein eigener Slash-Command — wird automatisch vom Agenten erkannt | Ja/Nein |
| **MGD_Autopilot_SKILL** | KI-Agent arbeitet ein Projektziel unbeaufsichtigt ab und merkt selbst, wenn er danebenliegt — Vertrag vor Start, Validierung nach jeder Änderung, zehn Härtungsregeln, harte Sicherheitsleitplanken | keiner (wirkt intern auf `/projektstart` selbst) | **verbindlich, keine Abfrage** |
| **MGD_AI-Thread** | Belegte Übergabe an Codex oder Claude Code; fertig geprüfte Änderungen vorher gemäß Projektregeln committen und pushen | `/thread` | **verbindlich, keine Abfrage** |

Für `MGD_AI-Thread` kopiere `SKILL.md` aus dessen Repository in
`.claude/skills/thread/` und `.codex/skills/thread/` (oder die jeweiligen
globalen Skill-Ordner) sowie die passenden
`.claude/commands/thread.md` und `.codex/commands/thread.md` in die
Command-Ordner. Prüfe jede Zieldatei und notiere Quelle und Stand im Manifest.

Für jeden bestätigten bzw. verbindlichen Skill:

```bash
# Beispiel MGD_DEV_SKILL, projekt-lokal
git clone --depth 1 https://github.com/MichaelGahnDESIGN/MGD_DEV_SKILL.git /tmp/projektstart-install/MGD_DEV_SKILL
mkdir -p .claude/commands .codex/commands dev
cp /tmp/projektstart-install/MGD_DEV_SKILL/.claude/commands/dev*.md .claude/commands/
cp /tmp/projektstart-install/MGD_DEV_SKILL/.codex/commands/dev*.md .codex/commands/ 2>/dev/null || true
cp -r /tmp/projektstart-install/MGD_DEV_SKILL/dev dev/
```

Installationsort (projekt-lokal vs. global) wird vorher erfragt:

- **Projekt-lokal** (Standard für projektspezifische Skills wie Fragenkatalog, Todo, Living-Documentation): Ziel `.claude/commands/`, `.codex/commands/`, sowie skill-eigene Ordner im Projektroot.
- **Global** (empfohlen für MGD_DEV_SKILL, das projektübergreifend genutzt wird): Ziel `~/.claude/skills/<name>/` bzw. `~/.codex/skills/<name>/`.

Nach jeder erfolgreichen Installation wird ein Eintrag in `PROJEKT/.projektstart-manifest.json` geschrieben (siehe `/projektstart-update`).

#### Schritt 3 — MGD-Plattform-Builder empfehlen (Web- und Plattform-Projekte)

Der [MGD-Plattform-Builder](https://github.com/MichaelGahnDESIGN/MGD-Plattform-Builder) ist die Empfehlung für Websites und Plattformen: Projekttyp „Website", Zielplattform Web/Server oder erkannter Backend-, Admin- oder Compliance-Bedarf (Schritt 1, Fragen 2, 3 und 6). Für andere Projekte wird er nicht angeboten. Der Assistent fragt sinngemäß:

> "Dieses Projekt ist ein Web- bzw. Plattform-Projekt. Soll ich es mit dem MGD-Plattform-Builder (`mgd-platform init --preset <preset>`) einrichten? Er bringt Backoffice, Rechte, Rechtstexte und Versionierung mit."

Das Preset wird aus Projekttyp und Zielplattform abgeleitet: `general`, `game`, `community`, `creator` oder `ecommerce`. Der Assistent nennt sein abgeleitetes Preset und lässt den Nutzer es korrigieren. Bei Zustimmung:

1. Prüfen, ob `mgd-platform` bereits verfügbar ist (`command -v mgd-platform`).
2. Falls nicht: `git clone https://github.com/MichaelGahnDESIGN/MGD-Plattform-Builder.git` in ein Tool-Verzeichnis (z. B. `~/.local/share/mgd-platform/`) und gemäß dessen `INSTALL.md` einrichten (Node.js 20+, `npm install`, `npm link`).
3. `mgd-platform init --preset <preset> --target <projektpfad>` ausführen.
4. Ergebnis prüfen mit `mgd-platform validate` und `mgd-platform doctor`.
5. Hinweis an den Nutzer: Das Projekt hat danach `MGD_PLATFORM.yml` und `version.json`; die MGD-DevOS-App zeigt Version und Status (z. B. „0.0.1 Pre-Alpha") in der Projektkarte. Für Starter-Templates und das „powered by"-Label des Plattform-Builders gilt dessen MGD-Lizenz.

Bei Ablehnung: übersprungen, im Abschluss-Report als "nicht eingerichtet (abgelehnt)" vermerkt.

**Wichtig:** Der MGD-Plattform-Builder wird nicht wie die MGD-Skills als Dateien kopiert — er ist ein eigenständiges System mit eigener CLI und wird ausschließlich über `mgd-platform` in das Zielprojekt eingebracht.

#### Schritt 4 — Domain-Skills finden

Aus dem Interview werden relevante Kategorien abgeleitet, z. B.:

- Projekttyp "App"/"Website" + Zielgruppe kommerziell → Design/UI/UX
- Zielplattform-Sprache (Flutter, Web, …) → programmiersprachenspezifisch
- Zielgruppe/Umfang kommerziell + Backend-Bedarf → Recht (v. a. deutsches Recht, DSGVO), Sicherheit
- Immer geprüft: Sicherheit (Skill-Vetting-Tools selbst, siehe Schritt 5)

Ablauf:

1. **Zuerst kuratierte Liste durchsehen**: `catalog/skills.json` nach passender `category` filtern und die Treffer aus der Tabelle unten vorschlagen (mit exakter Beschreibung/Sternzahl aus dem Katalog).
2. **Danach optional live weitersuchen**, wenn die kuratierte Liste keine oder keine ausreichende Passung liefert, z. B.:
   ```bash
   gh search repos "design skill claude code" --limit 10 --sort stars
   gh search code "SKILL.md" "claude code" "<Domäne>" --limit 10
   ```
   Ergebnisse werden dem Nutzer mit Repo-Name, Beschreibung (aus GitHub, nicht erfunden), Sternzahl und Link gezeigt. Der Nutzer wählt aus, welche Kandidaten weiterverfolgt werden.

**Kuratierter Startkatalog (Auszug aus `catalog/skills.json`):**

| Repo | Kategorie | Sterne | Scan nötig? |
|---|---|---|---|
| Graphify-Labs/graphify | Code-Analyse/Dokumentation | 120.740 | ja |
| Klotzkette/claude-fuer-deutsches-recht | Recht (Deutschland) | 1.615 | ja |
| dickwu/apple-design-skill | Design/UI/UX | 770 | ja |
| affaan-m/agentshield | Sicherheit | 1.214 | ja |
| affaan-m/ECC | Agenten-Framework | 265.856 | ja |
| WorldFlowAI/everything-claude-code | Sammlung/Toolkit | 3.494 | ja |
| Jakeschincariol/promptmaster-skill | Produktivität | 8 | ja |
| NVIDIA/SkillSpector | Sicherheit (Skill-Vetting) | 18.143 | ja |

#### Schritt 5 — Sicherheits-Check vor Installation (kritisch)

Für **jeden** Dritt-Skill-Kandidaten (kuratiert oder live gefunden), der nicht aus `github.com/MichaelGahnDESIGN/*` stammt, gilt zwingend folgender Ablauf, **bevor** die Installation endgültig bestätigt wird:

1. **Scanner sicherstellen**: Prüfen, ob `NVIDIA/SkillSpector` und/oder `affaan-m/agentshield` bereits lokal (global) installiert sind (z. B. `~/.local/share/skill-scanners/`). Falls nicht, werden sie zuerst geclont:
   ```bash
   git clone --depth 1 https://github.com/NVIDIA/SkillSpector.git ~/.local/share/skill-scanners/SkillSpector
   git clone --depth 1 https://github.com/affaan-m/agentshield.git ~/.local/share/skill-scanners/agentshield
   ```
2. **Zielskill klonen** (noch nicht ins Projekt kopieren, nur in ein temporäres Verzeichnis):
   ```bash
   git clone --depth 1 <kandidat-url> /tmp/projektstart-scan/<kandidat-name>
   ```
3. **Scan ausführen** gegen den geclonten Ziel-Ordner, z. B. (Aufrufsyntax gemäß jeweiliger Tool-eigener Dokumentation zum Zeitpunkt der Ausführung prüfen, sinngemäß):
   ```bash
   skillspector scan /tmp/projektstart-scan/<kandidat-name>
   agentshield scan --path /tmp/projektstart-scan/<kandidat-name>
   ```
4. **Ergebnis anzeigen**: Findings (Schweregrad, Beschreibung, betroffene Datei) werden dem Nutzer vollständig gezeigt, bevor irgendetwas ins Projekt übernommen wird.
5. **Explizite Nutzer-Bestätigung einholen**: "Trotzdem installieren? (ja/nein)" — bei CRITICAL/HIGH-Findings wird zusätzlich ausdrücklich gewarnt und eine zweite Bestätigung verlangt.
6. **Ohne verfügbaren Scanner** (z. B. kein Netzzugriff, Clone schlägt fehl): Der Assistent installiert **nicht automatisch weiter**, sondern warnt explizit: "Kein Sicherheits-Scanner verfügbar — dieser Skill würde ungeprüft installiert. Trotzdem fortfahren? (ja/nein)" und verlangt eine zusätzliche, separate Bestätigung, die diese Tatsache ausdrücklich anerkennt.
7. Erst nach Bestätigung: Installation wie bei den Kern-Skills (Kopieren in `.claude/`/`.codex/`-Struktur bzw. globale Skill-Ordner), inkl. Manifest-Eintrag mit `scanResult: "clean" | "warnings-accepted" | "unscanned-accepted"`.

Dieser Schritt gilt **nicht** für die sechs MGD-Skills des Basisangebots (`requiresScan: false` im Katalog; nur Autopilot und AI-Thread sind `mandatory: true`) und **nicht** für den MGD-Plattform-Builder (eigenes CLI-Init, keine Datei-Kopie).

#### Schritt 6 — Details eintragen

Nach Installation aller gewählten Skills werden die im Interview erhobenen Projektdaten automatisch in die jeweiligen Skills eingetragen:

- **Fragenkatalog-Skill**: `/fragenkatalog-setup` wird mit den erhobenen Projektdaten (Name, Typ, Zielgruppe, Sprache) angestoßen.
- **MGD_Todo_SKILL**: `/todo-setup` initialisiert `TODO.html`; anschließend werden über `/todo-add` erste Einträge für offene Setup-Punkte angelegt (z. B. "Rechtstext prüfen lassen", "Design-Skill-Ergebnisse durchgehen", "Backend-Preset validieren" — abhängig davon, was in den vorigen Schritten offen blieb oder abgelehnt wurde).
- **MGD_Living-Documentation**: eine erste Einstiegsseite wird mit den Interview-Antworten befüllt (Projektüberblick, Entscheidung "welche Skills installiert wurden und warum", offene Punkte aus Schritt 3–5).
- **PROJEKT/.projektstart-manifest.json**: wird geschrieben/aktualisiert (siehe `/projektstart-update`).

#### Schritt 7 — Abschluss-Zusammenfassung

Der Assistent fasst zusammen:

- **Installiert**: welche Kern-Skills, welche Domain-Skills (mit Scan-Ergebnis), MGD-Plattform-Builder (ja/nein/Preset).
- **Eingerichtet**: welche Setup-Befehle liefen (`/fragenkatalog-setup`, `/todo-setup`, Living-Doc-Einstiegsseite).
- **Offen**: abgelehnte Vorschläge, ungeprüft installierte Skills (falls zugestimmt), manuell zu erledigende Punkte.

#### Schritt 8 — Dashboard starten, Desktop-Verknüpfung, Einweisung

Nach der Zusammenfassung:

1. Starte `/dashboard` (Regeln oben, `dashboardOpenTarget` beachten).
2. Frage, ob eine **Desktop-Verknüpfung** zur `index.html` des Projekts
   angelegt werden soll. Nur nach Ja: macOS `.webloc`, Windows `.url`,
   Linux `.desktop` – die Verknüpfung zeigt auf die Projektdatei, es wird
   nichts kopiert und die `index.html` bleibt die kanonische Quelle.
3. Erkläre dem Nutzer in wenigen einfachen Sätzen, wie er arbeitet:
   Dashboard öffnen, was die Bereiche zeigen, wie er im Chat mit dem
   Assistenten Aufgaben erteilt (`/todo`, `/thread`, `/dev`), wo Todo und
   Living Documentation liegen und dass Installationen, Pushes,
   Deployments und Löschungen weiter seine Freigabe brauchen.

## Einrichten und Starten (Einstiegsbefehl)

Bekommt der Assistent nur den Link zu diesem Repository und die Aufforderung
„Einrichten und Starten“: installiere den Skill wie in der README beschrieben
(projekt-lokal oder global nach Rückfrage), starte `/projektstart` und führe
alle Schritte 1–8 gemeinsam mit dem Nutzer aus, inklusive Projektordner,
Todo und Living Documentation. Ändere nichts ohne die genannten Freigaben.

---

### `/projektstart-update`

Updater für alle über `/projektstart` installierten Skills.

**Grundlage**: `PROJEKT/.projektstart-manifest.json`, ein JSON-Array, das bei **jeder** Installation durch `/projektstart` (oder späterem `/projektstart-update`) fortgeschrieben wird. Jeder Eintrag enthält mindestens:

```json
{
  "skill": "Fragenkatalog-Skill",
  "sourceUrl": "https://github.com/MichaelGahnDESIGN/Fragenkatalog-Skill",
  "installedRef": "a1b2c3d",
  "installedDate": "2026-09-23",
  "installTarget": "project-local",
  "scanResult": "n/a"
}
```

Ablauf von `/projektstart-update`:

1. Manifest einlesen.
2. Für jeden Eintrag den aktuellen Stand des Quell-Repos ermitteln:
   ```bash
   git ls-remote https://github.com/<owner>/<repo>.git HEAD
   # oder
   gh api repos/<owner>/<repo>/commits/main --jq .sha
   gh release list --repo <owner>/<repo> --limit 1
   ```
3. Tabelle anzeigen (Beispielwerte, keine echten Commits):

   | Skill | installierte Version | aktuelle Version | Update verfügbar |
   |---|---|---|---|
   | MGD_DEV_SKILL | a1b2c3d (23.09.2026) | f9e8d7c | ja |
   | Fragenkatalog-Skill | 4c5d6e7 (23.09.2026) | 4c5d6e7 | nein |

4. Bei verfügbaren Updates: einzeln (oder "alle") nachfragen, ob aktualisiert werden soll. **Vor** der Bestätigung expliziter Hinweis: "Lokale Anpassungen an diesem Skill können beim Update überschrieben werden — vorher committen/sichern."
5. Bei Zustimmung: erneutes Kopieren der aktuellen Dateien aus einem frischen `git clone`, gleiche Zielpfade wie bei Erstinstallation, Manifest-Eintrag (Ref/Datum) aktualisieren.
6. Für Dritt-Skills (`requiresScan: true`) wird beim Update erneut der Sicherheits-Check aus Schritt 5 von `/projektstart` durchlaufen, bevor die neuen Dateien übernommen werden.

Details und Beispiel-Ausgabe: [wiki/Updater.md](wiki/Updater.md).

### `/projektstart-katalog`

Zeigt die aktuelle kuratierte Liste aus `catalog/skills.json` formatiert an (Tabelle: Name, Kategorie, Sterne, Quelle, Scan-Pflicht, Link). Unterstützt Kategorie-Filter, z. B.:

```
/projektstart-katalog --kategorie recht-deutschland
/projektstart-katalog --kategorie design-ui-ux
/projektstart-katalog --alle
```

### `/projektstart-katalog-add <repo-url> <kategorie>`

Fügt einen vom Nutzer **manuell geprüften** Dritt-Skill dauerhaft zu `catalog/skills.json` hinzu, damit er bei künftigen Projekten ohne erneute Live-Suche als kuratierter Vorschlag erscheint.

Ablauf:

1. Repo-Metadaten abrufen (`gh repo view <repo-url> --json description,stargazerCount`), um Beschreibung/Sternzahl korrekt (nicht erfunden) einzutragen.
2. Neuen Eintrag mit `source: "third-party-curated"`, `requiresScan: true` (außer der Nutzer bestätigt ausdrücklich, dass er selbst geprüft hat — dann trotzdem `requiresScan: true`, da der Scan projektspezifisch pro Installation erfolgt, nicht einmalig pro Katalogeintrag) an `catalog/skills.json` anhängen.
3. Kategorie wie vom Nutzer angegeben übernehmen (freie Kategorisierung, konsistent zu bestehenden Werten wo möglich).
4. Bestätigung anzeigen, Änderung ist sofort für künftige `/projektstart`-Läufe wirksam.

---

## Voraussetzungen

- `git` und `gh` (GitHub CLI, authentifiziert) für Live-Suche, Metadaten-Abfragen und Update-Checks.
- Netzzugriff für Clone/Scan-Schritte (ohne Netzzugriff greift der Fallback-Warnhinweis aus Schritt 5).

## Verwandte MGD-Skills

Siehe [README.md](README.md#verwandte-mgd-projekte) für die vollständige Übersicht.

## Lizenz

MGD-Lizenz 1.0, siehe [LICENSE](LICENSE) und [NOTICE](NOTICE) in diesem Ordner. Das Label
„powered by: Michael Gahn DESIGN" in Dashboards bleibt immer erhalten.
