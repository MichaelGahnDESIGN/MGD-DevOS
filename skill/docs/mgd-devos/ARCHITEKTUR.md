# MGD-DevOS: Architektur für eine lokale Agenten-Zentrale

MGD-DevOS ist die geplante Desktop-Anwendung über dem
`MGD-DevOS`. Sie ersetzt keine KI-Runtime und erfindet keinen
Agentenstatus. Sie macht reale, freigegebene Projekt- und Runtime-Daten für
Menschen sichtbar und verständlich bedienbar.

## Zielbild

MGD-DevOS läuft zuerst lokal auf macOS, Windows und Linux. Flutter Desktop ist
die gemeinsame Oberfläche. Projektdateien, Living Documentation und lokale
Statusdaten bleiben standardmäßig auf dem Computer des Nutzers. Es gibt keine
Telemetrie, kein Analytics und keinen Cloud-Sync ohne bewusste Aktivierung.

```text
Mensch
  │  Ziel, Freigaben, Stop
  ▼
MGD-DevOS (Flutter Desktop)
  ├── Projekt-Dashboard und Dokumente
  ├── Agentic Control Panel
  ├── Skills- und MCP-Katalog
  ├── Docker-, Git- und Backup-Übersicht
  └── sichere lokale Einstellungen
          │
          ▼
Lokaler Bridge-Dienst mit minimalen Rechten
  ├── Projektmanifest und Living Documentation
  ├── Codex-Adapter / Claude-Code-Adapter
  ├── Docker-CLI-Adapter
  ├── Git- und GitHub/Gitea-Adapter
  └── Betriebssystem-Schlüsselbund
```

Der Bridge-Dienst hat keine allgemein offene Netzwerk-Schnittstelle. Er bindet
standardmäßig nur an `127.0.0.1`, verwendet kurzlebige lokale Sitzungen und
besitzt pro Adapter eine eigene Berechtigung. Nicht verfügbare Integrationen
zeigen klar „nicht verbunden“ statt scheinbar echter Daten.

## Agentic Control Panel

Das Control Panel ist die visuelle Leitstelle. Es zeigt keine erfundenen
Beziehungen, sondern eine Graphansicht aus dem Projektmanifest und den
tatsächlich verfügbaren Adaptern:

```text
Projekt
 ├── Hauptagent
 │    ├── Aufgabe: Dashboard aktualisieren
 │    ├── Skill: Living Documentation
 │    └── Freigabe nötig: nein
 ├── Prüfagent
 │    ├── Aufgabe: Tests bewerten
 │    └── Freigabe nötig: nein
 └── Veröffentlichungsagent
      ├── Aufgabe: Release vorbereiten
      └── Freigabe nötig: ja
```

Jeder Knoten zeigt Rolle, Projekt, Laufzeitstatus, aktuelle Aufgabe,
verwendete Fähigkeiten, letzte bestätigte Aktivität und erforderliche
Freigaben. Ein Klick erklärt diese Begriffe in einfacher Sprache. Ein
gesperrter oder nicht verbundener Agent wird sichtbar als solcher markiert.
Das Panel darf Aufgaben pausieren oder abbrechen, aber nur über einen
nachweisbar vorhandenen Adapter und mit einer Bestätigung bei riskanten
Aktionen.

### Oberfläche

- Light-, Dark- und Systemmodus sowie individuelle Akzentfarbe sind pro Nutzer
  lokal gespeichert und vom Projekt-Theme getrennt.
- Die Standardansicht bleibt ruhig: Projektstatus, nächste sichere Aktion,
  Agentengraph, Risiken und Freigaben. Details öffnen sich erst bei Bedarf.
- Ein Einsteiger-Modus erklärt „Agent“, „Skill“, „MCP“, „Staging“ und
  „Backup“ direkt dort, wo die Begriffe erscheinen.
- Die Anwendung bleibt ohne Internet sinnvoll nutzbar. Externe Funktionen
  werden als optionale Verbindung angezeigt.

## Lokaler Datenschutz und Schutz

„DSGVO-konform“ darf nicht pauschal versprochen werden: Die tatsächliche
Konformität hängt von Einsatz, Daten, Auftragsverarbeitung und gewählten
Drittanbietern ab. MGD-DevOS wird jedoch datensparsam gestaltet:

1. **Local-first:** Projektindex, UI-Einstellungen und Auditdaten liegen lokal.
   Cloud-Sync, Telemetrie und externe Diagnose sind standardmäßig aus.
2. **Secrets:** Keine Klartext-Passwörter in Flutter-Preferences, SQLite,
   Logs, Projektordner oder Git. Geheimnisse liegen nur im Schlüsselbund des
   Betriebssystems; das Projekt speichert höchstens eine sichere Referenz.
3. **Optionaler App-Schutz:** Optionaler lokaler Sperrbildschirm mit
   Argon2id-Hash und Schlüsselbund-gestütztem Schlüssel. Nach Leerlauf wird
   die App gesperrt. Der Schutz ergänzt, aber ersetzt nicht die Anmeldung am
   Betriebssystem und die Festplattenverschlüsselung.
4. **Minimale Rechte:** Jeder Adapter benötigt eine einzeln aktivierte,
   verständlich erklärte Berechtigung. Lesen, Schreiben, Starten und
   Veröffentlichen sind getrennte Rechte.
5. **Audit:** Das System protokolliert lokal nur sicherheitsrelevante Aktionen
   wie Freigaben, Konfigurationsänderungen, Backups und Releases. Secrets,
   Prompts mit vertraulichen Daten und Zahlungskartendaten werden nie geloggt.
6. **Externe Dienste:** Vor GitHub, Gitea, Stripe, MCPs, Social Media oder
   Cloud-Backups nennt die App Datenfluss, Zweck und Rechte. Der Nutzer kann
   die Verbindung ablehnen oder jederzeit entfernen.

## Auslieferungsplan

| Phase | Ergebnis | Keine stillen Risiken |
| --- | --- | --- |
| 1 – Lesen | Flutter-App mit Projektübersicht, Dokumentenöffnung, Agentengraph aus lokalen Daten und Theme-Einstellungen | keine Secrets, keine Schreibaktionen, keine Cloud |
| 2 – Kontrollieren | Aktivierbare lokale Skills, echte Adapter-Statusansicht und Freigabe-Inbox | jede Aktion zeigt Ziel und Folgen vor Ausführung |
| 3 – Betrieb | Docker-Übersicht, Staging-Start, Backup-Vorschau und Wiederherstellungsnachweis | keine Produktion ohne Backup und explizite Freigabe |
| 4 – Verbindungen | MCP-Konfiguration, GitHub/Gitea und externe Integrationen | kleinste Rechte, Secret-Referenzen und Audit |
| 5 – Zahlungen | optionales Spendenmodul mit Stripe-hosted Checkout | keine Kartendaten oder Stripe-Secret-Keys in der App |

## Qualitätsregeln

Neue DevOS-Funktionen beginnen mit verständlichen Nutzerwegen und Tests. Für
Sicherheit, lokale Sperre, Adapter, Docker und Zahlungen sind Unit-,
Integrations- und End-to-End-Tests erforderlich. Ein Status oder Button darf
nur sichtbar aktiv sein, wenn das zugrundeliegende System wirklich verfügbar
ist.
