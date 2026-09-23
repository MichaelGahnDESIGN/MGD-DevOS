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

Jeder Eintrag nennt Quelle und Zeitpunkt des Scans. Es gibt keine Aktionen (Pause, Stop,
Delegation), weil es noch keinen Adapter und keine Autorisierung gibt.
