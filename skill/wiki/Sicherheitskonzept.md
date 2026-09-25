# Sicherheitskonzept: Scan vor Installation

## Warum Live-Suche statt nur kuratierter Liste?

Eine rein kuratierte Liste ist sicherer, aber begrenzt: sie deckt nur ab, was der Betreiber bereits kennt und geprüft hat. Neue, gut passende Skills auf GitHub würden nie vorgeschlagen. Der Owner hat sich deshalb bewusst für **Live-GitHub-Suche** (`gh search repos`, `gh search code`) entschieden, um auch neue und spezialisierte Skills zu finden, die nicht im kuratierten Startkatalog stehen.

Der Preis dafür: Live-gefundene Repos sind **ungeprüft**. Ein Skill kann bösartigen Code, Prompt-Injection-Payloads in seiner SKILL.md, übermäßige Tool-Berechtigungen oder Daten-Exfiltrationslogik enthalten — und das ist auf den ersten Blick oft nicht erkennbar. Deshalb ist der Sicherheits-Scan **kein optionales Extra**, sondern ein Pflichtschritt zwischen "Kandidat gefunden" und "Kandidat installiert".

## Der Workflow im Detail

Gilt für **jeden** Skill-Kandidaten, dessen Quelle nicht `github.com/MichaelGahnDESIGN/*` ist — egal ob er aus dem kuratierten Startkatalog (`catalog/skills.json`, `source: "third-party-curated"`) oder aus einer Live-Suche stammt.

```
Kandidat gefunden
       │
       ▼
Scanner vorhanden? (SkillSpector / agentshield lokal installiert)
       │
   ┌───┴────┐
  nein      ja
   │         │
   ▼         ▼
Scanner   Ziel-Repo in temporäres Verzeichnis klonen
klonen    (noch NICHT ins Projekt kopieren)
   │         │
   └────┬────┘
        ▼
   Scan gegen geclonten Ordner ausführen
        │
        ▼
   Findings dem Nutzer vollständig zeigen
        │
        ▼
   "Trotzdem installieren? (ja/nein)"
        │
   ┌────┴────┐
  nein       ja
   │          │
   ▼          ▼
 Abbruch   Installation wie bei Kern-Skills
           (Kopieren, Manifest-Eintrag mit scanResult)
```

### Schritt für Schritt

1. **Scanner sicherstellen.** `NVIDIA/SkillSpector` (18.143 ⭐, spezialisiert auf Claude-Code-/Codex-/MCP-Skills: erkennt Schwachstellen, bösartige Muster, Prompt-Injection, Datenexfiltration, Supply-Chain-Risiken) und/oder `affaan-m/agentshield` (1.214 ⭐, allgemeiner Agenten-Sicherheitsscanner für Agent-Konfigurationen, MCP-Server, Tool-Berechtigungen) werden lokal vorgehalten. Fehlen sie, werden sie einmalig geklont.
2. **Zielskill isoliert klonen.** Der Kandidat wird in ein temporäres Scan-Verzeichnis geklont — nicht direkt ins Projekt. So wird nichts Ungeprüftes auch nur kurzzeitig Teil des Projekt-Repos.
3. **Scan ausführen** gegen genau diesen geclonten Ordner.
4. **Ergebnis transparent zeigen.** Alle Findings (Schweregrad, betroffene Datei, Beschreibung) werden dem Nutzer angezeigt — nicht nur eine Zusammenfassung "ok/nicht ok".
5. **Explizite Bestätigung.** Nur nach einem klaren "ja" installiert der Assistent tatsächlich. Bei CRITICAL/HIGH-Findings gibt es eine zusätzliche, verschärfte Warnung und eine zweite Bestätigung.
6. **Fallback ohne Netzzugriff/Scanner.** Kann weder ein vorhandener noch ein frisch geclonter Scanner genutzt werden, installiert der Assistent nicht automatisch "irgendwie sicher" — er warnt ausdrücklich, dass ungeprüft installiert würde, und verlangt eine gesonderte Bestätigung, die genau das anerkennt ("Ja, ich installiere diesen Skill ohne Sicherheits-Scan").

## Was der Scan nicht ersetzt

Ein automatischer Scan ist eine Heuristik, kein Garant. Er senkt das Risiko offensichtlicher, maschinell erkennbarer Probleme erheblich, ersetzt aber keine menschliche Prüfung bei sicherheitskritischen Projekten (z. B. Skills, die produktiv mit echten Nutzerdaten arbeiten). Der Assistent weist bei CRITICAL/HIGH-Findings ausdrücklich darauf hin, dass eine manuelle Code-Durchsicht sinnvoll sein kann.

## Warum die MGD-Kern-Skills und der MGD-Plattform-Builder ausgenommen sind

Die sechs MGD-Skills des Basisangebots (`requiresScan: false`; Autopilot und AI-Thread sind `mandatory: true`) sowie der MGD-Plattform-Builder stammen aus dem eigenen GitHub-Konto des Betreibers (`MichaelGahnDESIGN`). Der spezielle Dritt-Skill-Scan wird daher hier nicht verlangt. Quelle, Dateien und vorhandene Installationen werden trotzdem geprüft.

## Autopilot-Vertrag als zusätzliche Leitplanke

`MGD_Autopilot_SKILL` wird in `/projektstart` als verbindlicher Basis-Skill installiert (siehe [SKILL.md](../SKILL.md)) und sein Vertrags-/Validierungs-Prinzip wirkt direkt auf diesen Sicherheits-Workflow: Der **Vertrag** ist die im Interview bestätigte Liste der zu installierenden Skills — ein Dritt-Skill, der nicht Teil dieses Vertrags war, wird nicht "unterwegs" nachinstalliert, ohne erneut den vollständigen Scan-Workflow zu durchlaufen. Die **Validierung nach jeder Änderung** bedeutet hier konkret: nach jedem Scan wird geprüft, ob tatsächlich ein Scan-Ergebnis vorliegt (nicht nur ein leerer/fehlgeschlagener Lauf), bevor der Nutzer überhaupt gefragt wird. Die **Leitplanke** greift, sobald der Nutzer einen Scan ablehnt, einen Fund nicht bestätigt, oder kein Scanner verfügbar ist und die Ungeprüft-Bestätigung ausbleibt: `/projektstart` bricht die Installation dieses einen Skills sofort ab und macht nicht automatisch mit dem nächsten Kandidaten weiter, ohne das im Abschluss-Report zu vermerken.
