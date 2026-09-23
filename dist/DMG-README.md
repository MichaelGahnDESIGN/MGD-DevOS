# MGD-DevOS – Installation (macOS)

1. **MGD-DevOS.app** in den Ordner **Applications** ziehen (Verknüpfung in
   diesem DMG-Fenster).
2. App aus dem Programme-Ordner starten, nicht aus diesem DMG heraus.
3. Da diese Version noch **nicht signiert und nicht notarisiert** ist, zeigt
   macOS beim ersten Start eine Gatekeeper-Warnung ("nicht verifizierter
   Entwickler"). Das ist für diese frühe, lokale Entwicklungsversion
   erwartet. Vorgehen: Rechtsklick auf die App → „Öffnen" → im Dialog
   erneut „Öffnen" bestätigen. Danach startet die App normal.
4. Beim ersten Start fragt MGD-DevOS nach einem Projekt-Root-Ordner (dem
   Ordner, der deine Projekt-Unterordner enthält). Es werden nur
   Dateien gelesen, nichts automatisch verändert.

## Was diese Version schon kann

- Projektregister: erkennt echte Projektordner (Git, README, AGENTS.md, ...)
  im gewählten Projekt-Root und öffnet ihre Dokumente.
- Einstellungen: Light/Dark/System-Theme, Akzentfarbe.
- Agentic Control Panel: zeigt Agenten, Skills und Integrationen, die es aus
  echten Projektdateien liest (AGENTS.md, catalog/*.json) – niemals einen
  erfundenen „aktiv"-Status ohne echten Live-Adapter.

## Was noch fehlt

Kein Live-Agenten-Adapter, keine App-Sperre/Secret-Verwaltung, keine
Stripe-Spenden, keine Code-Signierung/Notarisierung. Details siehe README.md
im Quellrepository.

## Deinstallation

MGD-DevOS.app aus dem Programme-Ordner in den Papierkorb ziehen. Lokal
gespeichert werden ausschließlich Theme, Akzentfarbe und der gewählte
Projekt-Root-Pfad (keine Zugangsdaten).
