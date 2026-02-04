//+------------------------------------------------------------------+
//|                                                    MACD_V_EA.mq5 |
//|                                    MACD-V Strategy Expert Advisor |
//|                          Volatility Normalized MACD Trading System |
//+------------------------------------------------------------------+
#property copyright "MACD-V EA"
#property link      ""
#property version   "2.00"
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

input group "=== Risk Management ==="
input double   InpLotSize            = 0.1;     // Lot Size
input bool     InpUseATRStops        = true;    // Use ATR-Based SL/TP
input double   InpATRMultiplier      = 1.5;     // ATR Multiplier for SL
input double   InpRiskRewardRatio    = 2.0;     // Risk:Reward Ratio (TP = SL x RR)
input double   InpStopLossPips       = 50.0;    // Fixed Stop Loss (Pips) - if ATR disabled
input double   InpTakeProfitPips     = 100.0;   // Fixed Take Profit (Pips) - if ATR disabled
input double   InpMinSLPips          = 10.0;    // Minimum SL (Pips) - ATR floor
input double   InpMaxSLPips          = 100.0;   // Maximum SL (Pips) - ATR ceiling
input bool     InpUseBreakeven       = true;    // Use Breakeven
input double   InpBreakevenTrigger   = 20.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenPlus      = 5.0;     // Breakeven Plus (Pips)
input bool     InpUseTrailingStop    = true;    // Use Trailing Stop
input double   InpTrailingStop       = 30.0;    // Trailing Stop (Pips)
input double   InpTrailingStep       = 10.0;    // Trailing Step (Pips)
input double   InpMaxRiskPercent     = 2.0;     // Max Risk Per Trade (%)
input bool     InpUseDynamicLots     = false;   // Use Dynamic Lot Sizing

input group "=== Trading Filters ==="
input bool     InpUseSpreadFilter    = true;    // Use Spread Filter
input double   InpMaxSpreadPips      = 3.0;     // Max Spread (Pips)
input bool     InpUseTradingHours    = false;   // Use Trading Hours Filter
input int      InpStartHour          = 8;       // Start Hour (Server Time)
input int      InpEndHour            = 20;      // End Hour (Server Time)

input group "=== Additional Filters ==="
input bool     InpUseExtremeFilter   = true;    // Use Extreme Level Filter
input double   InpExtremeOverbought  = 150.0;   // Extreme Overbought Level
input double   InpExtremeOversold    = -150.0;  // Extreme Oversold Level
input bool     InpCloseOnReverse     = true;    // Close Position on Reverse Signal

