# Befehle im Detail

## `/projektstart`

Startet den kompletten 7-Schritte-Assistenten (siehe [SKILL.md](../SKILL.md)).

### Beispiel-Dialog (Ausschnitt Schritt 1–2)

```
> /projektstart

Willkommen beim Projektstart-Assistenten. Ich stelle dir ein paar Fragen, um dein
neues Projekt optimal einzurichten.

1. Wie soll das Projekt heißen?
> Kraut & Rüben Rezept-App

2. Projekttyp? (Spiel/App/Website/Business-Tool/Bibliothek/sonstiges)
> App

3. Zielplattform(en)? (Web, iOS, Android, Desktop, Server/Backend, mehrere)
> iOS + Android

4. Zielgruppe?
> Privatpersonen, die Restegerichte kochen wollen

5. Umfang? (Hobby/privat oder kommerziell)
> kommerziell, geplante App-Store-Veröffentlichung

6. Braucht das Projekt eigene Nutzerkonten, Rollen/Rechte, einen Admin-/
   Moderationsbereich, oder verarbeitet es DSGVO-relevante Daten?
> ja, Nutzerkonten mit gespeicherten Rezepten

7. Sprache(n) für Code/Doku/UI?
> Deutsch (UI), Englisch (Code)

Danke! Jetzt zu den MGD-Kern-Skills — soll ich sie installieren?

[1] MGD_DEV_SKILL — Release/Sync/Backup/Cleanup/Tests/Wissensdokumentation
[2] Fragenkatalog-Skill — interaktiver Design-Fragenkatalog mit KI-Antworten
[3] MGD_Todo_SKILL — selbst-gehostete TODO.html
[4] MGD_Living-Documentation — lebendige Projektdokumentation

Installieren? (alle/einzeln auswählen/keine)
> alle

MGD_Autopilot_SKILL wird zusätzlich verbindlich installiert (kein Ja/Nein
nötig) — er liefert Vertrag, Validierung nach jeder Änderung und
Sicherheitsleitplanken, nach denen dieser gesamte /projektstart-Lauf selbst
abläuft.
MGD_AI-Thread wird ebenfalls verbindlich eingerichtet. Mit /thread kann der
aktuelle Arbeitsstand später mit belegtem Git-Status an Codex oder Claude Code
übergeben werden.
```

### Beispiel-Dialog (Ausschnitt Schritt 3 — Plattform-Frage)

```
Dieses Projekt ist ein Plattform-Projekt (Nutzerkonten mit gespeicherten
Rezepten). Soll ich es mit dem MGD-Plattform-Builder einrichten
(`mgd-platform init --preset community`)?
> ja

mgd-platform ist noch nicht installiert — ich klone
https://github.com/MichaelGahnDESIGN/MGD-Plattform-Builder.git und richte
es gemäß dessen INSTALL.md ein …
✓ mgd-platform verfügbar
✓ mgd-platform init --preset community --target . ausgeführt
✓ mgd-platform validate — keine Fehler
```

### Beispiel-Dialog (Ausschnitt Schritt 4–5 — Domain-Skill mit Scan)

```
Passend zu "App, iOS/Android, kommerziell" schlage ich aus dem Startkatalog vor:

- dickwu/apple-design-skill (770 ⭐, Design/UI/UX) — Cross-Platform UI/UX-Design-
  Reviewer nach Apple HIG, funktioniert mit Flutter, Tauri, Electron, React Native.

Interesse? (ja/nein/weitere live suchen)
> ja

Bevor ich dickwu/apple-design-skill installiere, scanne ich es sicherheitshalber:

✓ NVIDIA/SkillSpector bereits vorhanden
→ Klone https://github.com/dickwu/apple-design-skill.git nach
  /tmp/projektstart-scan/apple-design-skill
→ Führe skillspector scan aus …

Scan-Ergebnis: keine CRITICAL/HIGH-Findings. 1 LOW-Hinweis (fehlende
Lizenzdatei im Quell-Repo).

Trotzdem installieren? (ja/nein)
> ja
✓ dickwu/apple-design-skill installiert unter .claude/skills/apple-design-skill/
```

## `/projektstart-update`

Siehe [Updater.md](Updater.md) für Ablauf und Beispiel-Ausgabe.

## `/thread`

Sichert fertige, geprüfte Arbeit gemäß Projektregeln im vorgesehenen
Git-Remote und erstellt eine ehrliche Übergabedatei samt Startprompt. Details
stehen in [Thread-Übergabe.md](Thread-Übergabe.md). Ein Push nach GitHub ist
kein produktiver Deploy.

## `/projektstart-katalog`

```
/projektstart-katalog --kategorie recht-deutschland
```

```
Katalog-Filter: Kategorie = recht-deutschland

| Name                                  | Sterne | Scan nötig |
|----------------------------------------|--------|-----------|
| Klotzkette/claude-fuer-deutsches-recht | 1.615  | ja        |
```

```
/projektstart-katalog --alle
```
zeigt die vollständige Tabelle aus `catalog/skills.json` (siehe [Skill-Katalog.md](Skill-Katalog.md)).

## `/projektstart-katalog-add <repo-url> <kategorie>`

```
> /projektstart-katalog-add https://github.com/beispiel/mein-geprueftes-skill sicherheit

Repo-Metadaten abgerufen: "Beispielbeschreibung laut GitHub", 42 ⭐
Als kuratierter Eintrag zu catalog/skills.json hinzugefügt
(source: third-party-curated, requiresScan: true, category: sicherheit).
Wird bei künftigen /projektstart-Läufen als Vorschlag berücksichtigt.
```
