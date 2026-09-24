# MGD-DevOS: sicheres Stripe-Spendenmodul

## Ziel

Unten rechts erscheint ein zurückhaltender Spenden-Button. Er öffnet ein
Modal mit den Beträgen **1 €, 5 €, 10 €** und **eigener Betrag**. Ein Hinweis
erklärt in einfachen Worten, dass die Zahlung über Stripe erfolgt und MGD-DevOS
keine Kartendaten verarbeitet oder speichert.

## Sichere Umsetzung

Die Flutter-App verwendet keine Stripe-Secret-Keys und verarbeitet weder
Kartennummern noch CVC. Sie öffnet eine von Stripe gehostete Zahlungsseite im
Standardbrowser.

Der Nutzer wünscht ausdrücklich ein eigenes Live-System **„MGD DevOS“** unter
„Stripe Accounts“. Vor der Einrichtung ist im authentifizierten Dashboard zu
klären, ob damit ein zusätzliches Stripe-Konto innerhalb der bestehenden
Organisation gemeint ist und welcher Rechtsträger/Auszahlungsempfänger dafür
gilt. Ein bloßes Produkt im bestehenden Konto erfüllt diesen Wunsch nicht
automatisch. Für gewöhnliche eigene Zahlungen ist ein Stripe-Connect-Konto
nicht erforderlich; Connect wäre ein anderes Produkt für Plattformzahlungen.
Die bisherige Stripe-Sitzung zeigte nur die Anmeldeseite. Ein Konto, Produkt
oder Live-Payment-Link wurde noch nicht angelegt.

Nach Klärung und Anmeldung empfohlene Konfiguration im richtigen Live-Konto:

1. Eigenes Produkt **MGD DevOS Unterstützung** im Live-Modus anlegen.
2. Drei einmalige Payment Links für 1 €, 5 € und 10 € anlegen.
3. Einen weiteren Payment Link mit „Kunde wählt Betrag“ für den eigenen Betrag
   anlegen; Mindest- und Höchstbetrag bewusst festlegen.
4. Die Schaltfläche als Spende kennzeichnen und die lokale Sprache/Branding
   prüfen.
5. Für Zahlungsnachweise die Stripe-E-Mail-Belege aktivieren; bei Bedarf die
   Erstellung einer Rechnung nach erfolgreicher Einmalzahlung konfigurieren.
6. Die öffentlichen Payment-Link-URLs als Konfiguration eintragen. Sie sind
   keine Secrets, dürfen aber nur aus einer signierten/reviewten DevOS-Version
   stammen.

Für „Rechnungen ansehen und herunterladen“ wird kein eigenes Rechnungssystem
gebaut. Nach einer Zahlung verweist die App auf die Stripe-Bestätigung und den
Beleg. Ein Stripe Customer Portal ist nur sinnvoll, wenn es im eigenen
Stripe-Billing-Tarif verfügbar und für die gewählte Zahlungsart eingerichtet
ist; es benötigt immer einen konkreten Stripe-Customer und eine kurzlebige,
serverseitig erzeugte Portal-Sitzung.

## Was nicht passiert

- keine Kartendaten, CVC, IBAN oder Stripe-Secret-Keys in MGD-DevOS;
- keine frei erfundene Zahlungsbestätigung;
- keine Stripe-Webhooks ohne abgesicherten Server, Signaturprüfung und
  Idempotenz;
- keine automatische Rückerstattung, Rechnungskorrektur oder Auszahlung;
- keine rechtliche oder steuerliche Bewertung einer „Spende“.

Die rechtliche Bezeichnung, Umsatzsteuer, Rechnungsangaben und mögliche
Gemeinnützigkeits-Aussagen müssen vor Livegang fachlich geprüft werden. Eine
Unterstützungszahlung ist nicht automatisch eine steuerlich abzugsfähige
Spende; die Oberfläche darf keinen Spendenbeleg versprechen, solange die
Voraussetzungen nicht belegt sind.
