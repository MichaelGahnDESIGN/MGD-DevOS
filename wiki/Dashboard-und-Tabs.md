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

**Ungeprüft:** Das Laden von `file://` im eingebetteten WebView wurde noch nicht auf einem echten
macOS- oder Windows-Gerät getestet.
