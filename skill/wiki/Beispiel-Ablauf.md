# Beispiel-Ablauf: Mobile-Game-Projekt

Ein fiktives kleines Mobile-Game-Projekt ("Sternenstaub-Sammler", ein entspanntes Puzzle-Game für iOS/Android) durchläuft `/projektstart` vollständig.

## 1. Interview

```
> /projektstart

1. Projektname? > Sternenstaub-Sammler
2. Projekttyp? > Spiel
3. Zielplattform(en)? > iOS, Android
4. Zielgruppe? > Gelegenheitsspieler, entspannte Puzzle-Fans, alle Altersgruppen
5. Umfang? > Hobby, evtl. später App-Store-Veröffentlichung
6. Backend-Bedarf (Nutzerkonten/Admin/DSGVO)? > nein, nur lokale Spielstände
7. Sprache(n)? > Deutsch
```

## 2. Kern-Skills (inkl. Autopilot und AI-Thread)

```
Die vier wählbaren MGD-Skills installiere ich auf Wunsch. Autopilot und
AI-Thread gehören verbindlich zum Projektstart: Autopilot prüft den Ablauf,
AI-Thread sichert später fertige Arbeit und schreibt die Übergabe.

[1] MGD_DEV_SKILL — installieren? > ja
[2] Fragenkatalog-Skill — installieren? > ja
[3] MGD_Todo_SKILL — installieren? > ja
[4] MGD_Living-Documentation — installieren? > ja
[5] MGD_Autopilot_SKILL — wird verbindlich installiert (kein Ja/Nein nötig)
[6] MGD_AI-Thread — wird verbindlich installiert (kein Ja/Nein nötig)

✓ MGD_DEV_SKILL installiert (global, ~/.claude/skills/dev/)
✓ Fragenkatalog-Skill installiert (projekt-lokal)
✓ MGD_Todo_SKILL installiert (projekt-lokal)
✓ MGD_Living-Documentation installiert (projekt-lokal)
✓ MGD_Autopilot_SKILL installiert (projekt-lokal)
✓ MGD_AI-Thread installiert (projekt-lokal)
```

## 3. Plattform-Frage — verneint

```
Kein Web- oder Plattform-Projekt und kein Backend-Bedarf (nur lokale
Spielstände) — ich überspringe die Frage nach dem MGD-Plattform-Builder.
```

## 4. Domain-Skill-Vorschlag inkl. Scan-Dialog

```
Passend zu "Spiel, iOS/Android" schlage ich aus dem Startkatalog vor:

- dickwu/apple-design-skill (770 ⭐, Design/UI/UX) — Cross-Platform UI/UX-
  Design-Reviewer nach Apple HIG, funktioniert u. a. mit Flutter.

Interesse? > ja

Bevor ich installiere, scanne ich sicherheitshalber:
✓ NVIDIA/SkillSpector bereits vorhanden
→ Klone dickwu/apple-design-skill nach /tmp/projektstart-scan/apple-design-skill
→ Scan läuft …

Scan-Ergebnis: keine CRITICAL/HIGH/MEDIUM-Findings. Sauber.

Trotzdem noch einmal bestätigen — installieren? > ja
✓ dickwu/apple-design-skill installiert unter .claude/skills/apple-design-skill/
```

Keine weiteren Domain-Skills gewünscht — Live-Suche wird nicht genutzt.

## 5. Details eintragen

```
→ /fragenkatalog-setup mit Projektdaten (Sternenstaub-Sammler, Spiel, iOS/
  Android, Gelegenheitsspieler, Deutsch) angestoßen.
→ /todo-setup ausgeführt, TODO.html angelegt.
→ /todo-add "App-Icon und Store-Assets erstellen"
→ /todo-add "Design-Skill-Ergebnisse (apple-design-skill) in erste UI-Iteration einarbeiten"
→ Living-Documentation-Einstiegsseite mit Projektüberblick und Entscheidung
  "welche Skills installiert wurden und warum" befüllt.
→ PROJEKT/.projektstart-manifest.json mit 7 Einträgen geschrieben
  (4 wählbare MGD-Skills + Autopilot + AI-Thread + 1 Domain-Skill).
```

## 6. Abschluss-Zusammenfassung

```
Installiert:
- MGD_DEV_SKILL (global)
- Fragenkatalog-Skill, MGD_Todo_SKILL, MGD_Living-Documentation (projekt-lokal)
- MGD_Autopilot_SKILL (projekt-lokal, verbindlich)
- MGD_AI-Thread (projekt-lokal, verbindlich)
- dickwu/apple-design-skill (projekt-lokal, Scan: clean)

Eingerichtet:
- /fragenkatalog-setup mit Projektdaten
- TODO.html mit 2 Einstiegs-Todos
- Living-Documentation-Einstiegsseite

Offen:
- MGD-Plattform-Builder nicht eingerichtet (kein Web-/Plattform-Projekt)
- Keine weitere Live-Suche durchgeführt (nicht gewünscht)

Viel Erfolg mit Sternenstaub-Sammler!
```
