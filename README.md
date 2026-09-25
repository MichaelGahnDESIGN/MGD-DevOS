<p align="center"><a href="https://Michael-Gahn.de"><img src="assets/brand/logo-64.png" alt="Michael Gahn DESIGN" width="48"></a></p>

<p align="center"><img src="assets/banner.svg" alt="MGD-DevOS" width="100%"></p>

<p align="center">
  <a href="https://github.com/MichaelGahnDESIGN/MGD-DevOS/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/MichaelGahnDESIGN/MGD-DevOS/actions/workflows/ci.yml/badge.svg"></a>
  <img alt="Plattformen" src="https://img.shields.io/badge/macOS%20%C2%B7%20Windows%20%C2%B7%20Linux-Flutter%203.47-2f6fed">
  <a href="https://github.com/MichaelGahnDESIGN/MGD-DevOS/releases/latest"><img alt="Release" src="https://img.shields.io/github/v/release/MichaelGahnDESIGN/MGD-DevOS?label=Release"></a>
  <a href="LICENSE"><img alt="Lizenz" src="https://img.shields.io/badge/Lizenz-PolyForm%20Noncommercial-blue"></a>
  <img alt="Lokal" src="https://img.shields.io/badge/Daten-lokal%2C%20keine%20Telemetrie-2e9e6e">
</p>

**MGD-DevOS** ist deine Projektzentrale aus zwei Teilen in einem Repository:

- **Desktop-App** (Flutter, macOS/Windows/Linux): Tabs für die Dashboards aller Projekte, Agentic Control Panel, PIN-Sperre.
- **Projektmanager-Skill** (`skill/`) für Claude Code, Codex & Co.: Projektstart, Skill-Auswahl, `/dashboard` mit einem
  Dashboard im Stil eines Programms (Menüleiste, verschiebbare Fenster, Einstellungen, Versionen, Credits).

Mit der App wechselst du zwischen den Dashboards aller Projekte. Die Daten liegen in deinen lokalen
Projektordnern, die Claude, Codex & Co. anlegen und pflegen. Die App zeigt sie an, sie
braucht deshalb keinen eigenen Server und keinen Updater für Inhalte.

