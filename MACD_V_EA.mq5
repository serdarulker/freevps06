//+------------------------------------------------------------------+
//|                                                    MACD_V_EA.mq5 |
//|                                    MACD-V Strategy Expert Advisor |
//|                   Volatility Normalized MACD - PROP FIRM Edition |
//+------------------------------------------------------------------+
#property copyright "MACD-V EA - PROP Edition"
#property link      ""
#property version   "3.00"
#property strict

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input group "=== MACD-V Settings ==="
input int      InpFastLength     = 12;          // Fast EMA Length
input int      InpSlowLength     = 26;          // Slow EMA Length
input int      InpSignalLength   = 9;           // Signal Line Length
input int      InpATRLength      = 26;          // ATR Length

input group "=== Strategy Settings ==="
input double   InpBuySignalLevel    = 0.0;      // Buy Signal Level (Histogram)
input double   InpSellSignalLevel   = 0.0;      // Sell Signal Level (Histogram)
input double   InpOverboughtLevel   = 100.0;    // Overbought Level
input double   InpOversoldLevel     = -100.0;   // Oversold Level
input bool     InpUseTrendFilter    = true;     // Use Trend Filter
input bool     InpUseMomentumFilter = true;     // Use Momentum Filter

input group "=== STABILITY FILTERS ==="
input bool     InpUseVolatilityFilter = true;      // Use Volatility Filter
input double   InpMinATRMultiplier    = 1.0;       // Min ATR Multiplier (1.0 = avg volatility)
input bool     InpUseHigherTFFilter   = true;      // Use Higher Timeframe Trend Filter
input ENUM_TIMEFRAMES InpHigherTimeframe = PERIOD_H4;  // Higher Timeframe
input int      InpMaxDailyTrades      = 5;         // Max Trades Per Day
input double   InpMinMomentumStrength = 5.0;       // Min Momentum Strength for Entry
input bool     InpUseSmartExit        = true;      // Use Smart Exit (momentum reversal)

input group "=== PROP FIRM RISK MANAGEMENT ==="
input double   InpDailyLossPercent       = 3.0;    // Daily Loss Limit (%) - PROP RULE
input double   InpDailyTargetPercent     = 4.0;    // Daily Profit Target (%) - PROP RULE
input double   InpMaxTotalLossPercent    = 6.0;    // Max Total Drawdown (%) - PROP RULE
input bool     InpStopTradingOnDailyLimit  = true; // Stop Trading When Daily Limit Hit
input bool     InpStopTradingOnDailyTarget = false;// Stop Trading When Daily Target Hit

input group "=== DYNAMIC RISK PER TRADE ==="
input double   InpRiskPerTradePercent    = 0.5;    // Risk Per Trade (% of Balance)
input double   InpMaxRiskPerTradePercent = 1.0;    // Max Risk Per Trade (%)
input double   InpMinRiskPerTradePercent = 0.3;    // Min Risk Per Trade (%)
input bool     InpReduceRiskAfterLoss    = true;   // Reduce Risk After Consecutive Losses
input int      InpConsecutiveLossesBeforeReduce = 1; // Consecutive Losses Before Risk Reduction

input group "=== STOP LOSS & TAKE PROFIT ==="
input bool     InpUseATRStops        = true;       // Use ATR-Based SL/TP
input double   InpATRMultiplier      = 1.5;        // ATR Multiplier for SL
input double   InpRiskRewardRatio    = 2.5;        // Risk:Reward Ratio (TP = SL x RR)
input double   InpStopLossPips       = 40.0;       // Fixed Stop Loss (Pips) - if ATR disabled
input double   InpTakeProfitPips     = 100.0;      // Fixed Take Profit (Pips) - if ATR disabled
input double   InpMinSLPips          = 10.0;       // Minimum SL (Pips) - ATR floor
input double   InpMaxSLPips          = 100.0;      // Maximum SL (Pips) - ATR ceiling

input group "=== POSITION MANAGEMENT ==="
input bool     InpUseBreakeven       = true;       // Use Breakeven
input double   InpBreakevenTrigger   = 20.0;       // Breakeven Trigger (Pips)
input double   InpBreakevenPlus      = 5.0;        // Breakeven Plus (Pips)
input bool     InpUseTrailingStop    = true;       // Use Trailing Stop
input double   InpTrailingStop       = 30.0;       // Trailing Stop (Pips)
input double   InpTrailingStep       = 10.0;       // Trailing Step (Pips)

input group "=== POSITION SIZING ==="
input double   InpLotSize            = 0.1;        // Default Lot Size
input double   InpMaxLotSize         = 10.0;       // Maximum Lot Size
input double   InpMinLotSize         = 0.01;       // Minimum Lot Size
input bool     InpUseFixedLots       = false;      // Use Fixed Lots (ignore risk calc)
input bool     InpUseDynamicLots     = true;       // Use Dynamic Lot Sizing

input group "=== Trading Filters ==="
input bool     InpUseSpreadFilter    = true;       // Use Spread Filter
input double   InpMaxSpreadPips      = 3.0;        // Max Spread (Pips)
input bool     InpUseTradingHours    = false;      // Use Trading Hours Filter
input int      InpStartHour          = 8;          // Start Hour (Server Time)
input int      InpEndHour            = 20;         // End Hour (Server Time)

input group "=== Additional Filters ==="
input bool     InpUseExtremeFilter   = true;       // Use Extreme Level Filter
input double   InpExtremeOverbought  = 150.0;      // Extreme Overbought Level
input double   InpExtremeOversold    = -150.0;     // Extreme Oversold Level
input bool     InpCloseOnReverse     = true;       // Close Position on Reverse Signal
input int      InpMaxOpenPositions   = 1;          // Max Simultaneous Positions

input group "=== EA Settings ==="
input int      InpMagicNumber        = 123456;     // Magic Number
input string   InpTradeComment       = "MACD-V";   // Trade Comment

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
CTrade         trade;
int            handleFastEMA;
int            handleSlowEMA;
int            handleATR;
int            htfFastEMAHandle;
int            htfSlowEMAHandle;
double         g_pipValue;
double         g_pipPoint;
int            g_digits;
int            g_barsTotal;

