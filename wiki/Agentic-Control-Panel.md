# Agentic Control Panel

Zeigt Agenten, Skills und Integrationen, die aus **echten lokalen Dateien** gelesen wurden:
`AGENTS.md` (Überschriften), `catalog/capabilities.json`, `catalog/skills.json` (Pflicht-Skills
sind markiert, z. B. `MGD_AI-Thread`), `catalog/integrations.json`.

## Status-Werte

| Status | Bedeutung |
|---|---|
| belegt aktiv | Nur mit echtem Live-Adapter möglich. **Aktuell nie.** |
| belegt inaktiv | Quelle sagt „inaktiv" |
| nicht verbunden | In Dateien deklariert, kein Live-Adapter |
| unbekannt | Datei nicht lesbar |

## Graph und Liste

- **Graph:** Projekt links, Gruppen (Agenten, Skills, Integrationen) in der Mitte, Einträge rechts. Ziehen verschiebt,
  Scrollen/Pinch zoomt, „Ansicht zurücksetzen" zentriert. Klick auf eine Gruppe klappt sie ein oder aus; Gruppen mit
  mehr als 8 Einträgen starten eingeklappt. Bei Filter oder Suche ist alles ausgeklappt.
- **Liste:** dieselben Einträge als Liste.
- **Inspektor:** Klick auf einen Eintrag zeigt Status, Art, Projekt, Beschreibung, Quelle und Zeitpunkt.

Jeder Eintrag nennt Quelle und Zeitpunkt des Scans. Es gibt keine Aktionen (Pause, Stop,
Delegation), weil es noch keinen Adapter und keine Autorisierung gibt.
