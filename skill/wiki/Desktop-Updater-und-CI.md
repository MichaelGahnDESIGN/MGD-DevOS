# Desktop-Apps bauen und aktualisieren (GitHub Actions + Releases)

Wiederverwendbares Wissen aus MGD-DevOS (Flutter-Desktop) für jedes Projekt,
das Installer für macOS, Windows und Linux ausliefern soll. Status je Punkt
ist ausgewiesen: **belegt** (im MGD-DevOS-Lauf tatsächlich beobachtet) oder
**Konzept** (bewährtes Muster, in MGD-DevOS noch nicht umgesetzt/geprüft).

## 1. Warum GitHub Actions

Ein lokaler Rechner braucht für macOS-Builds das volle Xcode (Installation
nur über den App Store mit Apple-ID). GitHub-Runner bringen es mit.
Ein Build je Plattform auf dem jeweiligen Runner ist außerdem die einzige
echte Verifikation für Windows und Linux. (**belegt**: lokal fehlte Xcode,
`flutter build macos` brach ab.)

Bewährtes Grundgerüst (`.github/workflows/ci.yml`, Vorlage siehe
MGD-DevOS):

| Job | Runner | Inhalt |
|---|---|---|
| `analyze_test` | ubuntu-latest | `flutter analyze`, `flutter test` – schnelles Feedback |
| `macos` | macos-14 | Release-Build, Packaging als DMG (`hdiutil`), Artefakt-Upload |
| `windows` | windows-latest | `flutter build windows --release`, ZIP, Artefakt-Upload |
| `linux` | ubuntu-latest | apt: `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev`, Build, TAR.GZ |

Setup von Flutter über `subosito/flutter-action`. Build-Jobs mit `needs:
analyze_test`, damit fehlerhafter Code keine teuren macOS-Minuten verbraucht.

## 2. Stolperfallen (alle **belegt** im MGD-DevOS-Lauf)

- **Workflow-Datei pushen braucht das `workflow`-Scope.** Ein
  `gh`-Token nur mit `repo` wird abgelehnt („without `workflow` scope").
  Abhilfe: `gh auth refresh -h github.com -s workflow` (Browser-Bestätigung
  durch den Nutzer nötig).
- **Abrechnung kann alle Jobs blockieren.** Symptom: Jobs starten nicht,
  Hinweis „recent account payments have failed or your spending limit needs
  to be increased". Ursache liegt im Account (Zahlungsmittel oder
  Ausgabenlimit), nicht im Workflow. Nur der Kontoinhaber kann das beheben.
- **Private Repos verbrauchen Minuten mit Multiplikator** (Stand meiner
  Kenntnis: Linux 1×, Windows 2×, macOS 10× auf Standard-Runnern; im
  aktuellen GitHub-Billing prüfen). Öffentliche Repos sind für Standard-
  Runner kostenlos. Deshalb macOS-Jobs erst nach bestandenem `analyze_test`
  starten und nicht bei jedem Pull-Request-Push.
- **Neues `flutter create --platforms=web .` legt eine Standard-
  `test/widget_test.dart` an**, die auf eine nicht mehr vorhandene `MyApp`
  verweist und `flutter analyze` bricht. Nach dem Befehl löschen.

## 3. Auto-Update über GitHub Releases – Konzept

Ziel: einmal per CI kompilieren, Nutzer erhalten Updates ohne Neuinstallation
von Hand. **Konzept, in MGD-DevOS noch nicht implementiert.**

### 3.1 Grundregel: Der Client darf keinen Token halten

Ein Desktop-Client kann Geheimnisse nicht sicher aufbewahren; jeder kann sie
auslesen. Ein privates Repo antwortet anonym mit 404. Folge: alles, was die
App ungefragt abruft (Update-Info und die Installer selbst), muss ohne
Login erreichbar sein. Zwei saubere Wege:

1. **Öffentliches Release-/Config-Repo** nur für Update-Metadaten und
   Installer (Quellcode bleibt in einem privaten Repo). Beispiel:
   `MichaelGahnDESIGN/MGD-DevOS-config`.
2. **Eigener kleiner Server**, der die Authentifizierung übernimmt.
   Mehr Kontrolle, aber Betriebsaufwand.

