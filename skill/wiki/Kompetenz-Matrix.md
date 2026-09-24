# Kompetenz-Matrix: Skills, Tools und MCPs

Der Projektmanager ist kein monolithischer Alleskönner. Er stellt je Projekt
passende Kompetenzen zusammen und hält die zentrale Entscheidung im Dashboard
und der Living Documentation fest.

| Bereich | Beispiele | Auswahlregel |
| --- | --- | --- |
| Spiele | Godot, Unity, Unreal, Playtests, Asset-Pipeline | Engine und Zielplattform zuerst klären |
| Design | UI/UX, Apple HIG, Affinity, 3D und Sprites | Originaldateien bleiben lokale Nutzerassets |
| Web/CMS | WordPress, Divi 5, Plugins, MGD_WordPress-MCP | Rechte, Staging und Datenschutz vor Verbindung prüfen |
| Content/Commerce | Blogpost, Shopware 6, JTL-Shop 5, Shopify, WooCommerce | Erst Plattform, Version und Zielaktion prüfen; Entwurf und Live-Veröffentlichung trennen |
| Daten | SQL, Datenmodellierung, Docker, Backup/Restore | Keine Migration ohne Backup und Rückfallplan |
| Büro | Numbers, Tabellen, Dokumente, PDFs | Dateien gezielt und ohne sensible Inhalte verarbeiten |
| Wissen/Social | AI-Knowledge-Vault, Graphify, Meta APIs | Externe Veröffentlichung nur nach konkreter Freigabe |

Die maschinenlesbare Auswahl steht in
[`catalog/capabilities.json`](../catalog/capabilities.json). Das ist ein
Entscheidungskatalog, keine Installationsliste. Jeder externe Skill oder MCP
wird auf Nutzen, Rechte, Kosten, Datenschutz und Sicherheitsrisiken geprüft.

## Blog und Shop-Systeme

Für diesen Bereich ergänzt [`catalog/integrations.json`](../catalog/integrations.json)
die Matrix mit überprüften MGD-Quellen. Der enthaltene
[`commerce-content`-Skill](../skills/commerce-content/SKILL.md) entscheidet
zuerst zwischen Agent-Skill, Shop-Plugin und MCP-Verbindung:

| Plattform | Geführter Einstieg | Wichtige Grenze |
| --- | --- | --- |
| WordPress, Blog und Social | MGD Blogpost Skill | WordPress nur als Entwurf; Social Publishing nur nach Freigabe |
| Shopware 6 | MGD Ausverkauft und MGD AI Kennzeichnung | Kompatibilität, Staging und Checkout vor Aktivierung prüfen |
| JTL-Shop 5 | MGD JTL OPC Skill, SEO, KI-Kennzeichnung und Garantiehinweise | OPC-Publishing ist live; Backup und konkretes Ziel bestätigen |
| Shopify | Bestehende Apps, Theme und API auditieren | Kein eindeutig zuordenbarer öffentlicher MGD-Skill im Katalogstand |
| WooCommerce | WordPress-, Plugin-, Staging- und Zahlungswege auditieren | Kein eindeutig zuordenbarer öffentlicher MGD-Skill im Katalogstand |
