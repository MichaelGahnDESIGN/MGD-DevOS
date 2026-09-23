# Sicherheit und Datenschutz

## Grundsätze

- Alles lokal, keine Telemetrie, keine Konten.
- Keine Zugangsdaten, Tokens oder Secrets in der App, in Logs oder in Einstellungen.
- Der Scanner liest nur im gewählten Projektordner. `SECRETS/` wird nicht gelesen.
- Ein Desktop-Client kann keine Geheimnisse sicher halten. Deshalb liegt nichts Abrufbares
  hinter einem GitHub-Token.

## macOS: keine App-Sandbox

Die macOS-App läuft ohne App-Sandbox, weil sie beliebige vom Nutzer gewählte Projektordner und
deren Dashboards lesen muss (wie andere Entwickler-Werkzeuge, nicht im App Store). Sie hat damit
dieselben Dateirechte wie dein Benutzerkonto, liest laut Code aber nur im gewählten Projektordner
und schreibt dort nichts.

## Webview

Siehe [Dashboard und Tabs](Dashboard-und-Tabs.md): nur Dateien im Projektordner, externe Links im
Systembrowser, keine Brücke zur App.

## Netzwerk

Im Normalbetrieb keine Zugriffe. Der ältere Webview-Wrapper (`lib/webview_app.dart`, inaktiv) würde
eine öffentliche JSON-Konfiguration laden (`config/mgd-devos-config.json` in diesem Repo, keine Secrets).

## Zahlungen

Die App verarbeitet nie Kartendaten. Siehe [Stripe-Spenden](Stripe-Spenden.md).

## DSGVO

Keine pauschale Konformitätsaussage. Bei öffentlichem Vertrieb sind Impressum, Datenschutzerklärung
und Prüfung aktivierter Drittanbieter nötig. Das ersetzt keine Rechtsberatung.

## Sicherheitslücken melden

Bitte privat an den Repository-Eigentümer, nicht als öffentliches Issue.