// MACD-V Buffers
double         bufferMACDV[];
double         bufferSignal[];
double         bufferHistogram[];
double         bufferFastEMA[];
double         bufferSlowEMA[];
double         bufferATR[];

// PROP Firm tracking
double         dailyStartBalance;
double         totalStartBalance;
datetime       dailyStartTime;
int            consecutiveLosses;
int            consecutiveWins;
double         currentRiskPercent;
bool           dailyLimitReached;
bool           dailyTargetReached;

// Daily trades counter
int            dailyTradeCount;
datetime       lastTradeResetDate;

// Last processed deal ticket
ulong          lastProcessedDealTicket;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Input validation
   if(InpFastLength >= InpSlowLength)
   {
      Print("Error: Fast Length (", InpFastLength, ") must be less than Slow Length (", InpSlowLength, ")");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpFastLength < 1 || InpSlowLength < 1 || InpSignalLength < 1 || InpATRLength < 1)
   {
      Print("Error: All length parameters must be greater than 0");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpUseBreakeven && InpBreakevenTrigger <= 0)
   {
      Print("Error: Breakeven trigger pips must be greater than 0 when breakeven is enabled");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpUseTrailingStop && InpTrailingStop <= 0)
   {
      Print("Error: Trailing stop pips must be greater than 0 when trailing is enabled");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpUseATRStops && InpATRMultiplier <= 0)
   {
      Print("Error: ATR Multiplier must be greater than 0 when ATR stops are enabled");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpRiskRewardRatio <= 0)
   {
      Print("Error: Risk:Reward ratio must be greater than 0");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpMinSLPips <= 0 || InpMaxSLPips <= 0 || InpMinSLPips >= InpMaxSLPips)
   {
      Print("Error: Min SL must be > 0 and less than Max SL");
      return(INIT_PARAMETERS_INCORRECT);
   }

   //--- Initialize pip value and digits
   g_digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   CalculatePipValue();

   //--- Create indicator handles
   handleFastEMA = iMA(_Symbol, PERIOD_CURRENT, InpFastLength, 0, MODE_EMA, PRICE_CLOSE);
   handleSlowEMA = iMA(_Symbol, PERIOD_CURRENT, InpSlowLength, 0, MODE_EMA, PRICE_CLOSE);
   handleATR     = iATR(_Symbol, PERIOD_CURRENT, InpATRLength);

   if(handleFastEMA == INVALID_HANDLE || handleSlowEMA == INVALID_HANDLE || handleATR == INVALID_HANDLE)
   {
      Print("Error creating indicator handles. Error: ", GetLastError());
      return(INIT_FAILED);
   }

   //--- Create higher timeframe handles
   if(InpUseHigherTFFilter)
   {
      htfFastEMAHandle = iMA(_Symbol, InpHigherTimeframe, InpFastLength, 0, MODE_EMA, PRICE_CLOSE);
      htfSlowEMAHandle = iMA(_Symbol, InpHigherTimeframe, InpSlowLength, 0, MODE_EMA, PRICE_CLOSE);

      if(htfFastEMAHandle == INVALID_HANDLE || htfSlowEMAHandle == INVALID_HANDLE)
      {
         Print("Error creating higher timeframe indicator handles");
         return(INIT_FAILED);
      }
   }

   //--- Resize and initialize arrays
   ArrayResize(bufferMACDV, 100);
   ArrayResize(bufferSignal, 100);
   ArrayResize(bufferHistogram, 100);

   ArraySetAsSeries(bufferMACDV, true);
   ArraySetAsSeries(bufferSignal, true);
   ArraySetAsSeries(bufferHistogram, true);
   ArraySetAsSeries(bufferFastEMA, true);
   ArraySetAsSeries(bufferSlowEMA, true);
   ArraySetAsSeries(bufferATR, true);

   ArrayInitialize(bufferMACDV, 0);
   ArrayInitialize(bufferSignal, 0);
   ArrayInitialize(bufferHistogram, 0);

   //--- Initialize trade object
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   //--- Initialize PROP tracking
   dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   totalStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   dailyStartTime = TimeCurrent();
   consecutiveLosses = 0;
   consecutiveWins = 0;
   currentRiskPercent = InpRiskPerTradePercent;
   dailyLimitReached = false;
   dailyTargetReached = false;
   dailyTradeCount = 0;
   lastTradeResetDate = 0;
   lastProcessedDealTicket = 0;

   //--- Initialize bars counter
   g_barsTotal = iBars(_Symbol, PERIOD_CURRENT);

   //--- Print initialization info
   Print("============================================================");
   Print("     MACD-V PROP STRATEGY EA v3.00 Initialized");
   Print("============================================================");
   Print("Symbol: ", _Symbol, " | Period: ", EnumToString(Period()));
   Print("Pip Value: ", g_pipValue, " | Pip Point: ", g_pipPoint, " | Digits: ", g_digits);
   Print("Fast EMA: ", InpFastLength, " | Slow EMA: ", InpSlowLength);
   Print("Signal Length: ", InpSignalLength, " | ATR Length: ", InpATRLength);
   Print("Higher TF: ", EnumToString(InpHigherTimeframe), " | Max Daily Trades: ", InpMaxDailyTrades);
   Print("------------------------------------------------------------");
   Print("Starting Balance: $", DoubleToString(totalStartBalance, 2));
   Print("Daily Loss Limit: ", InpDailyLossPercent, "% ($", DoubleToString(dailyStartBalance * InpDailyLossPercent / 100, 2), ")");
   Print("Daily Profit Target: ", InpDailyTargetPercent, "% ($", DoubleToString(dailyStartBalance * InpDailyTargetPercent / 100, 2), ")");
   Print("Max Total Drawdown: ", InpMaxTotalLossPercent, "%");
   Print("------------------------------------------------------------");
   if(InpUseATRStops)
   {
      Print("SL/TP Mode: ATR-Based | ATR Multiplier: ", InpATRMultiplier);
      Print("R:R Ratio: 1:", DoubleToString(InpRiskRewardRatio, 1), " | SL Range: ", InpMinSLPips, "-", InpMaxSLPips, " pips");
   }
   else
   {
      Print("SL/TP Mode: Fixed | SL: ", InpStopLossPips, " pips | R:R: ", InpRiskRewardRatio);
   }
   Print("Risk Per Trade: ", currentRiskPercent, "%");
   Print("------------------------------------------------------------");
   Print("Volatility Filter: ", InpUseVolatilityFilter ? "ON" : "OFF");
   Print("Higher TF Filter: ", InpUseHigherTFFilter ? "ON" : "OFF");
   Print("Smart Exit: ", InpUseSmartExit ? "ON" : "OFF");
   Print("Breakeven: ", InpUseBreakeven ? "ON" : "OFF", " | Trailing: ", InpUseTrailingStop ? "ON" : "OFF");
   Print("Magic Number: ", InpMagicNumber);
   Print("============================================================");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Release indicator handles
   if(handleFastEMA != INVALID_HANDLE) IndicatorRelease(handleFastEMA);
   if(handleSlowEMA != INVALID_HANDLE) IndicatorRelease(handleSlowEMA);
   if(handleATR != INVALID_HANDLE) IndicatorRelease(handleATR);
   if(htfFastEMAHandle != INVALID_HANDLE) IndicatorRelease(htfFastEMAHandle);
   if(htfSlowEMAHandle != INVALID_HANDLE) IndicatorRelease(htfSlowEMAHandle);

   double finalBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double totalProfit = finalBalance - totalStartBalance;
   double totalProfitPercent = (totalProfit / totalStartBalance) * 100;

   Print("============================================================");
   Print("     MACD-V PROP STRATEGY EA STOPPED");
   Print("============================================================");
   Print("Starting Balance: $", DoubleToString(totalStartBalance, 2));
   Print("Final Balance: $", DoubleToString(finalBalance, 2));
   Print("Total P/L: $", DoubleToString(totalProfit, 2), " (", DoubleToString(totalProfitPercent, 2), "%)");
   Print("Reason: ", GetDeinitReasonText(reason));
   Print("============================================================");
}

