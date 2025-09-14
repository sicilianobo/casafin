# Installation und Setup - CasaFin EA

## Systemanforderungen

- MetaTrader 4 Build 1090 oder neuer
- Windows 7/8/10/11 oder Windows Server 2008/2012/2016/2019
- Internetverbindung für automatischen Handel

## Schritt-für-Schritt Installation

### 1. Dateien kopieren

1. Öffnen Sie MetaTrader 4
2. Klicken Sie auf `Datei` → `Datenordner öffnen`
3. Navigieren Sie zum Ordner `MQL4`
4. Kopieren Sie die folgenden Dateien:
   - `CasaFinEA.mq4` → in den Ordner `Experts`
   - `CasaFinUtils.mqh` → in den Ordner `Include`

### 2. Code kompilieren

1. Öffnen Sie den MetaEditor (F4 in MT4)
2. Navigieren Sie zu `Experts` → `CasaFinEA.mq4`
3. Drücken Sie F7 oder klicken Sie auf "Kompilieren"
4. Prüfen Sie, dass keine Fehler auftreten

### 3. EA aktivieren

1. Starten Sie MetaTrader 4 neu
2. Im Navigator unter "Expert Advisors" sollte "CasaFinEA" erscheinen
3. Ziehen Sie den EA auf das gewünschte Chart
4. Konfigurieren Sie die Parameter im Einstellungsfenster

### 4. AutoTrading aktivieren

1. Klicken Sie auf die Schaltfläche "AutoTrading" in der Toolbar
2. Die Schaltfläche sollte grün werden
3. Ein lächelnder Smiley sollte rechts oben im Chart erscheinen

## Konfiguration

### Grundeinstellungen

**Für Anfänger (Demokonto):**
```
LotSize = 0.01
StopLoss = 100
TakeProfit = 50
RSI_Period = 21
UseTrailingStop = true
```

**Für erfahrene Händler:**
```
LotSize = 0.05
StopLoss = 50
TakeProfit = 100
RSI_Period = 14
UseTrailingStop = true
```

### Erweiterte Einstellungen

- **MagicNumber**: Ändern Sie diese Nummer, wenn Sie mehrere EAs verwenden
- **Slippage**: Erhöhen Sie den Wert bei volatilen Märkten
- **RSI-Level**: Passen Sie die Überverkauft/Überkauft-Level an die Marktbedingungen an

## Überwachung

### Log-Dateien

Alle EA-Aktivitäten werden in den MetaTrader Logs aufgezeichnet:
- Journal-Tab: Allgemeine Meldungen
- Experts-Tab: EA-spezifische Meldungen

### Performance-Monitoring

1. Öffnen Sie das "Terminal" (Strg+T)
2. Tab "Handel": Zeigt aktive Positionen
3. Tab "Kontoverlauf": Zeigt abgeschlossene Trades

## Fehlerbehebung

### Häufige Probleme

**"Expert Advisors sind nicht aktiviert"**
- Lösung: AutoTrading-Button aktivieren

**"Kein Handel möglich"**
- Prüfen Sie: Markt geöffnet, genügend Margin, EA-Einstellungen

**EA startet nicht**
- Kompilierungsfehler beheben
- MetaTrader neu starten

### Kontakt

Bei Problemen oder Fragen erstellen Sie bitte ein Issue im GitHub Repository.

## Haftungsausschluss

⚠️ **WICHTIGER HINWEIS**: 
- Testen Sie den EA immer zuerst auf einem Demokonto
- Automatisierter Handel kann zu erheblichen Verlusten führen
- Überwachen Sie Ihre Positionen regelmäßig
- Verwenden Sie nur Kapital, dessen Verlust Sie verkraften können