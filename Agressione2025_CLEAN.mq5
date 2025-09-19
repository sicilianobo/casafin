//+------------------------------------------------------------------+
//| Agressione2025 - Clean EA with History Learning (MQL5)           |
//+------------------------------------------------------------------+
#property strict
#property version "1.37"

// ------------------------- Inputs ---------------------------------
input int    EMA_Fast=8;
input int    EMA_Slow=21;
input int    RSI_Period=14;
input int    ADX_Period=14;
input int    BB_Period=20;
input int    ATR_Period=14;

input double RSI_Buy=55.0;
input double RSI_Sell=45.0;
input double ADX_Min=18.0;
input double BB_Dev=2.0;

input double SL_ATR=1.8;
input double TP_ATR=3.4;
input double Trail_ATR=1.2;

input bool   UseBreakEven=true;
input bool   UseATRTrailing=true;
input bool   UseSpreadFilter=true;
input bool   UseATRMinFilter=true;
input bool   UseSessionFilter=true;
input bool   UseRiskPercent=true;

input double MaxSpreadPoints=120.0;
input double Min_ATR_Value=0.20;
input double RiskPercent=0.50;
input double FixedLot=0.02;

input double MaxDailyLossPercent=2.0;

input int    TradeStartHour=7;
input int    TradeEndHour=21;

input int    CooldownBars=2;
input int    MaxTradesPerDay=8;
input int    MaxSimultaneousTrades=1;

input double MinProfitToClose=1.00;
input double MaxLossPerTrade=-1.00; // -1.00 -> keine erzwungene Verlust-Schließung

// Basket-TP: schließt nur im Gewinn (Korbbasierend: Symbol + Magic)
input bool   UseBasketTP=true;
input double BasketTPMoney=5.0;

input long   MagicNumber=99009977;
input bool   DebugMode=false;

// Lernen aus Kontohistorie
input bool   LearnFromHistory=true;
input int    HistoryLookbackDays=30;
input int    LearnUpdateHours=6;
input int    LearnMinTrades=15;
input double LearnRiskScaleMax=1.2;
input double LearnRiskScaleMin=0.5;
input double LearnRSIAdjustStep=2.0;
input double LearnATRScaleStep=0.1;

// --------------------- Runtime-Variablen --------------------------
datetime g_lastBar=0;
int      g_lastDay=-1;
int      g_tradesToday=0;
int      g_cooldown=0;

int      g_totalWins=0;
int      g_totalLosses=0;

// Laufzeit-Parameter (lernen)
double   g_RSI_Buy;
double   g_RSI_Sell;
double   g_SL_ATR;
double   g_TP_ATR;
double   g_RiskPct;

datetime g_nextLearnTime=0;

// ---------------------- Zeit-Wrapper ------------------------------
datetime Now(){return TimeTradeServer();}
int CurrentHour(){MqlDateTime t; TimeToStruct(TimeTradeServer(),t); return (int)t.hour;}
int CurrentDayOfMonth(){MqlDateTime t; TimeToStruct(TimeTradeServer(),t); return (int)t.day;}

// ---------------------- Numeric Helpers (ASCII only) --------------
double EPS(){ return 1e-8; }
bool ge(double a,double b){ return (a>b) || (MathAbs(a-b)<EPS()); }
bool le(double a,double b){ return (a<b) || (MathAbs(a-b)<EPS()); }
bool eq(double a,double b){ return MathAbs(a-b)<EPS(); }

// ---------------------- Helper-Funktionen -------------------------
double AccountBalanceStart()
{
   static double balance=-1.0;
   if(balance<0.0) balance=AccountInfoDouble(ACCOUNT_BALANCE);
   return balance;
}

double CurrentDrawdown()
{
   return AccountInfoDouble(ACCOUNT_BALANCE) - AccountBalanceStart();
}

double GetSpread()
{
   return (double)(SymbolInfoInteger(Symbol(),SYMBOL_SPREAD));
}

