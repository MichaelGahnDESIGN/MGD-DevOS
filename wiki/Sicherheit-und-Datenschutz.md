# Sicherheit und Datenschutz

## Grundsätze

- Alles lokal, keine Telemetrie, keine Konten.
- Keine Zugangsdaten, Tokens oder Secrets in der App, in Logs oder in Einstellungen.
- Der Scanner liest nur im gewählten Projektordner. `SECRETS/` wird nicht gelesen.
- Ein Desktop-Client kann keine Geheimnisse sicher halten. Deshalb liegt nichts Abrufbares
  hinter einem GitHub-Token.

## Was gespeichert wird

In den lokalen App-Einstellungen des Betriebssystems (Flutter `shared_preferences`, z. B. unter macOS
`~/Library/Preferences`):

| Wert | Wann |
|---|---|
| Farbschema, Akzentfarbe | nach Änderung in den Einstellungen |
| Projektordner (Pfad) | nach dem Onboarding bzw. einer Änderung |
| Onboarding erledigt | nach dem Onboarding |
| PIN: Länge, Salz, PBKDF2-Hash, Anzahl Iterationen | nur wenn eine PIN gesetzt ist, nie die PIN selbst |
| PIN: Zähler für Fehlversuche und Ende der Wartezeit | nach falschen Eingaben |

Dashboards im eingebetteten Webview speichern ihre eigenen Einstellungen (Darstellung, Fensterlayout, Notizen,
Dashboard-PIN-Hash) im Browser-Speicher (`localStorage`) des Webviews.

## Was geschrieben wird

Die App liest Projektordner. Sie schreibt dort nur an einer Stelle: Der **Grundregeln-Editor**
(Einstellungen › Grundregeln) speichert nach einer Rückfrage `GRUNDREGELN.md` im Hauptordner des gewählten
Projekts und überschreibt eine vorhandene Datei. Sonst verändert die App keine Projektdateien.

## PIN-Sichtschutz

Die PIN (4, 6 oder 8 Ziffern) ist ein **Sichtschutz gegen neugierige Blicke**, kein Zugriffsschutz:

- Sie verdeckt die App beim Start, bis die PIN eingegeben ist. Es gibt **keine automatische Sperre** bei
  Inaktivität oder beim Wechsel in ein anderes Programm.
- Gespeichert wird nur ein PBKDF2-SHA-256-Hash mit Salz in den lokalen App-Einstellungen. Nach 5 Fehlversuchen
  folgt eine Wartezeit (30 s, verdoppelt, höchstens 1 Stunde).
- Wer Zugriff auf dein Benutzerkonto oder deine Dateien hat, kommt trotzdem an die Daten: Die Projektdateien sind
  unverschlüsselt, und wer die App-Einstellungen löscht, entfernt auch die PIN.
- Sie ersetzt nicht die Anmeldung am Rechner und keine Festplattenverschlüsselung.

Das Dashboard hat denselben Sichtschutz im Browser; dort stehen die Inhalte zusätzlich im Klartext in der HTML-Datei.

## macOS: keine App-Sandbox

Die macOS-App läuft ohne App-Sandbox, weil sie beliebige vom Nutzer gewählte Projektordner und
deren Dashboards lesen muss (wie andere Entwickler-Werkzeuge, nicht im App Store). Sie hat damit
dieselben Dateirechte wie dein Benutzerkonto. Laut Code liest sie nur im gewählten Projektordner und
schreibt dort nur `GRUNDREGELN.md`, wenn du im Grundregeln-Editor speicherst.

## Webview

Siehe [Dashboard und Tabs](Dashboard-und-Tabs.md): nur Dateien im Projektordner, externe Links im
Systembrowser, keine Brücke zur App.

## Netzwerk

Im Normalbetrieb keine Zugriffe. Links (z. B. das Label „powered by: Michael Gahn DESIGN" oder GitHub)
öffnen im Systembrowser.

## Zahlungen

Die App verarbeitet nie Kartendaten. Siehe [Stripe-Spenden](Stripe-Spenden.md).

## DSGVO

Keine pauschale Konformitätsaussage. Bei öffentlichem Vertrieb sind Impressum, Datenschutzerklärung
und Prüfung aktivierter Drittanbieter nötig. Das ersetzt keine Rechtsberatung.

## Sicherheitslücken melden

Bitte privat an den Repository-Eigentümer, nicht als öffentliches Issue.
