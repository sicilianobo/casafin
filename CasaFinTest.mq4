//+------------------------------------------------------------------+
//|                                                CasaFinTest.mq4   |
//|                                          Copyright 2024, CasaFin |
//|                                       Test-Script für CasaFin EA |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, CasaFin"
#property link      ""
#property version   "1.00"
#property strict
#property script_show_inputs

//--- Input-Parameter für Tests
input bool TestRSICalculation = true;     // RSI-Berechnung testen
input bool TestOrderFunctions = false;    // Order-Funktionen testen (nur Demo!)
input bool TestUtilityFunctions = true;   // Hilfsfunktionen testen

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("=== CasaFin EA Test-Script gestartet ===");
   
   if(TestRSICalculation)
      TestRSI();
      
   if(TestUtilityFunctions)
      TestUtilities();
      
   if(TestOrderFunctions && !IsRealAccount())
      TestOrders();
   else if(TestOrderFunctions && IsRealAccount())
      Print("WARNUNG: Order-Tests nur auf Demokonten erlaubt!");
      
   Print("=== Test-Script beendet ===");
}

//+------------------------------------------------------------------+
//| Testet RSI-Berechnungen                                         |
//+------------------------------------------------------------------+
void TestRSI()
{
   Print("--- RSI-Test ---");
   
   double rsi14 = iRSI(NULL, 0, 14, PRICE_CLOSE, 1);
   double rsi21 = iRSI(NULL, 0, 21, PRICE_CLOSE, 1);
   
   Print("RSI(14): ", DoubleToString(rsi14, 2));
   Print("RSI(21): ", DoubleToString(rsi21, 2));
   
   // Test der Signallogik
   if(rsi14 < 30)
      Print("RSI-Signal: ÜBERVERKAUFT - Kauf-Signal");
   else if(rsi14 > 70)
      Print("RSI-Signal: ÜBERKAUFT - Verkauf-Signal");
   else
      Print("RSI-Signal: NEUTRAL - Kein Signal");
}

//+------------------------------------------------------------------+
//| Testet Hilfsfunktionen                                          |
//+------------------------------------------------------------------+
void TestUtilities()
{
   Print("--- Hilfsfunktionen-Test ---");
   
   // Spread-Test
   double spread = (Ask - Bid);
   double spreadPips;
   
   if(Digits == 2 || Digits == 3)
      spreadPips = spread / Point;
   else if(Digits == 4 || Digits == 5)
      spreadPips = spread / Point / 10.0;
   else
      spreadPips = spread / Point;
      
   Print("Aktueller Spread: ", DoubleToString(spreadPips, 1), " Pips");
   
   // Markt-Info
   Print("Symbol: ", Symbol());
   Print("Digits: ", Digits);
   Print("Point: ", Point);
   Print("Min Lot: ", MarketInfo(Symbol(), MODE_MINLOT));
   Print("Max Lot: ", MarketInfo(Symbol(), MODE_MAXLOT));
   Print("Lot Step: ", MarketInfo(Symbol(), MODE_LOTSTEP));
   
   // Account-Info
   Print("Account Balance: ", AccountBalance());
   Print("Account Equity: ", AccountEquity());
   Print("Free Margin: ", AccountFreeMargin());
   
   if(IsRealAccount())
      Print("Kontotyp: ECHTKONTO");
   else
      Print("Kontotyp: DEMOKONTO");
}

//+------------------------------------------------------------------+
//| Testet Order-Funktionen (nur Demo!)                             |
//+------------------------------------------------------------------+
void TestOrders()
{
   Print("--- Order-Funktionen-Test (nur Demo) ---");
   
   if(IsRealAccount())
   {
      Print("FEHLER: Order-Tests nur auf Demokonten!");
      return;
   }
   
   // Prüfe aktuelle Orders
   int totalOrders = OrdersTotal();
   Print("Aktuelle Orders: ", totalOrders);
   
   for(int i = 0; i < totalOrders; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         Print("Order #", OrderTicket(), 
               " - Type: ", OrderTypeToString(OrderType()),
               " - Lots: ", OrderLots(),
               " - Symbol: ", OrderSymbol());
      }
   }
   
   Print("Order-Funktionstest abgeschlossen");
}

//+------------------------------------------------------------------+
//| Konvertiert OrderType zu String                                 |
//+------------------------------------------------------------------+
string OrderTypeToString(int orderType)
{
   switch(orderType)
   {
      case OP_BUY:       return("BUY");
      case OP_SELL:      return("SELL");
      case OP_BUYLIMIT:  return("BUY LIMIT");
      case OP_SELLLIMIT: return("SELL LIMIT");
      case OP_BUYSTOP:   return("BUY STOP");
      case OP_SELLSTOP:  return("SELL STOP");
      default:           return("UNKNOWN");
   }
}