//+------------------------------------------------------------------+
//| Get deinitialization reason text                                  |
//+------------------------------------------------------------------+
string GetDeinitReasonText(int reason)
{
   switch(reason)
   {
      case REASON_PROGRAM:     return "EA terminated";
      case REASON_REMOVE:      return "EA removed from chart";
      case REASON_RECOMPILE:   return "EA recompiled";
      case REASON_CHARTCHANGE: return "Symbol or timeframe changed";
      case REASON_CHARTCLOSE:  return "Chart closed";
      case REASON_PARAMETERS:  return "Input parameters changed";
      case REASON_ACCOUNT:     return "Account changed";
      case REASON_TEMPLATE:    return "Template applied";
      case REASON_INITFAILED:  return "OnInit failed";
      case REASON_CLOSE:       return "Terminal closed";
      default:                 return "Unknown reason " + IntegerToString(reason);
   }
}

//+------------------------------------------------------------------+
//| Trade Transaction Event Handler                                   |
//+------------------------------------------------------------------+
void OnTrade()
{
   if(HistorySelect(0, TimeCurrent()))
   {
      int totalDeals = HistoryDealsTotal();
      if(totalDeals > 0)
      {
         ulong dealTicket = HistoryDealGetTicket(totalDeals - 1);

         if(dealTicket > 0 && dealTicket != lastProcessedDealTicket)
         {
            long dealMagic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
            string dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
            ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);

            if(dealMagic == InpMagicNumber && dealSymbol == _Symbol && dealEntry == DEAL_ENTRY_OUT)
            {
               double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
               double dealSwap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
               double dealCommission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
               double totalProfit = dealProfit + dealSwap + dealCommission;

               UpdateTradeStatistics(totalProfit);
               lastProcessedDealTicket = dealTicket;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Check for new day
   CheckNewDay();

   //--- Check PROP limits
   if(!CheckPROPLimits())
   {
      return;
   }

   //--- Always update trailing stop (every tick for tighter management)
   if(InpUseTrailingStop && CountOpenPositions() > 0)
      UpdateTrailingStop();

   //--- Check for new bar
   int bars = iBars(_Symbol, PERIOD_CURRENT);
   if(bars == g_barsTotal)
      return;
   g_barsTotal = bars;

   //--- Calculate MACD-V
   if(!CalculateMACDV())
   {
      Print("Error: Failed to calculate MACD-V");
      return;
   }

   //--- Debug info on first calculation
   static bool firstRun = true;
   if(firstRun)
   {
      Print("Initial MACD-V values - MACD-V[1]=", DoubleToString(bufferMACDV[1], 2),
            " Signal[1]=", DoubleToString(bufferSignal[1], 2),
            " Hist[1]=", DoubleToString(bufferHistogram[1], 2));
      firstRun = false;
   }

   //--- Check trading hours
   if(InpUseTradingHours && !IsTradingTime())
   {
      return;
   }

   //--- Update breakeven on new bar
   if(InpUseBreakeven && CountOpenPositions() > 0)
      UpdateBreakeven();

   //--- Check extreme level exit and reverse close
   if(CountOpenPositions() > 0)
   {
      if(InpUseExtremeFilter)
         CheckExtremeExit();

      if(InpUseSmartExit)
         SmartExitStrategy();
   }

   //--- Check for trading signals (only if positions < max)
   if(CountOpenPositions() < InpMaxOpenPositions)
   {
      //--- Check spread filter
      if(InpUseSpreadFilter && !IsSpreadOK())
      {
         static datetime lastSpreadWarning = 0;
         if(TimeCurrent() - lastSpreadWarning > 300)
         {
            Print("Spread too high: ", DoubleToString(GetCurrentSpreadPips(), 1), " pips (Max: ", InpMaxSpreadPips, ")");
            lastSpreadWarning = TimeCurrent();
         }
         return;
      }

      //--- Check signals and open positions
      if(CheckBuySignal())
      {
         Print(">>> BUY Signal detected! <<<");
         OpenBuyPosition();
      }
      else if(CheckSellSignal())
      {
         Print(">>> SELL Signal detected! <<<");
         OpenSellPosition();
      }
   }
}

//+------------------------------------------------------------------+
//| Check for new trading day                                         |
//+------------------------------------------------------------------+
void CheckNewDay()
{
   MqlDateTime currentTime, startTime;
   TimeCurrent(currentTime);
   TimeToStruct(dailyStartTime, startTime);

   if(currentTime.day != startTime.day || currentTime.mon != startTime.mon || currentTime.year != startTime.year)
   {
      double yesterdayBalance = dailyStartBalance;
      double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      double dailyProfit = currentBalance - yesterdayBalance;
      double dailyProfitPercent = (dailyProfit / yesterdayBalance) * 100;

      Print("============================================================");
      Print("                    NEW TRADING DAY");
      Print("============================================================");
      Print("Previous Day P/L: $", DoubleToString(dailyProfit, 2), " (", DoubleToString(dailyProfitPercent, 2), "%)");
      Print("Previous Day Trades: ", dailyTradeCount);
      Print("New Day Starting Balance: $", DoubleToString(currentBalance, 2));

      //--- Reset daily tracking
      dailyStartBalance = currentBalance;
      dailyStartTime = TimeCurrent();
      dailyLimitReached = false;
      dailyTargetReached = false;
      consecutiveLosses = 0;
      consecutiveWins = 0;
      currentRiskPercent = InpRiskPerTradePercent;
      dailyTradeCount = 0;

      Print("Daily Loss Limit: ", InpDailyLossPercent, "% ($", DoubleToString(dailyStartBalance * InpDailyLossPercent / 100, 2), ")");
      Print("Daily Profit Target: ", InpDailyTargetPercent, "% ($", DoubleToString(dailyStartBalance * InpDailyTargetPercent / 100, 2), ")");
      Print("============================================================");
   }
}

//+------------------------------------------------------------------+
//| Check PROP firm limits                                            |
//+------------------------------------------------------------------+
bool CheckPROPLimits()
{
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);

   double dailyProfit = currentBalance - dailyStartBalance;
   double dailyProfitPercent = (dailyProfit / dailyStartBalance) * 100;

   double totalDrawdown = totalStartBalance - currentEquity;
   double totalDrawdownPercent = (totalDrawdown / totalStartBalance) * 100;

   //--- Check daily loss limit
   if(dailyProfitPercent <= -InpDailyLossPercent)
   {
      if(!dailyLimitReached)
      {
         Print("============================================================");
         Print("           !!! DAILY LOSS LIMIT REACHED !!!");
         Print("============================================================");
         Print("Daily Loss: $", DoubleToString(dailyProfit, 2), " (", DoubleToString(dailyProfitPercent, 2), "%)");
         Print("Limit: ", InpDailyLossPercent, "%");

         CloseAllPositions("Daily loss limit reached");
         dailyLimitReached = true;
      }

      if(InpStopTradingOnDailyLimit)
         return false;
   }

   //--- Check daily profit target
   if(dailyProfitPercent >= InpDailyTargetPercent)
   {
      if(!dailyTargetReached)
      {
         Print("============================================================");
         Print("           +++ DAILY PROFIT TARGET REACHED +++");
         Print("============================================================");
         Print("Daily Profit: $", DoubleToString(dailyProfit, 2), " (", DoubleToString(dailyProfitPercent, 2), "%)");
         Print("Target: ", InpDailyTargetPercent, "%");

         dailyTargetReached = true;
      }

      if(InpStopTradingOnDailyTarget)
      {
         CloseAllPositions("Daily target reached");
         return false;
      }
   }

   //--- Check max total drawdown
   if(totalDrawdownPercent >= InpMaxTotalLossPercent)
   {
      Print("============================================================");
      Print("          !!! MAX TOTAL DRAWDOWN REACHED !!!");
      Print("============================================================");
      Print("Total Drawdown: $", DoubleToString(totalDrawdown, 2), " (", DoubleToString(totalDrawdownPercent, 2), "%)");
      Print("Max Allowed: ", InpMaxTotalLossPercent, "%");

      CloseAllPositions("Max total drawdown reached");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check max daily trades limit                                      |
//+------------------------------------------------------------------+
bool CheckMaxDailyTrades()
{
   MqlDateTime tm;
   TimeCurrent(tm);
   datetime today = StringToTime(IntegerToString(tm.year) + "." +
                                 IntegerToString(tm.mon) + "." +
                                 IntegerToString(tm.day));

   if(today != lastTradeResetDate)
   {
      dailyTradeCount = 0;
      lastTradeResetDate = today;
   }

   if(dailyTradeCount >= InpMaxDailyTrades)
   {
      Print("Daily trade limit reached (", dailyTradeCount, "/", InpMaxDailyTrades, ")");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check volatility filter                                           |
//+------------------------------------------------------------------+
bool CheckVolatilityFilter()
{
   if(!InpUseVolatilityFilter)
      return true;

   double atr[];
   ArraySetAsSeries(atr, true);

   if(CopyBuffer(handleATR, 0, 0, 20, atr) <= 0)
      return false;

   double avgATR = 0;
   for(int i = 0; i < 20; i++)
      avgATR += atr[i];
   avgATR /= 20.0;

   if(atr[0] < avgATR * InpMinATRMultiplier)
   {
      Print("Low volatility - trade skipped (ATR: ", DoubleToString(atr[0], 5),
            " / Avg: ", DoubleToString(avgATR, 5), ")");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check higher timeframe trend                                      |
//+------------------------------------------------------------------+
bool CheckHigherTimeframeTrend(bool isBuySignal)
{
   if(!InpUseHigherTFFilter)
      return true;

   double htfFastEMA[], htfSlowEMA[];
   ArraySetAsSeries(htfFastEMA, true);
   ArraySetAsSeries(htfSlowEMA, true);

   if(CopyBuffer(htfFastEMAHandle, 0, 0, 3, htfFastEMA) <= 0)
      return true;
   if(CopyBuffer(htfSlowEMAHandle, 0, 0, 3, htfSlowEMA) <= 0)
      return true;

   double htfMACD = htfFastEMA[0] - htfSlowEMA[0];

   if(isBuySignal)
   {
      if(htfMACD < -0.0001)
      {
         Print("Higher timeframe is bearish - BUY skipped");
         return false;
      }
   }
   else
   {
      if(htfMACD > 0.0001)
      {
         Print("Higher timeframe is bullish - SELL skipped");
         return false;
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| Calculate dynamic risk based on performance                       |
//+------------------------------------------------------------------+
double CalculateDynamicRisk()
{
   if(!InpReduceRiskAfterLoss)
      return InpRiskPerTradePercent;

   if(consecutiveLosses >= InpConsecutiveLossesBeforeReduce)
   {
      double reduction = (consecutiveLosses - InpConsecutiveLossesBeforeReduce + 1) * 0.15;
      currentRiskPercent = InpRiskPerTradePercent - reduction;
      currentRiskPercent = MathMax(currentRiskPercent, InpMinRiskPerTradePercent);
   }
   else if(consecutiveWins >= 4)
   {
      double increase = (consecutiveWins - 3) * 0.1;
      currentRiskPercent = InpRiskPerTradePercent + increase;
      currentRiskPercent = MathMin(currentRiskPercent, InpMaxRiskPerTradePercent);
   }
   else
   {
      currentRiskPercent = InpRiskPerTradePercent;
   }

   return currentRiskPercent;
}

//+------------------------------------------------------------------+
//| Update trade statistics                                           |
//+------------------------------------------------------------------+
void UpdateTradeStatistics(double profit)
{
   if(profit > 0)
   {
      consecutiveWins++;
      consecutiveLosses = 0;
      Print("Win! Consecutive wins: ", consecutiveWins);
   }
   else if(profit < 0)
   {
      consecutiveLosses++;
      consecutiveWins = 0;
      Print("Loss! Consecutive losses: ", consecutiveLosses);

      if(consecutiveLosses >= InpConsecutiveLossesBeforeReduce)
      {
         Print("Risk reduced to ", DoubleToString(CalculateDynamicRisk(), 2), "% due to consecutive losses");
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate Pip Value                                               |
//+------------------------------------------------------------------+
void CalculatePipValue()
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   if(g_digits == 5 || g_digits == 3)
   {
      g_pipPoint = point * 10;
      g_pipValue = 10.0;
   }
   else if(g_digits == 4 || g_digits == 2)
   {
      g_pipPoint = point;
      g_pipValue = 1.0;
   }
   else
   {
      g_pipPoint = point;
      g_pipValue = 1.0;
   }
}

//+------------------------------------------------------------------+
//| Calculate MACD-V Values                                           |
//+------------------------------------------------------------------+
bool CalculateMACDV()
{
   int copyCount = 60;

   if(CopyBuffer(handleFastEMA, 0, 0, copyCount, bufferFastEMA) < copyCount)
   {
      Print("Error copying Fast EMA data. Error: ", GetLastError());
      return false;
   }
   if(CopyBuffer(handleSlowEMA, 0, 0, copyCount, bufferSlowEMA) < copyCount)
   {
      Print("Error copying Slow EMA data. Error: ", GetLastError());
      return false;
   }
   if(CopyBuffer(handleATR, 0, 0, copyCount, bufferATR) < copyCount)
   {
      Print("Error copying ATR data. Error: ", GetLastError());
      return false;
   }

   for(int i = 0; i < copyCount && i < 100; i++)
   {
      double macdLine = bufferFastEMA[i] - bufferSlowEMA[i];

      if(bufferATR[i] > 0)
         bufferMACDV[i] = (macdLine / bufferATR[i]) * 100.0;
      else
         bufferMACDV[i] = 0;
   }

   double alpha = 2.0 / (InpSignalLength + 1.0);

   int seedIndex = copyCount - 1;
   if(seedIndex >= 100) seedIndex = 99;

   double sum = 0;
   int smaCount = 0;
   for(int i = seedIndex; i >= seedIndex - InpSignalLength + 1 && i >= 0; i--)
   {
      sum += bufferMACDV[i];
      smaCount++;
   }

   if(smaCount > 0)
      bufferSignal[seedIndex - InpSignalLength + 1] = sum / smaCount;
   else
      bufferSignal[seedIndex - InpSignalLength + 1] = bufferMACDV[seedIndex - InpSignalLength + 1];

   for(int i = seedIndex - InpSignalLength; i >= 0; i--)
   {
      bufferSignal[i] = alpha * bufferMACDV[i] + (1.0 - alpha) * bufferSignal[i + 1];
   }

   for(int i = 0; i < copyCount && i < 100; i++)
   {
      bufferHistogram[i] = bufferMACDV[i] - bufferSignal[i];
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check Buy Signal (Uses Closed Bar)                                |
//+------------------------------------------------------------------+
bool CheckBuySignal()
{
   //--- Basic histogram cross on CLOSED BAR (Index 1 vs 2)
   bool histogramCross = (bufferHistogram[2] <= InpBuySignalLevel && bufferHistogram[1] > InpBuySignalLevel);

   if(!histogramCross)
      return false;

   //--- Check daily trade limit
   if(!CheckMaxDailyTrades())
      return false;

   //--- Check volatility
   if(!CheckVolatilityFilter())
      return false;

   //--- Check higher timeframe trend
   if(!CheckHigherTimeframeTrend(true))
      return false;

   //--- Strong momentum required
   bool strongMomentum = (bufferHistogram[1] - bufferHistogram[2]) > InpMinMomentumStrength;

   //--- MACD-V rising trend
   bool macdvRising = (bufferMACDV[1] > bufferMACDV[2]) && (bufferMACDV[2] > bufferMACDV[3]);

   //--- Exiting oversold zone bonus
   bool exitingOversold = (bufferMACDV[2] < -50 && bufferMACDV[1] > -50);

   //--- Trend Filter
   bool trendFilter = true;
   if(InpUseTrendFilter)
      trendFilter = (bufferMACDV[1] > -20);

   //--- Momentum Filter
   bool momentumFilter = true;
   if(InpUseMomentumFilter)
      momentumFilter = (bufferHistogram[1] > bufferHistogram[2]);

   //--- Not in extreme overbought zone
   bool notOverbought = (bufferMACDV[1] < InpExtremeOverbought);

   //--- Combined signal logic
   bool qualitySignal = (strongMomentum || exitingOversold) && macdvRising;

   if(histogramCross && trendFilter && momentumFilter && notOverbought && qualitySignal)
   {
      Print("BUY Signal Quality Check:");
      Print("  Histogram Cross: YES | Strong Momentum: ", strongMomentum ? "YES" : "NO");
      Print("  MACD-V Rising: ", macdvRising ? "YES" : "NO", " | Exiting Oversold: ", exitingOversold ? "YES" : "NO");
      Print("  MACD-V: ", DoubleToString(bufferMACDV[1], 2), " | Histogram: ", DoubleToString(bufferHistogram[1], 2));
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check Sell Signal (Uses Closed Bar)                               |
//+------------------------------------------------------------------+
bool CheckSellSignal()
{
   //--- Basic histogram cross on CLOSED BAR (Index 1 vs 2)
   bool histogramCross = (bufferHistogram[2] >= InpSellSignalLevel && bufferHistogram[1] < InpSellSignalLevel);

   if(!histogramCross)
      return false;

   //--- Check daily trade limit
   if(!CheckMaxDailyTrades())
      return false;

   //--- Check volatility
   if(!CheckVolatilityFilter())
      return false;

   //--- Check higher timeframe trend
   if(!CheckHigherTimeframeTrend(false))
      return false;

   //--- Strong momentum required
   bool strongMomentum = (bufferHistogram[2] - bufferHistogram[1]) > InpMinMomentumStrength;

   //--- MACD-V falling trend
   bool macdvFalling = (bufferMACDV[1] < bufferMACDV[2]) && (bufferMACDV[2] < bufferMACDV[3]);

   //--- Exiting overbought zone bonus
   bool exitingOverbought = (bufferMACDV[2] > 50 && bufferMACDV[1] < 50);

   //--- Trend Filter
   bool trendFilter = true;
   if(InpUseTrendFilter)
      trendFilter = (bufferMACDV[1] < 20);

   //--- Momentum Filter
   bool momentumFilter = true;
   if(InpUseMomentumFilter)
      momentumFilter = (bufferHistogram[1] < bufferHistogram[2]);

   //--- Not in extreme oversold zone
   bool notOversold = (bufferMACDV[1] > InpExtremeOversold);

   //--- Combined signal logic
   bool qualitySignal = (strongMomentum || exitingOverbought) && macdvFalling;

   if(histogramCross && trendFilter && momentumFilter && notOversold && qualitySignal)
   {
      Print("SELL Signal Quality Check:");
      Print("  Histogram Cross: YES | Strong Momentum: ", strongMomentum ? "YES" : "NO");
      Print("  MACD-V Falling: ", macdvFalling ? "YES" : "NO", " | Exiting Overbought: ", exitingOverbought ? "YES" : "NO");
      Print("  MACD-V: ", DoubleToString(bufferMACDV[1], 2), " | Histogram: ", DoubleToString(bufferHistogram[1], 2));
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Open Buy Position                                                 |
//+------------------------------------------------------------------+
void OpenBuyPosition()
{
   double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = 0, tp = 0;
   double slDistance = 0;
   double tpDistance = 0;
   string slType = "Fixed";

   //--- Calculate SL and TP
   if(InpUseATRStops)
   {
      double atrValue = GetCurrentATR();
      slDistance = atrValue * InpATRMultiplier;

      double minSL = InpMinSLPips * g_pipPoint;
      double maxSL = InpMaxSLPips * g_pipPoint;
      slDistance = MathMax(slDistance, minSL);
      slDistance = MathMin(slDistance, maxSL);

      tpDistance = slDistance * InpRiskRewardRatio;

      sl = NormalizeDouble(price - slDistance, g_digits);
      tp = NormalizeDouble(price + tpDistance, g_digits);
      slType = "ATR";
   }
   else
   {
      if(InpStopLossPips > 0)
      {
         slDistance = InpStopLossPips * g_pipPoint;
         sl = NormalizeDouble(price - slDistance, g_digits);
      }

      tpDistance = slDistance * InpRiskRewardRatio;
      tp = NormalizeDouble(price + tpDistance, g_digits);
   }

   //--- Calculate lot size
   double lots;
   if(InpUseFixedLots)
   {
      lots = InpLotSize;
   }
   else if(InpUseDynamicLots)
   {
      double riskPercent = CalculateDynamicRisk();
      lots = CalculateLotSize(slDistance, riskPercent);
   }
   else
   {
      lots = InpLotSize;
   }

   lots = NormalizeLotSize(lots);

   if(lots < InpMinLotSize || lots > InpMaxLotSize)
   {
      Print("Lot size out of range: ", lots);
      return;
   }

   //--- Validate SL/TP distances
   double minStopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   if(sl > 0 && price - sl < minStopLevel)
   {
      sl = NormalizeDouble(price - minStopLevel - g_pipPoint, g_digits);
      Print("Warning: SL adjusted to meet minimum stop level requirement");
   }

   if(tp > 0 && tp - price < minStopLevel)
   {
      tp = NormalizeDouble(price + minStopLevel + g_pipPoint, g_digits);
      Print("Warning: TP adjusted to meet minimum stop level requirement");
   }

   double slPips = (price - sl) / g_pipPoint;
   double tpPips = (tp - price) / g_pipPoint;

   if(trade.Buy(lots, _Symbol, price, sl, tp, InpTradeComment))
   {
      dailyTradeCount++;

      Print("============================================================");
      Print("              BUY POSITION OPENED");
      Print("============================================================");
      Print("Ticket: ", trade.ResultOrder());
      Print("Lot: ", lots, " | Price: ", price);
      Print("SL Type: ", slType, " | R:R Ratio: 1:", DoubleToString(InpRiskRewardRatio, 1));
      Print("SL: ", sl, " (", DoubleToString(slPips, 1), " pips) | TP: ", tp, " (", DoubleToString(tpPips, 1), " pips)");
      Print("Risk: ", DoubleToString(CalculateDynamicRisk(), 2), "%");
      if(InpUseATRStops)
         Print("ATR: ", DoubleToString(GetCurrentATR() / g_pipPoint, 1), " pips | Multiplier: ", InpATRMultiplier);
      Print("MACD-V: ", DoubleToString(bufferMACDV[1], 2),
            " | Signal: ", DoubleToString(bufferSignal[1], 2),
            " | Histogram: ", DoubleToString(bufferHistogram[1], 2));
      Print("Daily Trades: ", dailyTradeCount, "/", InpMaxDailyTrades);
      Print("============================================================");
   }
   else
   {
      Print("!!! Error opening BUY order !!!");
      Print("Error Code: ", GetLastError());
      Print("RetCode: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
      Print("Price: ", price, " SL: ", sl, " TP: ", tp, " Lots: ", lots);
   }
}

//+------------------------------------------------------------------+
//| Open Sell Position                                                |
//+------------------------------------------------------------------+
void OpenSellPosition()
{
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = 0, tp = 0;
   double slDistance = 0;
   double tpDistance = 0;
   string slType = "Fixed";

   //--- Calculate SL and TP
   if(InpUseATRStops)
   {
      double atrValue = GetCurrentATR();
      slDistance = atrValue * InpATRMultiplier;

      double minSL = InpMinSLPips * g_pipPoint;
      double maxSL = InpMaxSLPips * g_pipPoint;
      slDistance = MathMax(slDistance, minSL);
      slDistance = MathMin(slDistance, maxSL);

      tpDistance = slDistance * InpRiskRewardRatio;

      sl = NormalizeDouble(price + slDistance, g_digits);
      tp = NormalizeDouble(price - tpDistance, g_digits);
      slType = "ATR";
   }
   else
   {
      if(InpStopLossPips > 0)
      {
         slDistance = InpStopLossPips * g_pipPoint;
         sl = NormalizeDouble(price + slDistance, g_digits);
      }

      tpDistance = slDistance * InpRiskRewardRatio;
      tp = NormalizeDouble(price - tpDistance, g_digits);
   }

   //--- Calculate lot size
   double lots;
   if(InpUseFixedLots)
   {
      lots = InpLotSize;
   }
   else if(InpUseDynamicLots)
   {
      double riskPercent = CalculateDynamicRisk();
      lots = CalculateLotSize(slDistance, riskPercent);
   }
   else
   {
      lots = InpLotSize;
   }

   lots = NormalizeLotSize(lots);

   if(lots < InpMinLotSize || lots > InpMaxLotSize)
   {
      Print("Lot size out of range: ", lots);
      return;
   }

   //--- Validate SL/TP distances
   double minStopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   if(sl > 0 && sl - price < minStopLevel)
   {
      sl = NormalizeDouble(price + minStopLevel + g_pipPoint, g_digits);
      Print("Warning: SL adjusted to meet minimum stop level requirement");
   }

   if(tp > 0 && price - tp < minStopLevel)
   {
      tp = NormalizeDouble(price - minStopLevel - g_pipPoint, g_digits);
      Print("Warning: TP adjusted to meet minimum stop level requirement");
   }

   double slPips = (sl - price) / g_pipPoint;
   double tpPips = (price - tp) / g_pipPoint;

   if(trade.Sell(lots, _Symbol, price, sl, tp, InpTradeComment))
   {
      dailyTradeCount++;

      Print("============================================================");
      Print("              SELL POSITION OPENED");
      Print("============================================================");
      Print("Ticket: ", trade.ResultOrder());
      Print("Lot: ", lots, " | Price: ", price);
      Print("SL Type: ", slType, " | R:R Ratio: 1:", DoubleToString(InpRiskRewardRatio, 1));
      Print("SL: ", sl, " (", DoubleToString(slPips, 1), " pips) | TP: ", tp, " (", DoubleToString(tpPips, 1), " pips)");
      Print("Risk: ", DoubleToString(CalculateDynamicRisk(), 2), "%");
      if(InpUseATRStops)
         Print("ATR: ", DoubleToString(GetCurrentATR() / g_pipPoint, 1), " pips | Multiplier: ", InpATRMultiplier);
      Print("MACD-V: ", DoubleToString(bufferMACDV[1], 2),
            " | Signal: ", DoubleToString(bufferSignal[1], 2),
            " | Histogram: ", DoubleToString(bufferHistogram[1], 2));
      Print("Daily Trades: ", dailyTradeCount, "/", InpMaxDailyTrades);
      Print("============================================================");
   }
   else
   {
      Print("!!! Error opening SELL order !!!");
      Print("Error Code: ", GetLastError());
      Print("RetCode: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
      Print("Price: ", price, " SL: ", sl, " TP: ", tp, " Lots: ", lots);
   }
}

//+------------------------------------------------------------------+
//| Smart Exit Strategy                                               |
//+------------------------------------------------------------------+
void SmartExitStrategy()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double posProfit = PositionGetDouble(POSITION_PROFIT);

      if(posProfit > 0)
      {
         if(posType == POSITION_TYPE_BUY)
         {
            if(bufferHistogram[1] < bufferHistogram[2] &&
               bufferHistogram[2] < bufferHistogram[3] &&
               bufferMACDV[1] < bufferMACDV[2])
            {
               if(trade.PositionClose(ticket))
               {
                  Print("BUY smart exit - momentum reversal (Profit: $", DoubleToString(posProfit, 2), ")");
               }
            }
         }
         else if(posType == POSITION_TYPE_SELL)
         {
            if(bufferHistogram[1] > bufferHistogram[2] &&
               bufferHistogram[2] > bufferHistogram[3] &&
               bufferMACDV[1] > bufferMACDV[2])
            {
               if(trade.PositionClose(ticket))
               {
                  Print("SELL smart exit - momentum reversal (Profit: $", DoubleToString(posProfit, 2), ")");
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update Breakeven                                                  |
//+------------------------------------------------------------------+
void UpdateBreakeven()
{
   double breakevenTrigger = InpBreakevenTrigger * g_pipPoint;
   double breakevenPlus = InpBreakevenPlus * g_pipPoint;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double posSL = PositionGetDouble(POSITION_SL);
      double posTP = PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      if(posType == POSITION_TYPE_BUY)
      {
         double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double breakevenLevel = NormalizeDouble(posOpenPrice + breakevenPlus, g_digits);

         if(price >= posOpenPrice + breakevenTrigger)
         {
            if(posSL < posOpenPrice && (posSL < breakevenLevel || posSL == 0))
            {
               if(trade.PositionModify(ticket, breakevenLevel, posTP))
               {
                  Print("=== BREAKEVEN ACTIVATED FOR BUY ===");
                  Print("Ticket: ", ticket, " | New SL: ", breakevenLevel);
               }
            }
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double breakevenLevel = NormalizeDouble(posOpenPrice - breakevenPlus, g_digits);

         if(price <= posOpenPrice - breakevenTrigger)
         {
            if((posSL > posOpenPrice || posSL == 0) && (posSL > breakevenLevel || posSL == 0))
            {
               if(trade.PositionModify(ticket, breakevenLevel, posTP))
               {
                  Print("=== BREAKEVEN ACTIVATED FOR SELL ===");
                  Print("Ticket: ", ticket, " | New SL: ", breakevenLevel);
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update Trailing Stop                                              |
//+------------------------------------------------------------------+
void UpdateTrailingStop()
{
   double trailingStop = InpTrailingStop * g_pipPoint;
   double trailingStep = InpTrailingStep * g_pipPoint;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double posSL = PositionGetDouble(POSITION_SL);
      double posTP = PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      if(posType == POSITION_TYPE_BUY)
      {
         double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double newSL = NormalizeDouble(price - trailingStop, g_digits);

         if(price > posOpenPrice + trailingStop)
         {
            if(newSL > posSL + trailingStep || posSL == 0)
            {
               if(newSL > posOpenPrice)
               {
                  trade.PositionModify(ticket, newSL, posTP);
               }
            }
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double newSL = NormalizeDouble(price + trailingStop, g_digits);

         if(price < posOpenPrice - trailingStop)
         {
            if(newSL < posSL - trailingStep || posSL == 0)
            {
               if(newSL < posOpenPrice)
               {
                  trade.PositionModify(ticket, newSL, posTP);
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check Extreme Level Exit                                          |
//+------------------------------------------------------------------+
void CheckExtremeExit()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double posProfit = PositionGetDouble(POSITION_PROFIT);

      if(posType == POSITION_TYPE_BUY && bufferMACDV[1] >= InpExtremeOverbought)
      {
         if(trade.PositionClose(ticket))
         {
            Print("=== BUY CLOSED AT EXTREME OVERBOUGHT ===");
            Print("MACD-V: ", DoubleToString(bufferMACDV[1], 2), " | Profit: ", posProfit);
         }
      }
      else if(posType == POSITION_TYPE_SELL && bufferMACDV[1] <= InpExtremeOversold)
      {
         if(trade.PositionClose(ticket))
         {
            Print("=== SELL CLOSED AT EXTREME OVERSOLD ===");
            Print("MACD-V: ", DoubleToString(bufferMACDV[1], 2), " | Profit: ", posProfit);
         }
      }
      else if(InpCloseOnReverse && posType == POSITION_TYPE_BUY &&
              bufferHistogram[1] < 0 && bufferHistogram[2] >= 0)
      {
         if(trade.PositionClose(ticket))
         {
            Print("=== BUY CLOSED ON HISTOGRAM REVERSAL ===");
            Print("Hist[2]=", DoubleToString(bufferHistogram[2], 2),
                  " -> Hist[1]=", DoubleToString(bufferHistogram[1], 2));
         }
      }
      else if(InpCloseOnReverse && posType == POSITION_TYPE_SELL &&
              bufferHistogram[1] > 0 && bufferHistogram[2] <= 0)
      {
         if(trade.PositionClose(ticket))
         {
            Print("=== SELL CLOSED ON HISTOGRAM REVERSAL ===");
            Print("Hist[2]=", DoubleToString(bufferHistogram[2], 2),
                  " -> Hist[1]=", DoubleToString(bufferHistogram[1], 2));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Close All Positions                                               |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
{
   Print("Closing all positions. Reason: ", reason);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
      {
         trade.PositionClose(ticket);
      }
   }
}

//+------------------------------------------------------------------+
//| Get Current ATR Value                                             |
//+------------------------------------------------------------------+
double GetCurrentATR()
{
   double atr[];
   ArraySetAsSeries(atr, true);

   if(CopyBuffer(handleATR, 0, 0, 1, atr) < 1)
   {
      Print("Warning: Failed to get ATR value. Using default.");
      return InpMinSLPips * g_pipPoint;
   }

   return atr[0];
}

//+------------------------------------------------------------------+
//| Calculate Lot Size Based on Risk                                  |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopLossDistance, double riskPercent)
{
   if(stopLossDistance <= 0)
      return InpMinLotSize;

   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * riskPercent / 100.0;

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tickSize == 0 || tickValue == 0)
   {
      Print("Warning: Unable to calculate dynamic lot size. Using default.");
      return InpLotSize;
   }

   double lots = riskAmount / (stopLossDistance / tickSize * tickValue);

   if(lots <= 0 || !MathIsValidNumber(lots))
   {
      Print("Warning: Invalid lot calculation. Using default lot size.");
      return InpLotSize;
   }

   return lots;
}

//+------------------------------------------------------------------+
//| Normalize Lot Size                                                |
//+------------------------------------------------------------------+
double NormalizeLotSize(double lots)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(lotStep == 0)
      lotStep = 0.01;

   lots = MathMax(lots, minLot);
   lots = MathMin(lots, maxLot);
   lots = MathFloor(lots / lotStep) * lotStep;
   lots = NormalizeDouble(lots, 2);

   return lots;
}

//+------------------------------------------------------------------+
//| Count Open Positions                                              |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         count++;
   }

   return count;
}

//+------------------------------------------------------------------+
//| Get Current Spread in Pips                                        |
//+------------------------------------------------------------------+
double GetCurrentSpreadPips()
{
   double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   return spread / g_pipPoint;
}

//+------------------------------------------------------------------+
//| Check if Spread is OK                                             |
//+------------------------------------------------------------------+
bool IsSpreadOK()
{
   return GetCurrentSpreadPips() <= InpMaxSpreadPips;
}

//+------------------------------------------------------------------+
//| Check if Within Trading Hours                                     |
//+------------------------------------------------------------------+
bool IsTradingTime()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   int currentHour = dt.hour;

   if(InpStartHour < InpEndHour)
   {
      return (currentHour >= InpStartHour && currentHour < InpEndHour);
   }
   else if(InpStartHour > InpEndHour)
   {
      return (currentHour >= InpStartHour || currentHour < InpEndHour);
   }
   else
   {
      return true;
   }
}
//+------------------------------------------------------------------+
