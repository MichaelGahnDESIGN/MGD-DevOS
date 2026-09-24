# `/thread`: Arbeit sichern und an Codex oder Claude Code übergeben

`MGD_AI-Thread` gehört zum Projektstart. Der eigenständige Skill erstellt eine
Übergabe, wenn ein Gespräch zu lang wird oder der Nutzer den Agenten wechselt.
Der Projektmanager richtet die Skill-Datei und die passenden
`/thread`-Befehle für Codex und Claude Code ein.

## Ablauf

1. Der Agent prüft Git-Status, Commits, Projektregeln und offene Aufgaben.
2. Fertige, geprüfte Änderungen werden getrennt committed und auf den
   vorgesehenen GitHub- oder Gitea-Branch gepusht, sofern dies für das
   Projekt erlaubt ist. Der Remote-Stand wird danach kontrolliert.
3. Unfertige, fehlgeschlagene oder fremde Änderungen bleiben ausdrücklich
   als offen erkennbar. Secrets, Backups und Playtest-Artefakte gehören nicht
   in den Push.
4. Die Übergabe wird als Datei unter `PROJEKT/UEBERGABEN/` oder, falls es
   keinen `PROJEKT/`-Ordner gibt, unter `UEBERGABEN/` geschrieben. Falls das
   Projekt Übergaben versioniert, wird auch diese Datei nach Prüfung gepusht.
5. Der Nutzer erhält Dateipfad, `cat`-Befehl und einen kurzen Startprompt für
   den neuen Agenten. Der Prompt nennt genau eine nächste Aufgabe.

Ein Push nach GitHub oder Gitea veröffentlicht Quellcode im vorgesehenen
Repository. Er ist **kein** Deployment einer produktiven App oder Website.
Wenn Push oder Deployment fehlen, steht das mit Grund in der Übergabe.

Quelle und vollständige Regeln:
[MGD_AI-Thread](https://github.com/MichaelGahnDESIGN/MGD_AI-Thread).
