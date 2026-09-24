# Bestehende Projekte migrieren

Der MGD-DevOS ergänzt bestehende Projekte, ohne ihre funktionierende
Struktur oder Geschichte stillschweigend zu ersetzen.

## Ablauf

1. Regeln, README, Dokumentation, Git-Status, `.gitignore`, Automatisierungen
   und vorhandene Skills lesen.
2. Kanonische Dokumentation bestimmen. Living Documentation wird verlinkt, nicht
   dupliziert.
3. Bestehende Projektstart- oder Dashboard-Lösungen erkennen. Der frühere
   `project-start-assistant` aus MGD Living Documentation erhält nur einen
   Kompatibilitätsverweis auf diesen Projektmanager.
4. Fehlende, konfliktfreie Elemente ergänzen: Dashboard, Manifest,
   Schutzordner, `.gitignore` und verständliche Einführung.
5. Den Skill-Audit durchführen und nur Empfehlungen aussprechen. Installation,
   Update oder Entfernung brauchen weiterhin die ausdrückliche Zustimmung.
6. Links, Git-Diff, Tests und Schutzgrenzen prüfen; offene Konflikte sichtbar
   dokumentieren.

## Geschützte Bereiche

`SECRETS/` wird ohne konkrete Zustimmung für einen benannten Pfad nie gelesen,
verändert, kopiert, gelöscht oder veröffentlicht. `USER CONCEPT/` wird als
lokale Ideensammlung erhalten; Dateien werden bei Bedarf kopiert, nicht
verschoben oder gelöscht.

## Was nicht automatisiert wird

Keine Änderungen an produktiven Diensten, Datenbanken, Deployments,
Authentifizierung, existierenden Secrets, externen Skills oder bereits
getrackten verdächtigen Dateien. Solche Befunde werden dokumentiert und zur
Entscheidung vorgelegt.