double GetATR()
{
   double atr[];
   ArraySetAsSeries(atr,true);
   if(CopyBuffer(iATR(Symbol(),Period(),ATR_Period),0,0,1,atr)<=0) return 0.0;
   return atr[0];
}

bool IsNewBar()
{
   datetime current = iTime(Symbol(),Period(),0);
   if(current != g_lastBar)
   {
      g_lastBar = current;
      return true;
   }
   return false;
}

void ResetDailyCounters()
{
   int today = CurrentDayOfMonth();
   if(today != g_lastDay)
   {
      g_lastDay = today;
      g_tradesToday = 0;
      if(DebugMode) Print("Daily counters reset");
   }
}

bool IsSessionTime()
{
   if(!UseSessionFilter) return true;
   int hour = CurrentHour();
   return (hour >= TradeStartHour && hour <= TradeEndHour);
}

bool PassesSpreadFilter()
{
   if(!UseSpreadFilter) return true;
   return GetSpread() <= MaxSpreadPoints;
}

bool PassesATRFilter()
{
   if(!UseATRMinFilter) return true;
   return GetATR() >= Min_ATR_Value;
}

bool PassesDailyLossFilter()
{
   double drawdown = CurrentDrawdown();
   double maxLoss = AccountBalanceStart() * (MaxDailyLossPercent / 100.0);
   return drawdown > -maxLoss;
}

int CountOpenPositions()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionGetSymbol(i) == Symbol() && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         count++;
   }
   return count;
}

double CalculatePositionSize()
{
   if(!UseRiskPercent) return FixedLot;
   
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double atr = GetATR();
   if(atr <= 0.0) return FixedLot;
   
   double riskMoney = balance * (g_RiskPct / 100.0);
   double atrValue = atr * g_SL_ATR;
   double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   
   if(tickValue <= 0.0 || tickSize <= 0.0) return FixedLot;
   
   double lotSize = riskMoney / (atrValue * tickValue / tickSize);
   double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   
   lotSize = MathMax(lotSize, minLot);
   lotSize = MathMin(lotSize, maxLot);
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   
   return lotSize;
}

// ---------------------- Signale -----------------------------------
bool GetBuySignal()
{
   double ema_fast[], ema_slow[], rsi[], adx_main[], bb_upper[], bb_lower[];
   
   ArraySetAsSeries(ema_fast, true);
   ArraySetAsSeries(ema_slow, true);
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(adx_main, true);
   ArraySetAsSeries(bb_upper, true);
   ArraySetAsSeries(bb_lower, true);
   
   if(CopyBuffer(iMA(Symbol(),Period(),EMA_Fast,0,MODE_EMA,PRICE_CLOSE),0,0,2,ema_fast) <= 0) return false;
   if(CopyBuffer(iMA(Symbol(),Period(),EMA_Slow,0,MODE_EMA,PRICE_CLOSE),0,0,2,ema_slow) <= 0) return false;
   if(CopyBuffer(iRSI(Symbol(),Period(),RSI_Period,PRICE_CLOSE),0,0,1,rsi) <= 0) return false;
   if(CopyBuffer(iADX(Symbol(),Period(),ADX_Period),0,0,1,adx_main) <= 0) return false;
   if(CopyBuffer(iBands(Symbol(),Period(),BB_Period,0,BB_Dev,PRICE_CLOSE),1,0,1,bb_upper) <= 0) return false;
   if(CopyBuffer(iBands(Symbol(),Period(),BB_Period,0,BB_Dev,PRICE_CLOSE),2,0,1,bb_lower) <= 0) return false;
   
   double price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   
   // EMA crossover (fast above slow)
   bool ema_signal = ema_fast[0] > ema_slow[0] && ema_fast[1] <= ema_slow[1];
   
   // RSI conditions
   bool rsi_signal = rsi[0] > g_RSI_Buy;
   
   // ADX strength
   bool adx_signal = adx_main[0] > ADX_Min;
   
   // Price above BB lower band
   bool bb_signal = price > bb_lower[0];
   
   return ema_signal && rsi_signal && adx_signal && bb_signal;
}

