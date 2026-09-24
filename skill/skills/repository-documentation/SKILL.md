---
name: repository-documentation
description: Erstellt oder aktualisiert verständliche README-, Wiki- und Demo-Dokumentation für GitHub oder Gitea. Verwenden bei Repository-Dokumentation, Projektseiten, Wiki-Sync und mehrsprachigen Einstiegen.
---

# Repository-Dokumentation

Erstelle eine klare Einstiegserklärung für Menschen und Agenten. Lies zuerst
Projektregeln, vorhandene README, Dokumentation, Lizenz, Installationsweg und
Git-Status. Behaupte nur überprüfte Funktionen.

## README

Eine README beantwortet kurz: Was ist das? Für wen? Was kann es? Wie wird es
installiert und gestartet? Welche Grenzen, Sicherheitsregeln und Beiträge
gelten? Deutsch ist Standardsprache, Englisch die erste vollständige
Übersetzung. Weitere Sprachen nur pflegen, wenn sie tatsächlich aktuell bleiben.

Nutze echte Demos oder selbst erzeugte, nicht sensible Screenshots. Keine
Screenshots mit Secrets, persönlichen Daten, Tokens oder privaten URLs.

## GitHub und Gitea

Bei GitHub kann die Repository-Wiki als getrenntes Git-Repository geführt
werden. Bei Gitea zuerst die Instanz- und Repository-Regeln prüfen. Die
Markdown-Quellen im Hauptrepository bleiben kanonisch; eine externe Wiki ist
eine geprüfte Ableitung. Vor einem Sync: Links, Lizenz, Geheimnisse und
Sichtbarkeit prüfen.

Offizielle Einstiegspunkte: [GitHub-Wikis](https://docs.github.com/en/communities/documenting-your-project-with-wikis/about-wikis)
und [Gitea-Dokumentation](https://docs.gitea.com/).

## Abschluss

Prüfe Markdown-Links, Dateienamen, Git-Diff und veröffentlichte Inhalte auf
Secrets. Ein Push, Wiki-Sync oder Release passiert nur mit entsprechender
Nutzerberechtigung.