Installer sind für Endnutzer per Definition nicht geheim: sie müssen sie ja
herunterladen können.

### 3.2 Ablauf

1. Version in `pubspec.yaml` erhöhen (SemVer), Git-Tag `vX.Y.Z` setzen.
2. Tag löst einen Release-Workflow aus: baut alle Plattformen, hängt
   Installer und eine **SHA-256-Prüfsummendatei** an das GitHub Release.
3. App liest beim Start (nach Nutzer-Opt-in, keine Telemetrie als
   Standard) `latest.json` bzw. die Releases-API des öffentlichen Repos,
   vergleicht mit der eigenen Version (`package_info_plus`) und zeigt bei
   neuerer Version einen Hinweis.
4. Nutzer bestätigt; App lädt den Installer, **prüft die SHA-256-Summe**
   und startet ihn bzw. übergibt an das Update-Framework.

### 3.3 Plattformrealität

| Plattform | Automatisch möglich? | Bemerkung |
|---|---|---|
| macOS | Ja, mit Sparkle (Paket `auto_updater`) | Erfordert Code-Signierung; Notarisierung braucht Apple Developer Program (Apple-ID). Ohne beides zeigt Gatekeeper Warnungen. |
| Windows | Ja, mit WinSparkle (Paket `auto_updater`) | Signierung empfohlen, sonst SmartScreen-Warnung. |
| Linux | Nicht zuverlässig | `auto_updater` unterstützt nur macOS und Windows (**belegt** über pub.dev). Ehrlich lösen: Update-Hinweis + Link zum Download, oder AppImage mit AppImageUpdate. |

### 3.4 Sicherheitsregeln für den Updater

- Nur HTTPS, Download nur vom festen, im Code hinterlegten Repo-Eigentümer.
- Integrität prüfen (SHA-256, besser signierte Appcast-Dateien) vor jeder
  Ausführung. Nie ungeprüfte Downloads automatisch starten.
- Nutzer-Zustimmung vor Installation; kein stilles Nachladen von Code.
- Keine Secrets im Client, keine Nutzerdaten in Update-Anfragen.
- Signierschlüssel und Zertifikate ausschließlich als GitHub-Secrets im
  Release-Workflow, nie im Repository.

## 4. Übertragung auf andere Projekte

- Workflow-Vorlage einmal pflegen und je Projekt kopieren oder als
  wiederverwendbaren Workflow (`workflow_call`) in einem zentralen
  öffentlichen Repo ablegen.
- Je Projekt nur Projektname, Build-Befehl und Artefaktpfade anpassen.
- Vor dem ersten Release prüfen: `workflow`-Scope, Abrechnungsstatus,
  öffentliche Erreichbarkeit der Update-Metadaten.
- Rechtliche Dokumente (Impressum, Datenschutz) hängen davon ab, ob die App
  nur privat oder öffentlich vertrieben wird; nicht pauschal DSGVO-konform
  behaupten.

## 5. Xcode-MCP für lokale macOS-Builds (Ergänzung, ersetzt Actions nicht)

[`getsentry/XcodeBuildMCP`](https://github.com/getsentry/XcodeBuildMCP) (MIT) ist ein MCP-Server, mit
dem ein Agent Xcode-Projekte lokal baut, testet und startet. Er steht als Dritt-Skill im Katalog
(`requiresScan: true`, Pflicht-Sicherheits-Scan vor der Installation).

- Voraussetzungen: macOS 14.5+, **volles Xcode 16+** (kostenlose Apple-ID genügt, kein Developer
  Account), Node 18+ oder Homebrew.
- Einbindung in Claude Code: `claude mcp add xcodebuild -- npx -y xcodebuildmcp@latest mcp`
  (laut README on-demand per npx möglich; Client-Konfigurationen auf xcodebuildmcp.com/docs/clients).
- Grenze: nur iOS/macOS. Windows- und Linux-Builds gehen weiterhin nur über GitHub Actions (Abschnitt 1).
- Faustregel: lokal Xcode-MCP für schnelle macOS-Iteration, Actions für alle Plattformen und Releases.
- Status: nicht in MGD-DevOS erprobt, da hier noch kein Xcode installiert ist.
