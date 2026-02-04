//+------------------------------------------------------------------+
//|                                                    MACD_V_EA.mq5 |
//|                                    MACD-V Strategy Expert Advisor |
//|                          Volatility Normalized MACD Trading System |
//+------------------------------------------------------------------+
#property copyright "MACD-V EA"
#property link      ""
#property version   "1.00"
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
input double   InpStopLossPips       = 50.0;    // Stop Loss (Pips)
input double   InpTakeProfitPips     = 100.0;   // Take Profit (Pips)
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
double         pipValue;
double         pipPoint;
datetime       lastBarTime;

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
      Print("ERROR: Fast Length must be less than Slow Length");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpFastLength <= 0 || InpSlowLength <= 0 || InpSignalLength <= 0 || InpATRLength <= 0)
   {
      Print("ERROR: All length parameters must be greater than 0");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpLotSize <= 0)
   {
      Print("ERROR: Lot size must be greater than 0");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpStopLossPips <= 0 || InpTakeProfitPips <= 0)
   {
      Print("ERROR: Stop Loss and Take Profit must be greater than 0");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(InpStartHour < 0 || InpStartHour > 23 || InpEndHour < 0 || InpEndHour > 23)
   {
      Print("ERROR: Trading hours must be between 0 and 23");
      return(INIT_PARAMETERS_INCORRECT);
   }

   //--- Calculate pip value
   CalculatePipValue();

   //--- Create indicator handles
   handleFastEMA = iMA(_Symbol, PERIOD_CURRENT, InpFastLength, 0, MODE_EMA, PRICE_CLOSE);
   handleSlowEMA = iMA(_Symbol, PERIOD_CURRENT, InpSlowLength, 0, MODE_EMA, PRICE_CLOSE);
   handleATR     = iATR(_Symbol, PERIOD_CURRENT, InpATRLength);

   if(handleFastEMA == INVALID_HANDLE || handleSlowEMA == INVALID_HANDLE || handleATR == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create indicator handles");
      return(INIT_FAILED);
   }

   //--- Set arrays as series
   ArraySetAsSeries(bufferMACDV, true);
   ArraySetAsSeries(bufferSignal, true);
   ArraySetAsSeries(bufferHistogram, true);
   ArraySetAsSeries(bufferFastEMA, true);
   ArraySetAsSeries(bufferSlowEMA, true);
   ArraySetAsSeries(bufferATR, true);

   //--- Initialize trade object
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_IOC);

   //--- Initialize last bar time
   lastBarTime = 0;

   //--- Print initialization info
   Print("===========================================");
   Print("MACD-V Expert Advisor Initialized");
   Print("Symbol: ", _Symbol);
   Print("Timeframe: ", EnumToString(Period()));
   Print("Pip Value: ", pipValue, " | Pip Point: ", pipPoint);
   Print("Fast EMA: ", InpFastLength, " | Slow EMA: ", InpSlowLength);
   Print("Signal Length: ", InpSignalLength, " | ATR Length: ", InpATRLength);
   Print("Stop Loss: ", InpStopLossPips, " pips | Take Profit: ", InpTakeProfitPips, " pips");
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

   Print("MACD-V EA Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Update trailing stop on every tick
   if(InpUseTrailingStop)
      UpdateTrailingStop();

   //--- Check for new bar
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime == lastBarTime)
      return;
   lastBarTime = currentBarTime;

   //--- Calculate MACD-V
   if(!CalculateMACDV())
   {
      Print("ERROR: Failed to calculate MACD-V");
      return;
   }

   //--- Check trading hours
   if(InpUseTradingHours && !IsTradingTime())
   {
      return;
   }

   //--- Update breakeven on new bar
   if(InpUseBreakeven)
      UpdateBreakeven();

   //--- Check extreme level exit
   if(InpUseExtremeFilter)
      CheckExtremeExit();

   //--- Check for close on reverse signal
   if(InpCloseOnReverse)
      CheckReverseClose();

   //--- Check spread filter
   if(InpUseSpreadFilter && !IsSpreadOK())
   {
      return;
   }

   //--- Count current positions
   if(CountOpenPositions() > 0)
      return;

   //--- Check signals and open positions
   if(CheckBuySignal())
   {
      OpenBuyPosition();
   }
   else if(CheckSellSignal())
   {
      OpenSellPosition();
   }
}

