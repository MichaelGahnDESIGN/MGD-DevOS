# Mitwirken

Änderungen vorschlagen ist ausdrücklich erwünscht: Issue eröffnen oder Pull Request stellen.

## Lizenz von Beiträgen

MGD-DevOS steht unter der [MGD-Lizenz 1.0](LICENSE). Mit einem Pull Request bestätigst du, dass du die nötigen
Rechte an deinem Beitrag hast, und stimmst zu, dass er unter der MGD-Lizenz veröffentlicht wird. Du räumst dem
Lizenzgeber außerdem ein einfaches, zeitlich unbegrenztes Recht ein, den Beitrag auch unter anderen Bedingungen zu
nutzen (z. B. für Whitelabel-Lizenzen). Das Label „powered by: Michael Gahn DESIGN" bleibt in Beiträgen unverändert.

## Ablauf

1. Fork, Branch, Änderung klein und fokussiert halten.
2. `flutter analyze` und `flutter test` müssen grün sein, neue Funktionen bekommen Tests.
3. Bei Änderungen an Version, Changelog oder Credits: `python3 scripts/sync_meta.py` ausführen
   (`--check` läuft in der CI).
4. Keine Zugangsdaten, Tokens oder Secrets in Code, Tests oder Screenshots.
5. Sicherheitslücken bitte nicht öffentlich melden, sondern privat an den Repository-Inhaber.
