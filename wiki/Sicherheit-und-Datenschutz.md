# Sicherheit und Datenschutz

## Grundsätze

- Alles lokal, keine Telemetrie, keine Konten.
- Keine Zugangsdaten, Tokens oder Secrets in der App, in Logs oder in Einstellungen.
- Der Scanner liest nur im gewählten Projektordner. `SECRETS/` wird nicht gelesen.
- Ein Desktop-Client kann keine Geheimnisse sicher halten. Deshalb liegt nichts Abrufbares
  hinter einem GitHub-Token.

## Webview

Siehe [Dashboard und Tabs](Dashboard-und-Tabs.md): nur Dateien im Projektordner, externe Links im
Systembrowser, keine Brücke zur App.

## Netzwerk

Im Normalbetrieb keine Zugriffe. Der ältere Webview-Wrapper (`lib/webview_app.dart`, inaktiv) würde
eine öffentliche JSON-Konfiguration laden ([MGD-DevOS-config](https://github.com/MichaelGahnDESIGN/MGD-DevOS-config), keine Secrets).

## Zahlungen

Die App verarbeitet nie Kartendaten. Siehe [Stripe-Spenden](Stripe-Spenden.md).

## DSGVO

Keine pauschale Konformitätsaussage. Bei öffentlichem Vertrieb sind Impressum, Datenschutzerklärung
und Prüfung aktivierter Drittanbieter nötig. Das ersetzt keine Rechtsberatung.

## Sicherheitslücken melden

Bitte privat an den Repository-Eigentümer, nicht als öffentliches Issue.