//+------------------------------------------------------------------+
//| Calculate Pip Value                                               |
//+------------------------------------------------------------------+
void CalculatePipValue()
{
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // For 5-digit forex pairs (EURUSD, GBPUSD, etc.)
   // For 3-digit JPY pairs (USDJPY, EURJPY, etc.)
   if(digits == 5 || digits == 3)
   {
      pipPoint = point * 10;
      pipValue = 10.0;
   }
   // For 4-digit pairs or 2-digit pairs
   else if(digits == 4 || digits == 2)
   {
      pipPoint = point;
      pipValue = 1.0;
   }
   // For indices, metals, crypto (usually 1 or 2 digits)
   else
   {
      pipPoint = point;
      pipValue = 1.0;
   }
}

//+------------------------------------------------------------------+
//| Calculate MACD-V Values                                           |
//+------------------------------------------------------------------+
bool CalculateMACDV()
{
   int barsNeeded = InpSlowLength + InpSignalLength + 10;

   //--- Copy indicator data
   if(CopyBuffer(handleFastEMA, 0, 0, barsNeeded, bufferFastEMA) < barsNeeded)
      return false;
   if(CopyBuffer(handleSlowEMA, 0, 0, barsNeeded, bufferSlowEMA) < barsNeeded)
      return false;
   if(CopyBuffer(handleATR, 0, 0, barsNeeded, bufferATR) < barsNeeded)
      return false;

   //--- Resize MACD-V buffers
   ArrayResize(bufferMACDV, barsNeeded);
   ArrayResize(bufferSignal, barsNeeded);
   ArrayResize(bufferHistogram, barsNeeded);
   ArraySetAsSeries(bufferMACDV, true);
   ArraySetAsSeries(bufferSignal, true);
   ArraySetAsSeries(bufferHistogram, true);

   //--- Calculate MACD-V (newest to oldest in array, but we calculate oldest to newest)
   for(int i = barsNeeded - 1; i >= 0; i--)
   {
      double macdLine = bufferFastEMA[i] - bufferSlowEMA[i];
      if(bufferATR[i] > 0)
         bufferMACDV[i] = (macdLine / bufferATR[i]) * 100;
      else
         bufferMACDV[i] = 0;
   }

   //--- Calculate Signal Line (EMA of MACD-V)
   //--- First, calculate SMA for seed value (from oldest bars)
   double smaSum = 0;
   int startIdx = barsNeeded - 1;
   for(int i = 0; i < InpSignalLength; i++)
   {
      smaSum += bufferMACDV[startIdx - i];
   }
   double seedValue = smaSum / InpSignalLength;

   //--- Calculate multiplier for EMA
   double multiplier = 2.0 / (InpSignalLength + 1);

   //--- Initialize signal line with seed value
   bufferSignal[startIdx - InpSignalLength + 1] = seedValue;

   //--- Calculate EMA from oldest to newest (right to left in series array)
   for(int i = startIdx - InpSignalLength; i >= 0; i--)
   {
      bufferSignal[i] = (bufferMACDV[i] - bufferSignal[i + 1]) * multiplier + bufferSignal[i + 1];
   }

   //--- Calculate Histogram
   for(int i = 0; i < barsNeeded; i++)
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
   if(bufferHistogram[1] <= InpBuySignalLevel && bufferHistogram[0] > InpBuySignalLevel)
   {
      //--- Trend Filter: MACD-V > 0 or rising
      if(InpUseTrendFilter)
      {
         if(bufferMACDV[0] <= 0 && bufferMACDV[0] <= bufferMACDV[1])
            return false;
      }

      //--- Momentum Filter: Histogram increasing
      if(InpUseMomentumFilter)
      {
         if(bufferHistogram[0] <= bufferHistogram[1])
            return false;
      }

      //--- Extreme Filter: Not in overbought zone
      if(InpUseExtremeFilter)
      {
         if(bufferMACDV[0] >= InpExtremeOverbought)
            return false;
      }

      Print("BUY Signal Detected - Histogram: ", DoubleToString(bufferHistogram[0], 2),
            " | MACD-V: ", DoubleToString(bufferMACDV[0], 2),
            " | Signal: ", DoubleToString(bufferSignal[0], 2));
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check Sell Signal                                                 |
//+------------------------------------------------------------------+
bool CheckSellSignal()
{
   //--- Histogram crosses below sell signal level
   if(bufferHistogram[1] >= InpSellSignalLevel && bufferHistogram[0] < InpSellSignalLevel)
   {
      //--- Trend Filter: MACD-V < 0 or falling
      if(InpUseTrendFilter)
      {
         if(bufferMACDV[0] >= 0 && bufferMACDV[0] >= bufferMACDV[1])
            return false;
      }

      //--- Momentum Filter: Histogram decreasing
      if(InpUseMomentumFilter)
      {
         if(bufferHistogram[0] >= bufferHistogram[1])
            return false;
      }

      //--- Extreme Filter: Not in oversold zone
      if(InpUseExtremeFilter)
      {
         if(bufferMACDV[0] <= InpExtremeOversold)
            return false;
      }

      Print("SELL Signal Detected - Histogram: ", DoubleToString(bufferHistogram[0], 2),
            " | MACD-V: ", DoubleToString(bufferMACDV[0], 2),
            " | Signal: ", DoubleToString(bufferSignal[0], 2));
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Open Buy Position                                                 |
//+------------------------------------------------------------------+
void OpenBuyPosition()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   //--- Calculate SL and TP
   double sl = ask - InpStopLossPips * pipPoint;
   double tp = ask + InpTakeProfitPips * pipPoint;

   //--- Check minimum stop level
   double minStopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   if(minStopLevel > 0)
   {
      if((ask - sl) < minStopLevel)
      {
         sl = ask - minStopLevel - _Point;
         Print("WARNING: SL adjusted to minimum stop level: ", sl);
      }
      if((tp - ask) < minStopLevel)
      {
         tp = ask + minStopLevel + _Point;
         Print("WARNING: TP adjusted to minimum stop level: ", tp);
      }
   }

   //--- Calculate lot size
   double lots = CalculateLotSize(InpStopLossPips);
   lots = NormalizeLotSize(lots);

   //--- Normalize prices
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   sl = NormalizeDouble(sl, digits);
   tp = NormalizeDouble(tp, digits);

   //--- Open position
   if(trade.Buy(lots, _Symbol, ask, sl, tp, InpTradeComment))
   {
      Print("BUY Position Opened - Lots: ", lots, " | Entry: ", ask, " | SL: ", sl, " | TP: ", tp);
   }
   else
   {
      Print("ERROR: Failed to open BUY position. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Open Sell Position                                                |
//+------------------------------------------------------------------+
void OpenSellPosition()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   //--- Calculate SL and TP
   double sl = bid + InpStopLossPips * pipPoint;
   double tp = bid - InpTakeProfitPips * pipPoint;

   //--- Check minimum stop level
   double minStopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   if(minStopLevel > 0)
   {
      if((sl - bid) < minStopLevel)
      {
         sl = bid + minStopLevel + _Point;
         Print("WARNING: SL adjusted to minimum stop level: ", sl);
      }
      if((bid - tp) < minStopLevel)
      {
         tp = bid - minStopLevel - _Point;
         Print("WARNING: TP adjusted to minimum stop level: ", tp);
      }
   }

   //--- Calculate lot size
   double lots = CalculateLotSize(InpStopLossPips);
   lots = NormalizeLotSize(lots);

   //--- Normalize prices
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   sl = NormalizeDouble(sl, digits);
   tp = NormalizeDouble(tp, digits);

   //--- Open position
   if(trade.Sell(lots, _Symbol, bid, sl, tp, InpTradeComment))
   {
      Print("SELL Position Opened - Lots: ", lots, " | Entry: ", bid, " | SL: ", sl, " | TP: ", tp);
   }
   else
   {
      Print("ERROR: Failed to open SELL position. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Update Breakeven                                                  |
//+------------------------------------------------------------------+
void UpdateBreakeven()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      long posType = PositionGetInteger(POSITION_TYPE);

      double breakevenSL = 0;
      double currentPrice = 0;
      double profitPips = 0;

      if(posType == POSITION_TYPE_BUY)
      {
         currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         profitPips = (currentPrice - openPrice) / pipPoint;
         breakevenSL = openPrice + InpBreakevenPlus * pipPoint;

         //--- Check if profit reached breakeven trigger
         if(profitPips >= InpBreakevenTrigger)
         {
            //--- Check if trailing stop already moved SL beyond breakeven
            if(InpUseTrailingStop && currentSL >= breakevenSL)
            {
               continue; // Trailing already better
            }

            //--- Check if SL not already at or above breakeven
            if(currentSL < breakevenSL)
            {
               int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
               breakevenSL = NormalizeDouble(breakevenSL, digits);

               if(trade.PositionModify(ticket, breakevenSL, currentTP))
               {
                  Print("BREAKEVEN Activated - Ticket: ", ticket, " | New SL: ", breakevenSL);
               }
               else
               {
                  Print("ERROR: Failed to modify breakeven. Error: ", GetLastError());
               }
            }
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         profitPips = (openPrice - currentPrice) / pipPoint;
         breakevenSL = openPrice - InpBreakevenPlus * pipPoint;

         //--- Check if profit reached breakeven trigger
         if(profitPips >= InpBreakevenTrigger)
         {
            //--- Check if trailing stop already moved SL beyond breakeven
            if(InpUseTrailingStop && currentSL > 0 && currentSL <= breakevenSL)
            {
               continue; // Trailing already better
            }

            //--- Check if SL not already at or below breakeven
            if(currentSL == 0 || currentSL > breakevenSL)
            {
               int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
               breakevenSL = NormalizeDouble(breakevenSL, digits);

               if(trade.PositionModify(ticket, breakevenSL, currentTP))
               {
                  Print("BREAKEVEN Activated - Ticket: ", ticket, " | New SL: ", breakevenSL);
               }
               else
               {
                  Print("ERROR: Failed to modify breakeven. Error: ", GetLastError());
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
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      long posType = PositionGetInteger(POSITION_TYPE);

      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      double minStopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;

      if(posType == POSITION_TYPE_BUY)
      {
         double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double profitPips = (currentPrice - openPrice) / pipPoint;

         //--- Check if enough profit for trailing
         if(profitPips >= InpTrailingStop)
         {
            double newSL = currentPrice - InpTrailingStop * pipPoint;
            newSL = NormalizeDouble(newSL, digits);

            //--- Check minimum stop level
            if(minStopLevel > 0 && (currentPrice - newSL) < minStopLevel)
            {
               newSL = currentPrice - minStopLevel - _Point;
               newSL = NormalizeDouble(newSL, digits);
            }

            //--- Check trailing step
            if(currentSL > 0 && (newSL - currentSL) < InpTrailingStep * pipPoint)
            {
               continue; // Step not reached
            }

            //--- Move SL only if new SL is better (higher for buy)
            if(currentSL == 0 || newSL > currentSL)
            {
               if(trade.PositionModify(ticket, newSL, currentTP))
               {
                  Print("TRAILING STOP Updated - Ticket: ", ticket, " | New SL: ", newSL, " | Profit Pips: ", profitPips);
               }
            }
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double profitPips = (openPrice - currentPrice) / pipPoint;

         //--- Check if enough profit for trailing
         if(profitPips >= InpTrailingStop)
         {
            double newSL = currentPrice + InpTrailingStop * pipPoint;
            newSL = NormalizeDouble(newSL, digits);

            //--- Check minimum stop level
            if(minStopLevel > 0 && (newSL - currentPrice) < minStopLevel)
            {
               newSL = currentPrice + minStopLevel + _Point;
               newSL = NormalizeDouble(newSL, digits);
            }

            //--- Check trailing step
            if(currentSL > 0 && (currentSL - newSL) < InpTrailingStep * pipPoint)
            {
               continue; // Step not reached
            }

            //--- Move SL only if new SL is better (lower for sell)
            if(currentSL == 0 || newSL < currentSL)
            {
               if(trade.PositionModify(ticket, newSL, currentTP))
               {
                  Print("TRAILING STOP Updated - Ticket: ", ticket, " | New SL: ", newSL, " | Profit Pips: ", profitPips);
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
      if(ticket == 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      long posType = PositionGetInteger(POSITION_TYPE);

      //--- Close BUY if MACD-V reaches extreme overbought
      if(posType == POSITION_TYPE_BUY && bufferMACDV[0] >= InpExtremeOverbought)
      {
         if(trade.PositionClose(ticket))
         {
            Print("EXTREME EXIT - BUY closed at extreme overbought. MACD-V: ", DoubleToString(bufferMACDV[0], 2));
         }
      }
      //--- Close SELL if MACD-V reaches extreme oversold
      else if(posType == POSITION_TYPE_SELL && bufferMACDV[0] <= InpExtremeOversold)
      {
         if(trade.PositionClose(ticket))
         {
            Print("EXTREME EXIT - SELL closed at extreme oversold. MACD-V: ", DoubleToString(bufferMACDV[0], 2));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check Reverse Close                                               |
//+------------------------------------------------------------------+
void CheckReverseClose()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      long posType = PositionGetInteger(POSITION_TYPE);

      //--- Close BUY if histogram crosses below sell level
      if(posType == POSITION_TYPE_BUY)
      {
         if(bufferHistogram[1] >= InpSellSignalLevel && bufferHistogram[0] < InpSellSignalLevel)
         {
            if(trade.PositionClose(ticket))
            {
               Print("REVERSE CLOSE - BUY closed on sell signal. Histogram: ", DoubleToString(bufferHistogram[0], 2));
            }
         }
      }
      //--- Close SELL if histogram crosses above buy level
      else if(posType == POSITION_TYPE_SELL)
      {
         if(bufferHistogram[1] <= InpBuySignalLevel && bufferHistogram[0] > InpBuySignalLevel)
         {
            if(trade.PositionClose(ticket))
            {
               Print("REVERSE CLOSE - SELL closed on buy signal. Histogram: ", DoubleToString(bufferHistogram[0], 2));
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate Lot Size Based on Risk                                  |
//+------------------------------------------------------------------+
double CalculateLotSize(double slPips)
{
   if(!InpUseDynamicLots)
      return InpLotSize;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * InpMaxRiskPercent / 100.0;

   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

   if(tickSize == 0 || tickValue == 0)
      return InpLotSize;

   double slPoints = slPips * pipValue;
   double slValue = (slPoints / tickSize) * tickValue;

   if(slValue == 0)
      return InpLotSize;

   double lots = riskAmount / slValue;

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

   //--- Round to lot step
   lots = MathFloor(lots / lotStep) * lotStep;

   //--- Apply limits
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;

   return NormalizeDouble(lots, 2);
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
      if(ticket == 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      count++;
   }

   return count;
}

//+------------------------------------------------------------------+
//| Get Current Spread in Pips                                        |
//+------------------------------------------------------------------+
double GetCurrentSpreadPips()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double spreadPoints = ask - bid;

   return spreadPoints / pipPoint;
}

//+------------------------------------------------------------------+
//| Check if Spread is OK                                             |
//+------------------------------------------------------------------+
bool IsSpreadOK()
{
   double spreadPips = GetCurrentSpreadPips();

   if(spreadPips > InpMaxSpreadPips)
   {
      return false;
   }

   return true;
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
