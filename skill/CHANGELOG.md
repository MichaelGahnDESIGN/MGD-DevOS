# Changelog

Alle nennenswerten Änderungen an diesem Projekt werden hier dokumentiert.

## Unreleased

- Katalog: Godot AI (hi-godot/godot-ai, MIT, Asset Library 5050) als Editor-MCP-Plugin für Spiele-Projekte aufgenommen,
  mit Sicherheitshinweis (nur gegen eine Arbeitskopie, nicht in Exporte).

## 2.4.1 - 2026-09-25

- Dashboard-Vorlage: Verbindungslinien im Projektfluss werden jetzt auch in eingebetteten oder verdeckten Webviews
  sofort gezeichnet (vorher nur per `requestAnimationFrame`, das dort pausiert). In der MGD-DevOS-App auf macOS geprüft.

## 2.4.0 - 2026-09-24

- Dashboard-Vorlage als Programm-Oberfläche (Control Plane): Titelleiste mit Status, Icon-Leiste mit echten
  Ansichten (Übersicht, Aufgaben & Risiken, Arbeitsweise, Skills, Dokumentation) statt toter Links, Projektfluss-
  Graph mit Verbindungslinien, ein-/ausklappbarer Inspektor, Statusleiste mit Pflicht-Footer. Tastatur: 1–5, I, „,",
  Pfeiltasten, Esc; Deep-Links per `#ansicht`. Funktioniert als lokale Datei, in Sandbox-Vorschauen und ohne
  Browser-Speicher. Neue Akzentfarbe „MGD – Rot". Platzhalter und Einstellungs-IDs unverändert.

- Dashboard-Vorlage neu gestaltet: feinere Typografie (Gewichte 400/500/600, kleine Versal-Titel), Haarlinien statt kräftiger Rahmen,
  ruhige Karten, überarbeiteter Einstellungsdialog mit sauberen Auswahlfeldern, verfeinerter Pflicht-Footer, Fokusrahmen und Bewegung
  reduzieren berücksichtigt. Struktur, IDs und Platzhalter unverändert.

- Dashboard-Vorlage: „Speichern" und „Zurücksetzen" in den Einstellungen funktionieren auch, wenn der
  Browser-Speicher gesperrt ist (Artefakt-Vorschau, eingebettete Webviews); die Einstellung gilt dann bis zum Schließen.

## 2.3.0 - 2026-09-24

- `MGD_AI-Thread` als zweiten verbindlichen Basis-Skill ergänzt. `/thread`
  sichert geprüfte Arbeit vor einer Übergabe im vorgesehenen Git-Remote,
  sofern Projektregeln und Berechtigungen dies erlauben.
- Die bisher widersprüchlichen `mandatory`-Werte der vier wählbaren
  MGD-Kern-Skills im Katalog korrigiert.
- MGD-DevOS-Architektur für eine lokale Flutter-Agentenzentrale mit
  Agentic-Control-Panel, Light/Dark-Modus, Akzentfarben, optionaler Sperre,
  Rechte-Adaptern und Local-first-Datenschutz ergänzt.
- Sicheres Stripe-Spendenkonzept mit gehostetem Checkout, festen und freien
  Beträgen sowie klaren Grenzen für Belege, Rechnungen und Customer Portal
  dokumentiert.
- Ablauf „Einrichten und Starten" (Textbaustein und Install-Befehl oben in der
  README) mit neuem Schritt 8: Dashboard starten, Desktop-Verknüpfung nach
  Bestätigung, Einweisung.
- Pflicht-Footer „supported by: Michael Gahn DESIGN" mit Logo und Favicon in
  der Dashboard-Vorlage; Assistenten entfernen ihn nie.
- `getsentry/XcodeBuildMCP` als Dritt-Skill (mit Sicherheits-Scan) im Katalog.
- Wiki: „Desktop-Updater und CI" (GitHub Actions, Releases, Updater-Grenzen).
- MGD-DevOS-App (separates Repo) veröffentlicht: Tab-Browser für lokale
  Projekt-Dashboards, https://github.com/MichaelGahnDESIGN/MGD-DevOS.

