//+------------------------------------------------------------------+
//|                                               CasaFinUtils.mqh   |
//|                                          Copyright 2024, CasaFin |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, CasaFin"
#property strict

//+------------------------------------------------------------------+
//| Hilfsfunktionen für CasaFin EA                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Konvertiert Pips zu Punkten basierend auf Digits                |
//+------------------------------------------------------------------+
double PipsToPoints(double pips)
{
   if(Digits == 2 || Digits == 3)
      return(pips * Point);
   else if(Digits == 4 || Digits == 5)
      return(pips * Point * 10);
   else
      return(pips * Point);
}

//+------------------------------------------------------------------+
//| Berechnet optimale Lot-Größe basierend auf Risiko               |
//+------------------------------------------------------------------+
double CalculateLotSize(double riskPercent, double stopLossPips)
{
   double accountBalance = AccountBalance();
   double riskAmount = accountBalance * riskPercent / 100.0;
   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double stopLossPoints = PipsToPoints(stopLossPips);
   
   double lotSize = riskAmount / (stopLossPoints * tickValue / Point);
   
   // Mindest- und Maximalwerte prüfen
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   
   if(lotSize < minLot)
      lotSize = minLot;
   else if(lotSize > maxLot)
      lotSize = maxLot;
   else
      lotSize = NormalizeDouble(lotSize / lotStep, 0) * lotStep;
   
   return(lotSize);
}

//+------------------------------------------------------------------+
//| Prüft Handelszeiten                                             |
//+------------------------------------------------------------------+
bool IsTradeTime(int startHour, int endHour)
{
   int currentHour = Hour();
   
   if(startHour < endHour)
      return(currentHour >= startHour && currentHour < endHour);
   else if(startHour > endHour)
      return(currentHour >= startHour || currentHour < endHour);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| Berechnet Spread in Pips                                        |
//+------------------------------------------------------------------+
double GetSpreadInPips()
{
   double spread = Ask - Bid;
   
   if(Digits == 2 || Digits == 3)
      return(spread / Point);
   else if(Digits == 4 || Digits == 5)
      return(spread / Point / 10.0);
   else
      return(spread / Point);
}

//+------------------------------------------------------------------+
//| Formatiert Preis für Ausgabe                                    |
//+------------------------------------------------------------------+
string FormatPrice(double price)
{
   return(DoubleToString(price, Digits));
}

//+------------------------------------------------------------------+
//| Sendet Benachrichtigung (E-Mail/Push)                           |
//+------------------------------------------------------------------+
void SendNotification(string message, bool sendEmail = false, bool sendPush = false)
{
   string fullMessage = "CasaFin EA: " + message + " (" + Symbol() + ")";
   
   Print(fullMessage);
   
   if(sendEmail)
      SendMail("CasaFin EA Benachrichtigung", fullMessage);
      
   if(sendPush)
      SendNotification(fullMessage);
}