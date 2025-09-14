# CasaFin Expert Advisor

Ein automatisiertes Handelssystem für MetaTrader 4, das auf RSI-basierten Signalen handelt.

## Funktionen

- **RSI-basierte Handelssignale**: Verwendet den Relative Strength Index (RSI) zur Identifizierung von überkauften und überverkauften Marktbedingungen
- **Automatisches Risikomanagement**: Konfigurierbare Stop Loss und Take Profit Level
- **Trailing Stop**: Optional aktivierbarer Trailing Stop zur Gewinnmaximierung
- **Anpassbare Parameter**: Alle wichtigen Handelsparameter können angepasst werden

## Parameter

### Handelsparameter
- **LotSize** (0.01): Die Größe der Handelsposition
- **MagicNumber** (12345): Eindeutige Identifikationsnummer für Orders
- **Slippage** (3): Maximaler erlaubter Slippage in Pips

### Risikomanagement
- **StopLoss** (50): Stop Loss Distanz in Pips
- **TakeProfit** (100): Take Profit Distanz in Pips
- **UseTrailingStop** (true): Trailing Stop aktivieren/deaktivieren
- **TrailingStop** (30): Trailing Stop Distanz in Pips

### RSI-Indikator
- **RSI_Period** (14): Periode für RSI-Berechnung
- **RSI_Oversold** (30): Überverkauft-Level für Kauf-Signale
- **RSI_Overbought** (70): Überkauft-Level für Verkauf-Signale

## Installation

1. Kopieren Sie die Datei `CasaFinEA.mq4` in den Ordner `Experts` Ihrer MetaTrader 4 Installation
2. Starten Sie MetaTrader 4 neu oder klicken Sie auf "Aktualisieren" im Navigator
3. Der Expert Advisor erscheint nun unter "Expert Advisors" im Navigator

## Verwendung

1. Ziehen Sie den CasaFin EA auf das gewünschte Chart
2. Passen Sie die Parameter nach Ihren Bedürfnissen an
3. Stellen Sie sicher, dass "AutoTrading" aktiviert ist
4. Der EA wird nun automatisch handeln basierend auf den konfigurierten Parametern

## Handelslogik

Der Expert Advisor verwendet eine einfache RSI-basierte Strategie:

- **Kauf-Signal**: RSI fällt unter das Überverkauft-Level (Standard: 30)
- **Verkauf-Signal**: RSI steigt über das Überkauft-Level (Standard: 70)
- **Nur eine Position pro Richtung**: Der EA öffnet nur eine Kauf- oder Verkaufsposition zur Zeit

## Risikomanagement

- Jede Position wird mit konfigurierbarem Stop Loss und Take Profit eröffnet
- Optional kann ein Trailing Stop aktiviert werden, der den Stop Loss bei profitablen Positionen nachzieht
- Alle Parameter können an die jeweilige Handelsstrategie angepasst werden

## Haftungsausschluss

Dieser Expert Advisor dient nur zu Bildungszwecken. Der automatisierte Handel birgt erhebliche Risiken und kann zu Verlusten führen. Testen Sie alle Einstellungen ausführlich auf einem Demokonto, bevor Sie mit echtem Geld handeln.

## Lizenz

Copyright 2024, CasaFin

Dieses Programm wird "wie besehen" zur Verfügung gestellt, ohne jegliche Gewährleistung.