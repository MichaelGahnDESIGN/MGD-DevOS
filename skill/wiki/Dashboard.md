# Dashboard und Einstellungen

`/dashboard` ist die zentrale AI-Dev-OS-Ansicht eines Projekts. Es richtet die
lokale `index.html` ein oder öffnet sie. Die Datei enthält nur bestätigten
Projektstand, offene Punkte, Risiken, Skills und nächste Schritte – niemals
Secrets, personenbezogene Daten oder private Infrastrukturdetails.

## Einstellungen oben rechts

Das Zahnrad oben rechts öffnet die Einstellungen. Es ist ein beschrifteter
Button mit sichtbarem Tastaturfokus und verwendet ein skalierbares SVG-Symbol.

| Einstellung | Wirkung |
| --- | --- |
| Ansicht | System, Hell oder Dunkel |
| Akzentfarbe | Codex Grün, Claude Orange, Allgemein Blau oder eigene Farbe |
| Öffnungsort | Interner Browser, Standardbrowser oder einmal nachfragen |

Die optischen Einstellungen werden lokal im Browser gespeichert. Die
Browser-Präferenz wird zusätzlich in `PROJEKT/.mgd-ai-projektmanager.json`
geführt, damit ein Agent bei `/dashboard` zuverlässig weiß, wie er die Seite
öffnen soll.

## Tool-Oberflächen

In ChatGPT Codex kann die lokale Datei als Site gezeigt werden, wenn die
verwendete Oberfläche diese Funktion anbietet. In Claude Code kann sie als
Artefakt erscheinen. Fehlt eine dieser Funktionen, ist die Datei direkt im
Browser nutzbar. Die `index.html` bleibt unabhängig davon die kanonische Quelle.

## Kurze Erklärung für Menschen

Jedes erzeugte Dashboard enthält den Bereich „So arbeitet dein Assistent“.
Er erklärt in einfachen Sätzen: Regeln werden zuerst gelesen, Skills nur bei
Nutzen eingesetzt, Änderungen werden geprüft, offene Grenzen werden genannt,
`SECRETS/` ist geschützt und `USER CONCEPT/` bewahrt Ideen.
