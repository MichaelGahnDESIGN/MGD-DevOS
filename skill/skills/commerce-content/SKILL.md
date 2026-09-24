---
name: commerce-content
description: Plane und führe MGD-Workflows für Blog, Shopware, JTL-Shop, Shopify oder WooCommerce sicher aus. Verwenden bei E-Commerce-Inhalten, Shop-Plugins, SEO, Produktkennzeichnung oder Shop-Audits.
---

# Commerce und Content

Wähle zuerst Plattform, Version, Zielumgebung und Änderungsart: Inhalt,
Design, Plugin, Daten, Checkout, SEO oder Veröffentlichung. Lies anschließend
[`catalog/integrations.json`](../../catalog/integrations.json). Diese Datei
enthält die geprüften MGD-Quellen und ihre Grenzen.

## Passende MGD-Workflows

- Für WordPress-Artikel nutze den
  [MGD Blogpost Skill](https://github.com/MichaelGahnDESIGN/MGD_Blogpost-Skill):
  Recherche, Faktencheck, SEO, Bildkonzept und Social-Entwürfe. Mit
  Schreibzugriff entsteht standardmäßig ein Entwurf. Ein Publizieren oder
  Posten auf Facebook/Instagram benötigt eine separate Freigabe.
- Für JTL-Shop-5-OnPage-Composer-Aufgaben nutze den
  [MGD JTL OPC Skill](https://github.com/MichaelGahnDESIGN/MGD_JTL-OPC_SKILL).
  Seine Veröffentlichung wirkt live: Backup, Zielbereich und Freigabe sind
  vor jedem Schreibvorgang Pflicht.
- Für Shopware- oder JTL-Plugins prüfe Version, Release-Hinweise,
  Kompatibilität, Staging, Backup und den relevanten Kaufpfad. Plugins werden
  nicht mit Agent-Skills verwechselt und nicht automatisch installiert.

## Shopify und WooCommerce

Der Katalog führt Shopify und WooCommerce als Plattformpfade. Zum dokumentierten
Stand gibt es dafür kein eindeutig zuordenbares öffentliches MGD-Skill-Repo.
Erfinde keinen Skill und installiere keine beliebige Erweiterung. Prüfe zuerst
den vorhandenen Shop, seine Apps/Plugins, Theme-Anpassungen, API-Rechte,
Staging-Möglichkeit und Zahlungswege. Schlage danach konkret benötigte
Kompetenzen vor.

## Sicherheits- und Veröffentlichungsgrenzen

1. Nutze produktive Zugänge nur nach konkreter Zustimmung für die Zielaktion.
2. Verwalte Zugangsdaten ausschließlich über den freigegebenen Secret-Speicher;
   niemals im Prompt, Git, Dashboard oder Screenshot.
3. Sichere vor Migrationen, Plugin-Aktivierungen und Massenänderungen ein
   überprüfbares Backup und einen Rückfallweg.
4. Prüfe Warenkorb, Checkout, Steuern, Versand, Sprache und Mobilansicht nach
   einer Shop-Änderung. Rechtliche Hinweise bleiben einer fachlichen Prüfung
   vorbehalten.
5. Dokumentiere Auswahl, Freigabe, Prüfungen und offene Risiken in der Living
   Documentation.
