# MGD-DevOS — Wiki

Willkommen beim MGD-DevOS: der zentralen AI-Dev-OS-Projektzentrale
für Claude Code, ChatGPT Codex und kompatible Tools.

## Konzept-Übersicht

Ein neues Projekt beginnt meist mit denselben wiederkehrenden Aufgaben: Projektdaten klären, Dokumentations- und Todo-Struktur aufsetzen, passende Design-/Programmier-/Rechts-Skills suchen, und — oft übersprungen — prüfen, ob diese Skills überhaupt vertrauenswürdig sind, bevor man sie in ein Projekt lässt.

Der MGD-DevOS bündelt das in einer Projektzentrale:

1. **Interview** — erfasst Projektname, -typ, Zielplattform, Zielgruppe, Umfang, Backend-Bedarf und Sprache.
2. **Kern-Skills** — bietet vier wählbare MGD-Skills an (DEV, Fragenkatalog, Todo, Living Documentation) und richtet Autopilot sowie AI-Thread als verbindliche Basis für sichere Abläufe und Übergaben ein.
3. **Plattform-Frage** — bei erkanntem Backend-Bedarf wird das eigenständige Projekt-Plattform-System (`mgd-platform init`) angeboten.
4. **Domain-Skills** — schlägt passende Dritt-Skills zuerst aus einem kuratierten Startkatalog vor, sucht bei Bedarf live auf GitHub weiter.
5. **Sicherheits-Check** — scannt jeden Dritt-Skill vor der Installation mit `NVIDIA/SkillSpector` und/oder `affaan-m/agentshield`.
6. **Details eintragen** — überträgt die Interview-Antworten automatisch in die installierten Skills.
7. **Abschluss** — zeigt, was installiert, eingerichtet und noch offen ist.
8. **Dashboard** — zeigt Stand, Risiken, Skills und nächste Schritte in einer
   lokalen `index.html` mit Einstellungen für Darstellung, Akzentfarbe und
   Browser-Präferenz.

Ein integrierter Updater (`/projektstart-update`) hält alle so installierten Skills auf dem aktuellen Stand.

## Seiten in diesem Wiki

| Seite | Inhalt |
|---|---|
| [Befehle.md](Befehle.md) | Alle Slash-Befehle im Detail mit Beispiel-Dialogen |
| [Sicherheitskonzept.md](Sicherheitskonzept.md) | Der Scan-vor-Installation-Workflow im Detail |
| [Skill-Katalog.md](Skill-Katalog.md) | Vollständige, kommentierte Katalog-Tabelle |
| [Setup.md](Setup.md) | Installationsanleitung Claude Code + Codex |
| [Updater.md](Updater.md) | Funktionsweise von `/projektstart-update` |
| [Beispiel-Ablauf.md](Beispiel-Ablauf.md) | Durchgespieltes Beispiel: Mobile-Game-Projekt |
| [Dashboard.md](Dashboard.md) | `/Dashboard`, Zahnrad, Light/Dark und Tool-Akzentfarben |
| [Migration.md](Migration.md) | Bestehende Projekte sicher und ohne doppelte Zentrale übernehmen |
| [Kompetenz-Matrix.md](Kompetenz-Matrix.md) | Geführte Auswahl für Skills, Programme und MCPs |
| [Thread-Übergabe.md](Thread-Übergabe.md) | `/thread`: geprüfte Arbeit sichern und vollständig an Codex oder Claude Code übergeben |
| [Commerce und Content](../skills/commerce-content/SKILL.md) | Sichere Auswahl für Blog, Shopware, JTL-Shop, Shopify und WooCommerce |

## Einordnung im MGD-Skill-Ökosystem

Der MGD-DevOS ist die zentrale, umfassendere Variante der
"Companion-Skill-Check"-Logik. Living Documentation, DEV, Todo und Autopilot
bleiben spezialisierte Skills. Sie werden über Dashboard, Manifest und
Dokumentation koordiniert, aber nicht dupliziert oder ersetzt.