> **Version 0.5.1 Pre-Alpha.** Installer für macOS, Windows und Linux entstehen über GitHub Actions, sie sind
> **unsigniert**, siehe [Download](#download). Versionsschema 1.2.3: 1 = Hauptversion ab Release, 2 = neue Funktionen,
> 3 = Patches. Die Nummer steht zentral in [`assets/meta/version.json`](assets/meta/version.json).

## Download

Aktuelle Version: **[Releases](https://github.com/MichaelGahnDESIGN/MGD-DevOS/releases/latest)**

| System | Datei | Start |
|---|---|---|
| macOS | `MGD-DevOS.dmg` | DMG öffnen, App nach „Programme" ziehen. Beim ersten Start: Rechtsklick → „Öffnen" (unsigniert). |
| Windows | `MGD-DevOS-windows.zip` | Entpacken, `mgd_devos.exe` starten. SmartScreen: „Weitere Informationen" → „Trotzdem ausführen". |
| Linux (x64) | `MGD-DevOS-linux.tar.gz` | `tar -xzf MGD-DevOS-linux.tar.gz && ./bundle/mgd_devos` (benötigt GTK 3). |

Prüfsummen: `SHA256SUMS.txt` im Release, prüfen mit `shasum -a 256 -c SHA256SUMS.txt`.

## Einrichten und Starten

Gib deinem Assistenten (Claude Code, ChatGPT Codex, ...) diesen Text:

```text
Einrichten und Starten: Installiere den Skill aus dem Ordner skill/ von
https://github.com/MichaelGahnDESIGN/MGD-DevOS,
starte /projektstart und richte gemeinsam mit mir Projektordner, Todo und
Living Documentation ein. Öffne am Ende das Dashboard, lege nach meiner
Bestätigung eine Verknüpfung auf den Desktop und erkläre mir, wie ich damit arbeite.
```

Skill von Hand installieren (Claude Code, global):

```bash
git clone --depth 1 https://github.com/MichaelGahnDESIGN/MGD-DevOS.git /tmp/mgd-devos
mkdir -p ~/.claude/skills ~/.claude/commands
cp -R /tmp/mgd-devos/skill ~/.claude/skills/mgd-devos
cp ~/.claude/skills/mgd-devos/.claude/commands/dashboard.md ~/.claude/commands/
```

Start im Assistenten: `/projektstart`, danach `/dashboard`. Codex und projekt-lokal: [skill/wiki/Setup.md](skill/wiki/Setup.md).

App aus dem Quellcode:

```bash
git clone https://github.com/MichaelGahnDESIGN/MGD-DevOS.git
cd MGD-DevOS
flutter pub get
flutter run -d macos     # oder: -d windows / -d linux
```

Fertige Installer: siehe [Download](#download).

## So sieht es aus

<p align="center"><img src="assets/screenshots/02-projekte-light.png" alt="Projektübersicht, heller Modus" width="100%"></p>

| | |
|---|---|
| <img src="assets/screenshots/01-onboarding-light.png" alt="Onboarding"> | <img src="assets/screenshots/03b-agentic-auswahl-dark.png" alt="Agentic Control Panel als Graph mit Inspektor, dunkler Modus"> |
| <img src="assets/screenshots/02-projekte-dark.png" alt="Projekte, dunkler Modus"> | <img src="assets/screenshots/04-einstellungen-light.png" alt="Einstellungen"> |

## Was die App kann

| | |
|---|---|
| **Tab-Browser** | Tab „Übersicht" plus je ein Tab pro geöffnetem Projekt-Dashboard (`index.html`). Tabs wechseln und schließen. |
| **Projektregister** | Scannt deinen Projektordner nach echten Projekten (Git, README, AGENTS.md, ...) und öffnet Dokumente. |
| **Agentic Control Panel** | Graph aus Projekten, Agenten, Skills und Integrationen (aus `AGENTS.md` und `catalog/*.json`) mit Inspektor, Quelle und Zeitstempel. Nie ein erfundener „aktiv"-Status. |
| **Darstellung** | Hell, Dunkel oder System, eigene Akzentfarbe. |
| **Sicher by Design** | Alles lokal, keine Telemetrie, keine Zugangsdaten, Webview nur für Dateien im Projektordner. |

## So funktioniert es

```
Assistent (Claude/Codex)  ──pflegt──▶  Projektordner  ◀──liest──  MGD-DevOS
   /projektstart, /todo …              index.html, docs/, catalog/      Tabs · Scanner · Panel
```

## Status

| Bereich | Stand |
|---|---|
| Code, Analyse, Tests | ✅ grün (15 Tests) |
| macOS/Windows/Linux-Build | ✅ grün auf GitHub Actions, Installer im Release |
| Start auf echten Geräten | ⏳ noch nicht manuell geprüft |
| Dashboard im Webview (`file://`) | ✅ Integrationstest mit echter App auf macOS und Windows, Linux-Ausweichweg geprüft |
| Linux | eingebettetes WebView nicht verfügbar, Dashboard öffnet im Browser |
| Signierung/Notarisierung | ❌ nicht vorhanden (Apple Developer Program nötig) |
| App-Sperre, Schlüsselbund, Live-Agenten-Adapter | ❌ geplant |
| Spenden (Stripe) | ❌ nicht eingerichtet, siehe [Stripe-Spenden](wiki/Stripe-Spenden.md) |

## Dokumentation

Das ausführliche Wiki liegt im Ordner [`wiki/`](wiki/Home.md): Installation, Erste Schritte,
Tabs, Scanner, Agentic Panel, Sicherheit, Architektur, Entwicklung und CI, Release, Roadmap, FAQ.

## Sicherheit und Datenschutz

Keine Telemetrie, keine Zugangsdaten, keine Netzwerkzugriffe im Normalbetrieb. Gespeichert
werden nur Theme, Akzentfarbe und der Projekt-Root-Pfad. Mehr: [Sicherheit](wiki/Sicherheit-und-Datenschutz.md).

## Lizenz und Mitwirken

Nutzen, ändern und Änderungen vorschlagen ist erlaubt, **verkaufen oder kommerziell nutzen nicht**
([PolyForm Noncommercial 1.0.0](LICENSE)). Das ist keine Open-Source-Lizenz im Sinne der OSI.
Beiträge willkommen, siehe [CONTRIBUTING.md](CONTRIBUTING.md).


Regeln für Beiträge, Tests und CI stehen in [Entwicklung und CI](wiki/Entwicklung-und-CI.md).

---

<p align="center"><a href="https://Michael-Gahn.de"><img src="assets/brand/logo-64.png" width="24" alt=""> <b>supported by: Michael Gahn DESIGN</b></a></p>

<!-- MGD-LEGAL -->
---

## Lizenz

Dieses Projekt steht unter der [PolyForm Noncommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0). Den vollständigen Text enthält die Datei [LICENSE](LICENSE).

## Impressum

**Angaben gemäß § 5 DDG (Digitale-Dienste-Gesetz)**

Michael Gahn DESIGN  
Michael Gahn  
Dr.-Theodor-Brugsch Str. 12  
08529 Plauen  
Sachsen  
Deutschland

Tel.: +49 (0) 151 59156639  
E-Mail: Anfrage@Michael-Gahn.de

Umsatzsteuer-Identifikationsnummer gemäß § 27 a Umsatzsteuergesetz:  
Steuernummer: 223/222/02451  
Ust-ID: DE288143343

Wir sind zur Teilnahme an einem Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle weder verpflichtet noch bereit.

**Redaktionell verantwortlich:**

Michael Gahn DESIGN  
Michael Gahn  
Dr.-Theodor-Brugsch Str. 12  
08529 Plauen  
Sachsen  
Deutschland

Tel.: +49 (0) 151 59156639  
E-Mail: Anfrage@Michael-Gahn.de
<!-- /MGD-LEGAL -->
