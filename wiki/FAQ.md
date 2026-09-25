# FAQ

**Braucht die App Internet?** Im Normalbetrieb nein.

**Wo liegen meine Daten?** In deinen Projektordnern. In den lokalen App-Einstellungen liegen Farbschema, Akzentfarbe,
Projektordner, Onboarding-Status und, falls gesetzt, der PIN-Hash samt Fehlversuchszähler. In Projektordner schreibt
die App nur `GRUNDREGELN.md`, wenn du im Grundregeln-Editor speicherst.

**Schützt die PIN meine Projekte?** Nein, sie ist ein Sichtschutz gegen neugierige Blicke beim Start. Wer Zugriff auf
dein Benutzerkonto oder deine Dateien hat, kann die Einstellungen löschen und die Projektdateien direkt lesen. Eine
automatische Sperre bei Inaktivität gibt es nicht.

**Warum zeigt eine Projektkarte „Plattform 0.0.1 Pre-Alpha"?** Das Projekt stammt aus dem
[MGD-Plattform-Builder](https://github.com/MichaelGahnDESIGN/MGD-Plattform-Builder) (`MGD_PLATFORM.yml`); Version und
Status stehen in dessen `version.json`.

**Warum zeigt Linux das Dashboard im Browser?** Das verwendete Plugin hat kein eingebettetes Linux-WebView.

**Warum warnt macOS beim Start?** Die App ist nicht signiert oder notarisiert.

**Warum steht nirgends „aktiv" im Agentic Panel?** Es gibt noch keinen Live-Adapter, die App erfindet keinen Status.

**Kann jemand über die App meine Dateien lesen?** Das Dashboard hat keine Brücke zur App und lädt nur Dateien im Projektordner.

**Ist es DSGVO-konform?** Es sind keine Daten unterwegs, eine pauschale Aussage machen wir nicht.