input group "=== EA Settings ==="
input int      InpMagicNumber        = 123456;  // Magic Number
input string   InpTradeComment       = "MACD-V"; // Trade Comment

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
CTrade         trade;
int            handleFastEMA;
int            handleSlowEMA;
int            handleATR;
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

   if(InpLotSize <= 0)
   {
      Print("Error: Lot size must be greater than 0");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpStopLossPips <= 0 || InpTakeProfitPips <= 0)
   {
      Print("Error: Stop Loss and Take Profit must be greater than 0");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpStartHour < 0 || InpStartHour > 23 || InpEndHour < 0 || InpEndHour > 23)
   {
      Print("Error: Trading hours must be between 0 and 23");
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

   if(InpUseATRStops && InpRiskRewardRatio <= 0)
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

   //--- Initialize arrays to zero
   ArrayInitialize(bufferMACDV, 0);
   ArrayInitialize(bufferSignal, 0);
   ArrayInitialize(bufferHistogram, 0);

   //--- Initialize trade object
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   //--- Initialize bars counter
   g_barsTotal = 0;

   //--- Print initialization info
   Print("===========================================");
   Print("MACD-V Expert Advisor v2.0 Initialized");
   Print("Symbol: ", _Symbol, " | Period: ", EnumToString(Period()));
   Print("Pip Value: ", g_pipValue, " | Pip Point: ", g_pipPoint, " | Digits: ", g_digits);
   Print("Fast EMA: ", InpFastLength, " | Slow EMA: ", InpSlowLength);
   Print("Signal Length: ", InpSignalLength, " | ATR Length: ", InpATRLength);
   if(InpUseATRStops)
   {
      Print("SL/TP Mode: ATR-Based | ATR Multiplier: ", InpATRMultiplier);
      Print("R:R Ratio: 1:", DoubleToString(InpRiskRewardRatio, 1), " | SL Range: ", InpMinSLPips, "-", InpMaxSLPips, " pips");
   }
   else
   {
      Print("SL/TP Mode: Fixed | SL: ", InpStopLossPips, " pips | TP: ", InpTakeProfitPips, " pips");
   }
   Print("Breakeven: ", InpUseBreakeven ? "ON" : "OFF", " | Trailing: ", InpUseTrailingStop ? "ON" : "OFF");
   Print("Spread Filter: ", InpUseSpreadFilter ? "ON (Max: " + DoubleToString(InpMaxSpreadPips, 1) + " pips)" : "OFF");
   Print("Magic Number: ", InpMagicNumber);
   Print("===========================================");

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

   Print("MACD-V EA Deinitialized. Reason: ", GetDeinitReasonText(reason));
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
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
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
      Print("Initial MACD-V values - MACD-V[0]=", DoubleToString(bufferMACDV[0], 2),
            " Signal[0]=", DoubleToString(bufferSignal[0], 2),
            " Hist[0]=", DoubleToString(bufferHistogram[0], 2));
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
      CheckExtremeExit();

   //--- Check for trading signals (only if no open positions)
   if(CountOpenPositions() == 0)
   {
      //--- Check spread filter
      if(InpUseSpreadFilter && !IsSpreadOK())
      {
         static datetime lastSpreadWarning = 0;
         if(TimeCurrent() - lastSpreadWarning > 300) // Warn every 5 minutes max
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
//| OnTrade - Track position changes                                  |
//+------------------------------------------------------------------+
void OnTrade()
{
   static int lastPositionCount = 0;
   int currentCount = CountOpenPositions();

   if(currentCount != lastPositionCount)
   {
      if(currentCount < lastPositionCount)
      {
         Print("Position closed. Remaining positions: ", currentCount);
      }
      lastPositionCount = currentCount;
   }
}

//+------------------------------------------------------------------+
//| Calculate Pip Value                                               |
//+------------------------------------------------------------------+
void CalculatePipValue()
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // For 5-digit forex pairs (EURUSD, GBPUSD, etc.)
   // For 3-digit JPY pairs (USDJPY, EURJPY, etc.)
   if(g_digits == 5 || g_digits == 3)
   {
      g_pipPoint = point * 10;
      g_pipValue = 10.0;
   }
   // For 4-digit pairs or 2-digit pairs
   else if(g_digits == 4 || g_digits == 2)
   {
      g_pipPoint = point;
      g_pipValue = 1.0;
   }
   // For indices, metals, crypto (usually 1 or 2 digits)
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
   int copyCount = 60; // Need extra bars for signal calculation

   //--- Copy indicator data
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

   //--- Calculate MACD-V for all bars
   for(int i = 0; i < copyCount && i < 100; i++)
   {
      double macdLine = bufferFastEMA[i] - bufferSlowEMA[i];

      if(bufferATR[i] > 0)
         bufferMACDV[i] = (macdLine / bufferATR[i]) * 100.0;
      else
         bufferMACDV[i] = 0;
   }

   //--- Calculate Signal Line (EMA of MACD-V)
   //--- We need to calculate from oldest to newest for proper EMA
   double alpha = 2.0 / (InpSignalLength + 1.0);

   //--- First, calculate SMA for the oldest point as seed
   int seedIndex = copyCount - 1;
   if(seedIndex >= 100) seedIndex = 99;

   //--- Calculate initial SMA
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

   //--- Calculate EMA from seed point to newest (index 0)
   for(int i = seedIndex - InpSignalLength; i >= 0; i--)
   {
      bufferSignal[i] = alpha * bufferMACDV[i] + (1.0 - alpha) * bufferSignal[i + 1];
   }

   //--- Calculate Histogram
   for(int i = 0; i < copyCount && i < 100; i++)
   {
      bufferHistogram[i] = bufferMACDV[i] - bufferSignal[i];
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check Buy Signal                                                  |
//+------------------------------------------------------------------+
bool CheckBuySignal()
{
   //--- Histogram crosses above buy signal level
   bool histogramCross = (bufferHistogram[1] <= InpBuySignalLevel && bufferHistogram[0] > InpBuySignalLevel);

   if(!histogramCross)
      return false;

   //--- Trend Filter: MACD-V > 0 or rising
   bool trendFilter = true;
   if(InpUseTrendFilter)
      trendFilter = (bufferMACDV[0] > 0 || (bufferMACDV[0] > bufferMACDV[1]));

   //--- Momentum Filter: Histogram increasing
   bool momentumFilter = true;
   if(InpUseMomentumFilter)
      momentumFilter = (bufferHistogram[0] > bufferHistogram[1]);

   //--- Extreme Filter: Not in overbought zone
   bool notOverbought = (bufferMACDV[0] < InpExtremeOverbought);

   //--- Debug output
   Print("BUY Signal Check - Hist Cross: ", histogramCross,
         " | Trend: ", trendFilter,
         " | Momentum: ", momentumFilter,
         " | Not OB: ", notOverbought);
   Print("  Hist[1]=", DoubleToString(bufferHistogram[1], 2),
         " Hist[0]=", DoubleToString(bufferHistogram[0], 2),
         " MACD-V=", DoubleToString(bufferMACDV[0], 2));

   return (histogramCross && trendFilter && momentumFilter && notOverbought);
}

//+------------------------------------------------------------------+
//| Check Sell Signal                                                 |
//+------------------------------------------------------------------+
bool CheckSellSignal()
{
   //--- Histogram crosses below sell signal level
   bool histogramCross = (bufferHistogram[1] >= InpSellSignalLevel && bufferHistogram[0] < InpSellSignalLevel);

   if(!histogramCross)
      return false;

   //--- Trend Filter: MACD-V < 0 or falling
   bool trendFilter = true;
   if(InpUseTrendFilter)
      trendFilter = (bufferMACDV[0] < 0 || (bufferMACDV[0] < bufferMACDV[1]));

   //--- Momentum Filter: Histogram decreasing
   bool momentumFilter = true;
   if(InpUseMomentumFilter)
      momentumFilter = (bufferHistogram[0] < bufferHistogram[1]);

   //--- Extreme Filter: Not in oversold zone
   bool notOversold = (bufferMACDV[0] > InpExtremeOversold);

   //--- Debug output
   Print("SELL Signal Check - Hist Cross: ", histogramCross,
         " | Trend: ", trendFilter,
         " | Momentum: ", momentumFilter,
         " | Not OS: ", notOversold);
   Print("  Hist[1]=", DoubleToString(bufferHistogram[1], 2),
         " Hist[0]=", DoubleToString(bufferHistogram[0], 2),
         " MACD-V=", DoubleToString(bufferMACDV[0], 2));

   return (histogramCross && trendFilter && momentumFilter && notOversold);
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
      //--- ATR-based SL calculation
      double atrValue = GetCurrentATR();
      slDistance = atrValue * InpATRMultiplier;

      //--- Apply min/max limits
      double minSL = InpMinSLPips * g_pipPoint;
      double maxSL = InpMaxSLPips * g_pipPoint;
      slDistance = MathMax(slDistance, minSL);
      slDistance = MathMin(slDistance, maxSL);

      //--- Calculate TP based on R:R ratio
      tpDistance = slDistance * InpRiskRewardRatio;

      sl = NormalizeDouble(price - slDistance, g_digits);
      tp = NormalizeDouble(price + tpDistance, g_digits);
      slType = "ATR";
   }
   else
   {
      //--- Fixed pip-based SL/TP
      if(InpStopLossPips > 0)
      {
         slDistance = InpStopLossPips * g_pipPoint;
         sl = NormalizeDouble(price - slDistance, g_digits);
      }

      if(InpTakeProfitPips > 0)
      {
         tpDistance = InpTakeProfitPips * g_pipPoint;
         tp = NormalizeDouble(price + tpDistance, g_digits);
      }
   }

   //--- Calculate lot size
   double lots = InpLotSize;
   if(InpUseDynamicLots && sl > 0)
      lots = CalculateLotSize(slDistance);

   //--- Normalize lot size
   lots = NormalizeLotSize(lots);

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

   //--- Calculate actual pips for logging
   double slPips = (price - sl) / g_pipPoint;
   double tpPips = (tp - price) / g_pipPoint;

   //--- Open position
   if(trade.Buy(lots, _Symbol, price, sl, tp, InpTradeComment))
   {
      Print("===========================================");
      Print("=== BUY ORDER OPENED SUCCESSFULLY ===");
      Print("Ticket: ", trade.ResultOrder());
      Print("Lot: ", lots, " | Price: ", price);
      Print("SL Type: ", slType, " | R:R Ratio: 1:", DoubleToString(InpRiskRewardRatio, 1));
      Print("SL: ", sl, " (", DoubleToString(slPips, 1), " pips) | TP: ", tp, " (", DoubleToString(tpPips, 1), " pips)");
      if(InpUseATRStops)
         Print("ATR: ", DoubleToString(GetCurrentATR() / g_pipPoint, 1), " pips | Multiplier: ", InpATRMultiplier);
      Print("MACD-V: ", DoubleToString(bufferMACDV[0], 2),
            " | Signal: ", DoubleToString(bufferSignal[0], 2),
            " | Histogram: ", DoubleToString(bufferHistogram[0], 2));
      Print("===========================================");
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
      //--- ATR-based SL calculation
      double atrValue = GetCurrentATR();
      slDistance = atrValue * InpATRMultiplier;

      //--- Apply min/max limits
      double minSL = InpMinSLPips * g_pipPoint;
      double maxSL = InpMaxSLPips * g_pipPoint;
      slDistance = MathMax(slDistance, minSL);
      slDistance = MathMin(slDistance, maxSL);

      //--- Calculate TP based on R:R ratio
      tpDistance = slDistance * InpRiskRewardRatio;

      sl = NormalizeDouble(price + slDistance, g_digits);
      tp = NormalizeDouble(price - tpDistance, g_digits);
      slType = "ATR";
   }
   else
   {
      //--- Fixed pip-based SL/TP
      if(InpStopLossPips > 0)
      {
         slDistance = InpStopLossPips * g_pipPoint;
         sl = NormalizeDouble(price + slDistance, g_digits);
      }

      if(InpTakeProfitPips > 0)
      {
         tpDistance = InpTakeProfitPips * g_pipPoint;
         tp = NormalizeDouble(price - tpDistance, g_digits);
      }
   }

   //--- Calculate lot size
   double lots = InpLotSize;
   if(InpUseDynamicLots && sl > 0)
      lots = CalculateLotSize(slDistance);

   //--- Normalize lot size
   lots = NormalizeLotSize(lots);

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

   //--- Calculate actual pips for logging
   double slPips = (sl - price) / g_pipPoint;
   double tpPips = (price - tp) / g_pipPoint;

   //--- Open position
   if(trade.Sell(lots, _Symbol, price, sl, tp, InpTradeComment))
   {
      Print("===========================================");
      Print("=== SELL ORDER OPENED SUCCESSFULLY ===");
      Print("Ticket: ", trade.ResultOrder());
      Print("Lot: ", lots, " | Price: ", price);
      Print("SL Type: ", slType, " | R:R Ratio: 1:", DoubleToString(InpRiskRewardRatio, 1));
      Print("SL: ", sl, " (", DoubleToString(slPips, 1), " pips) | TP: ", tp, " (", DoubleToString(tpPips, 1), " pips)");
      if(InpUseATRStops)
         Print("ATR: ", DoubleToString(GetCurrentATR() / g_pipPoint, 1), " pips | Multiplier: ", InpATRMultiplier);
      Print("MACD-V: ", DoubleToString(bufferMACDV[0], 2),
            " | Signal: ", DoubleToString(bufferSignal[0], 2),
            " | Histogram: ", DoubleToString(bufferHistogram[0], 2));
      Print("===========================================");
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

         //--- Check if price has moved enough to trigger breakeven
         if(price >= posOpenPrice + breakevenTrigger)
         {
            //--- Only modify if current SL is below breakeven level
            //--- AND trailing stop hasn't already moved SL above breakeven
            if(posSL < posOpenPrice && (posSL < breakevenLevel || posSL == 0))
            {
               if(trade.PositionModify(ticket, breakevenLevel, posTP))
               {
                  Print("=== BREAKEVEN ACTIVATED FOR BUY ===");
                  Print("Ticket: ", ticket, " | New SL: ", breakevenLevel,
                        " (BE + ", InpBreakevenPlus, " pips)");
               }
               else
               {
                  Print("Failed to set breakeven. Error: ", GetLastError());
               }
            }
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double breakevenLevel = NormalizeDouble(posOpenPrice - breakevenPlus, g_digits);

         //--- Check if price has moved enough to trigger breakeven
         if(price <= posOpenPrice - breakevenTrigger)
         {
            //--- Only modify if current SL is above breakeven level (or not set)
            //--- AND trailing stop hasn't already moved SL below breakeven
            if((posSL > posOpenPrice || posSL == 0) && (posSL > breakevenLevel || posSL == 0))
            {
               if(trade.PositionModify(ticket, breakevenLevel, posTP))
               {
                  Print("=== BREAKEVEN ACTIVATED FOR SELL ===");
                  Print("Ticket: ", ticket, " | New SL: ", breakevenLevel,
                        " (BE - ", InpBreakevenPlus, " pips)");
               }
               else
               {
                  Print("Failed to set breakeven. Error: ", GetLastError());
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

         //--- Only trail if price has moved enough from entry
         if(price > posOpenPrice + trailingStop)
         {
            //--- Only update if new SL is better by at least trailing step
            if(newSL > posSL + trailingStep || posSL == 0)
            {
               //--- Make sure new SL is above entry (we're in profit)
               if(newSL > posOpenPrice)
               {
                  if(trade.PositionModify(ticket, newSL, posTP))
                  {
                     Print("Trailing stop updated for BUY #", ticket, ": New SL=", newSL);
                  }
               }
            }
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double newSL = NormalizeDouble(price + trailingStop, g_digits);

         //--- Only trail if price has moved enough from entry
         if(price < posOpenPrice - trailingStop)
         {
            //--- Only update if new SL is better by at least trailing step
            if(newSL < posSL - trailingStep || posSL == 0)
            {
               //--- Make sure new SL is below entry (we're in profit)
               if(newSL < posOpenPrice)
               {
                  if(trade.PositionModify(ticket, newSL, posTP))
                  {
                     Print("Trailing stop updated for SELL #", ticket, ": New SL=", newSL);
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check Extreme Level Exit and Reverse Close                        |
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

      //--- Close BUY if extreme overbought
      if(InpUseExtremeFilter && posType == POSITION_TYPE_BUY && bufferMACDV[0] >= InpExtremeOverbought)
      {
         if(trade.PositionClose(ticket))
         {
            Print("=== BUY CLOSED AT EXTREME OVERBOUGHT ===");
            Print("MACD-V: ", DoubleToString(bufferMACDV[0], 2), " | Profit: ", posProfit);
         }
      }
      //--- Close SELL if extreme oversold
      else if(InpUseExtremeFilter && posType == POSITION_TYPE_SELL && bufferMACDV[0] <= InpExtremeOversold)
      {
         if(trade.PositionClose(ticket))
         {
            Print("=== SELL CLOSED AT EXTREME OVERSOLD ===");
            Print("MACD-V: ", DoubleToString(bufferMACDV[0], 2), " | Profit: ", posProfit);
         }
      }
      //--- Close BUY if histogram reverses (crosses below buy level)
      else if(InpCloseOnReverse && posType == POSITION_TYPE_BUY &&
              bufferHistogram[0] < InpBuySignalLevel && bufferHistogram[1] >= InpBuySignalLevel)
      {
         if(trade.PositionClose(ticket))
         {
            Print("=== BUY CLOSED ON HISTOGRAM REVERSAL ===");
            Print("Hist[1]=", DoubleToString(bufferHistogram[1], 2),
                  " -> Hist[0]=", DoubleToString(bufferHistogram[0], 2));
         }
      }
      //--- Close SELL if histogram reverses (crosses above sell level)
      else if(InpCloseOnReverse && posType == POSITION_TYPE_SELL &&
              bufferHistogram[0] > InpSellSignalLevel && bufferHistogram[1] <= InpSellSignalLevel)
      {
         if(trade.PositionClose(ticket))
         {
            Print("=== SELL CLOSED ON HISTOGRAM REVERSAL ===");
            Print("Hist[1]=", DoubleToString(bufferHistogram[1], 2),
                  " -> Hist[0]=", DoubleToString(bufferHistogram[0], 2));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate Lot Size Based on Risk                                  |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopLossDistance)
{
   if(stopLossDistance <= 0)
      return InpLotSize;

   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * InpMaxRiskPercent / 100.0;

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tickSize == 0 || tickValue == 0)
   {
      Print("Warning: Unable to calculate dynamic lot size. Using default.");
      return InpLotSize;
   }

   //--- Calculate lots based on risk
   double lots = riskAmount / (stopLossDistance / tickSize * tickValue);

   //--- Fallback to default if calculation is invalid
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

   //--- Round to lot step
   lots = MathFloor(lots / lotStep) * lotStep;

   //--- Ensure within limits
   lots = MathMax(lots, minLot);
   lots = MathMin(lots, maxLot);

   //--- Final normalization
   lots = NormalizeDouble(lots, 2);

   return lots;
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

   //--- Normal hours (e.g., 8:00 - 20:00)
   if(InpStartHour < InpEndHour)
   {
      return (currentHour >= InpStartHour && currentHour < InpEndHour);
   }
   //--- Overnight hours (e.g., 20:00 - 08:00)
   else if(InpStartHour > InpEndHour)
   {
      return (currentHour >= InpStartHour || currentHour < InpEndHour);
   }
   //--- Same hour (always trade)
   else
   {
      return true;
   }
}
//+------------------------------------------------------------------+