## 2.2.0 - 2026-09-23

- MGD Blogpost Skill sowie geführte Content- und E-Commerce-Auswahl ergänzt.
- Öffentliche MGD-Quellen für Shopware 6 und JTL-Shop 5 als separate
  Agent-Skills beziehungsweise Shop-Plugins katalogisiert.
- Shopify und WooCommerce als transparente Audit-Pfade ergänzt; es wird kein
  nicht vorhandenes öffentliches MGD-Skill behauptet.
- Neuer `commerce-content`-Skill trennt Entwurf, produktive Shop-Änderung,
  Veröffentlichung und MCP-Zugriff verbindlich.

## 2.1.0 - 2026-09-23

- Professionelle deutschsprachige README mit Ein-Minuten-Einstieg und
  Übersetzungen für Englisch, Spanisch und Französisch ergänzt.
- Vollständig strukturiertes Impressum vom veröffentlichten Stand von
  michael-gahn.de ergänzt.
- Neuer Skill `repository-documentation` für README-, Wiki-, Demo- und
  Übersetzungsarbeit in GitHub- oder Gitea-Projekten.
- Kompetenz-Matrix und maschinenlesbarer Katalog für Spiele-Engines, Design,
  Apple- und Office-Programme, Daten, WordPress/Divi, Wissen und Social Media.

## 2.0.0 - 2026-09-23

- Repository und Skill zu `MGD_AI-Projektmanager` umbenannt.
- `/Dashboard` als zentrale AI-Dev-OS-Projektzentrale hinzugefügt; der frühere
  `/projektstart`-Befehl bleibt kompatibel.
- Offline-Dashboard mit Light/Dark/Systemmodus, Tool-Akzentfarben, eigener
  Akzentfarbe, zugänglichem Einstellungs-Zahnrad und Browser-Präferenz ergänzt.
- Migrationsregeln festgelegt: der Projektmanager ist die zentrale
  Projektstart-Schicht; Living Documentation, DEV, Todo und Autopilot bleiben
  spezialisierte, koordinierte Skills.
- Vollständige Dashboard- und Migrationsdokumentation sowie Release-Paket
  ergänzt.

## 1.0.0 - Initial Release

- Ersten `/projektstart`-Assistenten hinzugefügt: mehrstufiger Dialog (Interview → Kern-Skills → optionales Plattform-Gerüst → Domain-Skills → Sicherheits-Check → Eintragen der Details → Abschluss-Zusammenfassung).
- `/projektstart-update` hinzugefügt: vergleicht installierte Skill-Stände (`PROJEKT/.projektstart-manifest.json`) mit dem aktuellen Stand der Quell-Repos und bietet gezielte Aktualisierung an.
- `/projektstart-katalog` und `/projektstart-katalog-add` hinzugefügt: Anzeige und Erweiterung des kuratierten Startkatalogs.
- `catalog/skills.json` mit den vier MGD-Kern-Skills, dem Projekt-Plattform-System und acht verifizierten Dritt-Skills als kuratiertem Startpunkt angelegt.
- Sicherheitskonzept ergänzt: jeder Dritt-Skill wird vor Installation mit `NVIDIA/SkillSpector` und/oder `affaan-m/agentshield` gescannt; ohne Scanner erfolgt eine explizite Warnung mit zusätzlicher Bestätigung.
- Ausführliche `README.md`, `LICENSE` (MIT), `IMPRESSUM.md` und `wiki/`-Quellseiten (Home, Befehle, Sicherheitskonzept, Skill-Katalog, Setup, Updater, Beispiel-Ablauf) hinzugefügt.
- Command-Wrapper für Claude Code (`.claude/commands/projektstart.md`) und Codex (`.codex/commands/projektstart.md`) ergänzt.
