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
   Ordner, der deine Projekt-Unterordner enthält). Die App liest diese
   Ordner; schreiben kann nur der Grundregeln-Editor (`GRUNDREGELN.md`,
   erst nach Rückfrage).

## Was diese Version schon kann

- Projektregister: erkennt echte Projektordner (Git, README, AGENTS.md, ...)
  im gewählten Projekt-Root und öffnet ihre Dokumente.
- Tabs für die Projekt-Dashboards (`index.html`) der Projekte.
- Einstellungen: Light/Dark/System-Theme, Akzentfarbe, Grundregeln-Editor,
  Versionen, Credits, Lizenz.
- PIN-Sichtschutz (optional): verdeckt die App beim Start vor neugierigen
  Blicken. Das ist kein Zugriffsschutz: Wer Zugriff auf dein Benutzerkonto
  oder deine Dateien hat, kommt an die Daten; der PIN-Hash liegt in den
  lokalen App-Einstellungen; eine automatische Sperre bei Inaktivität gibt
  es nicht.
- Agentic Control Panel: zeigt Agenten, Skills und Integrationen, die es aus
  echten Projektdateien liest (AGENTS.md, catalog/*.json) – niemals einen
  erfundenen „aktiv"-Status ohne echten Live-Adapter.

## Was noch fehlt

Kein Live-Agenten-Adapter, keine Secret-Verwaltung (Schlüsselbund), keine
Stripe-Spenden, keine Code-Signierung/Notarisierung. Details siehe README.md
im Quellrepository.

## Deinstallation

MGD-DevOS.app aus dem Programme-Ordner in den Papierkorb ziehen. In den
App-Einstellungen von macOS bleiben Farbschema, Akzentfarbe, Projekt-Root-Pfad,
Onboarding-Status und, falls gesetzt, der PIN-Hash mit Fehlversuchszähler
zurück (keine Zugangsdaten).

## Lizenz

MGD-Lizenz 1.0, siehe LICENSE.txt und NOTICE.txt in diesem DMG.
powered by: Michael Gahn DESIGN (https://michael-gahn.de)
