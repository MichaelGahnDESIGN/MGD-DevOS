# Dashboard und Tabs

Die App ist ein Tab-Browser für lokale Projekt-Dashboards. Ein Dashboard ist die `index.html`
im Projektordner (erzeugt vom Befehl `/dashboard` des Projektmanagers).

## Verhalten

- Tab 0 „Übersicht" ist immer da und nicht schließbar.
- Ein Projekt öffnet höchstens einen Tab; erneutes Öffnen wechselt dorthin.
- Beim Schließen wählt die App den Nachbar-Tab.
- Tabs bleiben im Speicher (IndexedStack), Zustand geht beim Wechseln nicht verloren.

## Sicherheitsgrenzen des Webviews

- Erlaubt sind nur `file://`-Adressen innerhalb des Projektordners (Pfadprüfung gegen `..`).
- `http(s)`-Links öffnen im Systembrowser, nichts wird im Webview geladen.
- Alle anderen Schemata werden blockiert.
- Kein Zugriff der Seite auf andere `file://`-Ursprünge, keine Brücke zur App, keine Pop-ups.
- Inhalte aus Projektdateien gehören im Dashboard als Text ausgegeben, nie als HTML (XSS-Schutz).

## Plattformen

| Plattform | Anzeige |
|---|---|
| macOS, Windows | eingebettet (`flutter_inappwebview`) |
| Linux | kein eingebettetes WebView verfügbar, Knopf öffnet den Standardbrowser |
| Web (nur Entwicklung) | Knopf öffnet den Browser |

## Downloads, Speichern und Dialoge im Webview

Der eingebettete Webview hat keine Download-Behandlung und keine Brücke zur App. Seiten, die per
Blob-Download exportieren oder `alert()`/`confirm()` nutzen, funktionieren dort nicht zuverlässig. Deshalb
brauchen Dashboards und Vorlagen einen Ausweichweg auf der Seite selbst: Export-Fenster mit „Kopieren",
eigene Bestätigungsdialoge, `try/catch` um `localStorage` mit sichtbarem Hinweis. Die Vorlagen
`Fragenkatalog.template.html` (Fragenkatalog-Skill) und `dashboard/index.html` (Projektmanager) tun das seit dem 24.09.2026.
Linux und Web öffnen das Dashboard im normalen Browser, dort gelten die üblichen Browser-Regeln.

**Ungeprüft:** Das Laden von `file://` im eingebetteten WebView wurde noch nicht auf einem echten
macOS- oder Windows-Gerät getestet.