bool GetSellSignal()
{
   double ema_fast[], ema_slow[], rsi[], adx_main[], bb_upper[], bb_lower[];
   
   ArraySetAsSeries(ema_fast, true);
   ArraySetAsSeries(ema_slow, true);
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(adx_main, true);
   ArraySetAsSeries(bb_upper, true);
   ArraySetAsSeries(bb_lower, true);
   
   if(CopyBuffer(iMA(Symbol(),Period(),EMA_Fast,0,MODE_EMA,PRICE_CLOSE),0,0,2,ema_fast) <= 0) return false;
   if(CopyBuffer(iMA(Symbol(),Period(),EMA_Slow,0,MODE_EMA,PRICE_CLOSE),0,0,2,ema_slow) <= 0) return false;
   if(CopyBuffer(iRSI(Symbol(),Period(),RSI_Period,PRICE_CLOSE),0,0,1,rsi) <= 0) return false;
   if(CopyBuffer(iADX(Symbol(),Period(),ADX_Period),0,0,1,adx_main) <= 0) return false;
   if(CopyBuffer(iBands(Symbol(),Period(),BB_Period,0,BB_Dev,PRICE_CLOSE),1,0,1,bb_upper) <= 0) return false;
   if(CopyBuffer(iBands(Symbol(),Period(),BB_Period,0,BB_Dev,PRICE_CLOSE),2,0,1,bb_lower) <= 0) return false;
   
   double price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   
   // EMA crossover (fast below slow)
   bool ema_signal = ema_fast[0] < ema_slow[0] && ema_fast[1] >= ema_slow[1];
   
   // RSI conditions
   bool rsi_signal = rsi[0] < g_RSI_Sell;
   
   // ADX strength
   bool adx_signal = adx_main[0] > ADX_Min;
   
   // Price below BB upper band
   bool bb_signal = price < bb_upper[0];
   
   return ema_signal && rsi_signal && adx_signal && bb_signal;
}

// ---------------------- Trading Functions -------------------------
void OpenBuy()
{
   double price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double atr = GetATR();
   double sl = price - (atr * g_SL_ATR);
   double tp = price + (atr * g_TP_ATR);
   double lotSize = CalculatePositionSize();
   
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = Symbol();
   request.volume = lotSize;
   request.type = ORDER_TYPE_BUY;
   request.price = price;
   request.sl = sl;
   request.tp = tp;
   request.magic = MagicNumber;
   request.comment = "Agressione Buy";
   
   if(OrderSend(request, result))
   {
      g_tradesToday++;
      if(DebugMode) Print("Buy order opened: ", result.deal);
   }
   else
   {
      if(DebugMode) Print("Buy order failed: ", result.retcode);
   }
}

void OpenSell()
{
   double price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double atr = GetATR();
   double sl = price + (atr * g_SL_ATR);
   double tp = price - (atr * g_TP_ATR);
   double lotSize = CalculatePositionSize();
   
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = Symbol();
   request.volume = lotSize;
   request.type = ORDER_TYPE_SELL;
   request.price = price;
   request.sl = sl;
   request.tp = tp;
   request.magic = MagicNumber;
   request.comment = "Agressione Sell";
   
   if(OrderSend(request, result))
   {
      g_tradesToday++;
      if(DebugMode) Print("Sell order opened: ", result.deal);
   }
   else
   {
      if(DebugMode) Print("Sell order failed: ", result.retcode);
   }
}

void ManagePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!PositionGetSymbol(i) || PositionGetSymbol(i) != Symbol() || PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
         
      double profit = PositionGetDouble(POSITION_PROFIT);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 
                           SymbolInfoDouble(Symbol(), SYMBOL_BID) : 
                           SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      
      // Check for forced loss closure
      if(MaxLossPerTrade > -1.0 && profit <= MaxLossPerTrade)
      {
         ClosePosition(i);
         continue;
      }
      
      // Check for minimum profit closure
      if(profit >= MinProfitToClose)
      {
         if(UseATRTrailing)
            UpdateTrailingStop(i);
         if(UseBreakEven)
            UpdateBreakEven(i);
      }
   }
}

void ClosePosition(int index)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = PositionGetSymbol(index);
   request.volume = PositionGetDouble(POSITION_VOLUME);
   request.type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   request.price = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 
                   SymbolInfoDouble(Symbol(), SYMBOL_BID) : 
                   SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   request.magic = MagicNumber;
   
   if(OrderSend(request, result))
   {
      if(DebugMode) Print("Position closed: ", result.deal);
   }
}

void UpdateTrailingStop(int index)
{
   double atr = GetATR();
   double trailDistance = atr * Trail_ATR;
   double currentPrice = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 
                        SymbolInfoDouble(Symbol(), SYMBOL_BID) : 
                        SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double currentSL = PositionGetDouble(POSITION_SL);
   double newSL;
   
   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
   {
      newSL = currentPrice - trailDistance;
      if(newSL > currentSL)
      {
         ModifyPosition(index, newSL, PositionGetDouble(POSITION_TP));
      }
   }
   else
   {
      newSL = currentPrice + trailDistance;
      if(newSL < currentSL || currentSL == 0.0)
      {
         ModifyPosition(index, newSL, PositionGetDouble(POSITION_TP));
      }
   }
}

void UpdateBreakEven(int index)
{
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   double currentPrice = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 
                        SymbolInfoDouble(Symbol(), SYMBOL_BID) : 
                        SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double atr = GetATR();
   double breakEvenDistance = atr * 0.5; // Half ATR for break-even buffer
   
   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
   {
      if(currentPrice > openPrice + breakEvenDistance && (currentSL < openPrice || currentSL == 0.0))
      {
         ModifyPosition(index, openPrice, PositionGetDouble(POSITION_TP));
      }
   }
   else
   {
      if(currentPrice < openPrice - breakEvenDistance && (currentSL > openPrice || currentSL == 0.0))
      {
         ModifyPosition(index, openPrice, PositionGetDouble(POSITION_TP));
      }
   }
}

void ModifyPosition(int index, double sl, double tp)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   
   request.action = TRADE_ACTION_SLTP;
   request.symbol = PositionGetSymbol(index);
   request.sl = sl;
   request.tp = tp;
   request.magic = MagicNumber;
   
   if(OrderSend(request, result))
   {
      if(DebugMode) Print("Position modified: SL=", sl, " TP=", tp);
   }
}

void CheckBasketTP()
{
   if(!UseBasketTP) return;
   
   double totalProfit = 0.0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionGetSymbol(i) == Symbol() && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         totalProfit += PositionGetDouble(POSITION_PROFIT);
      }
   }
   
   if(totalProfit >= BasketTPMoney)
   {
      CloseAllPositions();
      if(DebugMode) Print("Basket TP reached: ", totalProfit);
   }
}

void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == Symbol() && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         ClosePosition(i);
      }
   }
}

// ---------------------- Learning Functions ------------------------
void LearnFromHistory()
{
   if(!LearnFromHistory || Now() < g_nextLearnTime) return;
   
   datetime fromDate = Now() - (HistoryLookbackDays * 24 * 3600);
   HistorySelect(fromDate, Now());
   
   int totalTrades = 0;
   int wins = 0;
   int losses = 0;
   double totalProfit = 0.0;
   
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != MagicNumber) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != Symbol()) continue;
      if(HistoryDealGetInteger(ticket, DEAL_TYPE) != DEAL_TYPE_BUY && 
         HistoryDealGetInteger(ticket, DEAL_TYPE) != DEAL_TYPE_SELL) continue;
      
      totalTrades++;
      double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
      totalProfit += profit;
      
      if(profit > 0) wins++;
      else if(profit < 0) losses++;
   }
   
   if(totalTrades >= LearnMinTrades)
   {
      ApplyLearning(totalTrades, wins, losses, totalProfit);
   }
   
   g_nextLearnTime = Now() + (LearnUpdateHours * 3600);
}

