//+------------------------------------------------------------------+
//|                                                     CasaFinEA.mq4|
//|                                          Copyright 2024, CasaFin |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, CasaFin"
#property link      ""
#property version   "1.00"
#property strict

//--- Eingabeparameter
extern double LotSize = 0.01;           // Lot-Größe
extern int    MagicNumber = 12345;      // Magische Nummer
extern int    Slippage = 3;             // Slippage in Pips
extern double StopLoss = 50;            // Stop Loss in Pips
extern double TakeProfit = 100;         // Take Profit in Pips
extern int    RSI_Period = 14;          // RSI Periode
extern double RSI_Oversold = 30;        // RSI Überverkauft Level
extern double RSI_Overbought = 70;      // RSI Überkauft Level
extern bool   UseTrailingStop = true;   // Trailing Stop verwenden
extern double TrailingStop = 30;        // Trailing Stop in Pips

//--- Globale Variablen
int LastBar = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("CasaFin EA initialisiert - Version 1.00");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("CasaFin EA beendet");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Neue Bar prüfen
   if(IsNewBar() == false)
      return;
      
   // RSI berechnen
   double rsi = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, 1);
   
   // Handelslogik
   if(CountOrders(OP_BUY) == 0 && rsi < RSI_Oversold)
   {
      OpenBuyOrder();
   }
   
   if(CountOrders(OP_SELL) == 0 && rsi > RSI_Overbought)
   {
      OpenSellOrder();
   }
   
   // Trailing Stop verwalten
   if(UseTrailingStop)
   {
      ManageTrailingStop();
   }
}

//+------------------------------------------------------------------+
//| Prüft ob neue Bar vorhanden ist                                 |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   if(LastBar != Time[0])
   {
      LastBar = Time[0];
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+
//| Öffnet eine Kauf-Order                                          |
//+------------------------------------------------------------------+
void OpenBuyOrder()
{
   double sl = 0;
   double tp = 0;
   
   if(StopLoss > 0)
      sl = Ask - StopLoss * Point * 10;
   if(TakeProfit > 0)
      tp = Ask + TakeProfit * Point * 10;
   
   int ticket = OrderSend(Symbol(), OP_BUY, LotSize, Ask, Slippage, sl, tp, 
                         "CasaFin Buy", MagicNumber, 0, clrGreen);
   
   if(ticket > 0)
      Print("Kauf-Order eröffnet: Ticket #", ticket);
   else
      Print("Fehler beim Eröffnen der Kauf-Order: ", GetLastError());
}

//+------------------------------------------------------------------+
//| Öffnet eine Verkauf-Order                                       |
//+------------------------------------------------------------------+
void OpenSellOrder()
{
   double sl = 0;
   double tp = 0;
   
   if(StopLoss > 0)
      sl = Bid + StopLoss * Point * 10;
   if(TakeProfit > 0)
      tp = Bid - TakeProfit * Point * 10;
   
   int ticket = OrderSend(Symbol(), OP_SELL, LotSize, Bid, Slippage, sl, tp, 
                         "CasaFin Sell", MagicNumber, 0, clrRed);
   
   if(ticket > 0)
      Print("Verkauf-Order eröffnet: Ticket #", ticket);
   else
      Print("Fehler beim Eröffnen der Verkauf-Order: ", GetLastError());
}

//+------------------------------------------------------------------+
//| Zählt offene Orders                                              |
//+------------------------------------------------------------------+
int CountOrders(int orderType)
{
   int count = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == orderType)
            count++;
      }
   }
   return(count);
}

//+------------------------------------------------------------------+
//| Verwaltet Trailing Stop                                         |
//+------------------------------------------------------------------+
void ManageTrailingStop()
{
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            double newSL = 0;
            
            if(OrderType() == OP_BUY)
            {
               newSL = Bid - TrailingStop * Point * 10;
               if(newSL > OrderStopLoss() && (OrderStopLoss() == 0 || newSL > OrderStopLoss()))
               {
                  if(!OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0))
                     Print("Fehler beim Modifizieren der Buy-Order: ", GetLastError());
               }
            }
            else if(OrderType() == OP_SELL)
            {
               newSL = Ask + TrailingStop * Point * 10;
               if(newSL < OrderStopLoss() && (OrderStopLoss() == 0 || newSL < OrderStopLoss()))
               {
                  if(!OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0))
                     Print("Fehler beim Modifizieren der Sell-Order: ", GetLastError());
               }
            }
         }
      }
   }
}