void ApplyLearning(int totalTrades, int wins, int losses, double totalProfit)
{
   double winRate = (double)wins / totalTrades;
   double avgProfit = totalProfit / totalTrades;
   
   // Adjust risk based on performance
   if(winRate > 0.6 && avgProfit > 0)
   {
      g_RiskPct = MathMin(g_RiskPct * 1.1, RiskPercent * LearnRiskScaleMax);
   }
   else if(winRate < 0.4 || avgProfit < 0)
   {
      g_RiskPct = MathMax(g_RiskPct * 0.9, RiskPercent * LearnRiskScaleMin);
   }
   
   // Adjust RSI levels
   if(winRate < 0.45)
   {
      g_RSI_Buy = MathMin(g_RSI_Buy + LearnRSIAdjustStep, 70.0);
      g_RSI_Sell = MathMax(g_RSI_Sell - LearnRSIAdjustStep, 30.0);
   }
   else if(winRate > 0.65)
   {
      g_RSI_Buy = MathMax(g_RSI_Buy - LearnRSIAdjustStep, 50.0);
      g_RSI_Sell = MathMin(g_RSI_Sell + LearnRSIAdjustStep, 50.0);
   }
   
   // Adjust ATR multipliers
   if(avgProfit < 0)
   {
      g_SL_ATR = MathMax(g_SL_ATR - LearnATRScaleStep, SL_ATR * 0.5);
      g_TP_ATR = MathMin(g_TP_ATR + LearnATRScaleStep, TP_ATR * 2.0);
   }
   
   if(DebugMode)
   {
      Print("Learning applied - WinRate: ", winRate, " AvgProfit: ", avgProfit);
      Print("New params - Risk: ", g_RSI_Buy, " RSI: ", g_RSI_Buy, "/", g_RSI_Sell);
   }
}

// ---------------------- Expert Advisor Functions ------------------
int OnInit()
{
   // Initialize runtime parameters with input values
   g_RSI_Buy = RSI_Buy;
   g_RSI_Sell = RSI_Sell;
   g_SL_ATR = SL_ATR;
   g_TP_ATR = TP_ATR;
   g_RiskPct = RiskPercent;
   
   g_nextLearnTime = Now() + (LearnUpdateHours * 3600);
   
   if(DebugMode) Print("Agressione2025 CLEAN EA initialized");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(DebugMode) Print("Agressione2025 CLEAN EA deinitialized, reason: ", reason);
}

void OnTick()
{
   if(!IsNewBar()) return;
   
   ResetDailyCounters();
   LearnFromHistory();
   
   // Check filters
   if(!IsSessionTime() || !PassesSpreadFilter() || !PassesATRFilter() || !PassesDailyLossFilter())
      return;
   
   // Check position limits
   if(CountOpenPositions() >= MaxSimultaneousTrades) return;
   if(g_tradesToday >= MaxTradesPerDay) return;
   if(g_cooldown > 0)
   {
      g_cooldown--;
      return;
   }
   
   // Check for trading signals
   bool buySignal = GetBuySignal();
   bool sellSignal = GetSellSignal();
   
   if(buySignal && !sellSignal)
   {
      OpenBuy();
      g_cooldown = CooldownBars;
   }
   else if(sellSignal && !buySignal)
   {
      OpenSell();
      g_cooldown = CooldownBars;
   }
   
   // Manage existing positions
   ManagePositions();
   CheckBasketTP();
}