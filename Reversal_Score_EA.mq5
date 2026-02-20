//+------------------------------------------------------------------+
//|                                           Reversal_Score_EA.mq5 |
//|                         Reversal Score [10] - PRO v6 for MT5    |
//|                     10 Indicator Weighted Scoring System         |
//+------------------------------------------------------------------+
#property copyright "Reversal Score EA"
#property link      ""
#property version   "1.00"
#property description "10 Indicator Reversal Scoring System"
#property description "RSI, Stoch, CCI, W%R, BB, MACD, MFI, Volume, Divergence, Candle"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+
input group "=== SKOR AYARLARI ==="
input int      InpMinScore          = 7;       // Minimum Skor (1-10)
input bool     InpUseWeighted       = true;    // Ağırlıklı Skor Kullan

input group "=== AĞIRLIKLAR (1-5) ==="
input int      InpWeightRSI         = 2;       // RSI Ağırlık
input int      InpWeightStoch       = 1;       // Stochastic Ağırlık
input int      InpWeightCCI         = 2;       // CCI Ağırlık
input int      InpWeightWR          = 1;       // Williams %R Ağırlık
input int      InpWeightBB          = 2;       // Bollinger Bands Ağırlık
input int      InpWeightMACD        = 3;       // MACD Ağırlık
input int      InpWeightMFI         = 2;       // MFI Ağırlık
input int      InpWeightVol         = 2;       // Volume Ağırlık
input int      InpWeightDiv         = 4;       // Diverjans Ağırlık
input int      InpWeightCandle      = 2;       // Candle Pattern Ağırlık

input group "=== RSI PARAMETRELERI ==="
input int      InpRSILen            = 14;      // RSI Periyot
input int      InpRSIOB             = 75;      // RSI Overbought
input int      InpRSIOS             = 25;      // RSI Oversold

input group "=== STOCHASTIC PARAMETRELERI ==="
input int      InpStochK            = 14;      // Stochastic K Periyot
input int      InpStochD            = 3;       // Stochastic D Periyot
input int      InpStochSmooth       = 3;       // Stochastic Smoothing
input int      InpStochOB           = 85;      // Stochastic Overbought
input int      InpStochOS           = 15;      // Stochastic Oversold

input group "=== CCI PARAMETRELERI ==="
input int      InpCCILen            = 20;      // CCI Periyot
input int      InpCCILevel          = 150;     // CCI Eşik Seviyesi

input group "=== WILLIAMS %R PARAMETRELERI ==="
input int      InpWRLen             = 14;      // Williams %R Periyot
input int      InpWROB              = 15;      // W%R Overbought (15 -> -15)
input int      InpWROS              = 85;      // W%R Oversold (85 -> -85)

input group "=== BOLLINGER BANDS PARAMETRELERI ==="
input int      InpBBLen             = 20;      // BB Periyot
input double   InpBBMult            = 2.0;     // BB Standart Sapma Çarpanı

input group "=== MACD PARAMETRELERI ==="
input int      InpMACDFast          = 12;      // MACD Hızlı EMA
input int      InpMACDSlow          = 26;      // MACD Yavaş EMA
input int      InpMACDSignal        = 9;       // MACD Sinyal Periyodu

input group "=== MFI PARAMETRELERI ==="
input int      InpMFILen            = 14;      // MFI Periyot
input int      InpMFIOB             = 85;      // MFI Overbought
input int      InpMFIOS             = 15;      // MFI Oversold

input group "=== VOLUME PARAMETRELERI ==="
input int      InpVolLen            = 20;      // Volume MA Periyot
input double   InpVolMult           = 1.8;     // Volume Spike Çarpanı

input group "=== FİLTRELER (KALİTE) ==="
input int      InpMALen             = 50;      // Trend MA Periyot
input int      InpATRLen            = 14;      // ATR Periyot
input double   InpATRMult           = 1.2;     // Overextension ATR Çarpanı
input bool     InpUseADXFilter      = true;    // ADX Filtresi Kullan
input int      InpADXLen            = 14;      // ADX Periyot
input double   InpADXThreshold      = 28.0;    // ADX Eşik (üstü güçlü trend)
input int      InpPivotLen          = 5;       // Diverjans Pivot Periyot

input group "=== KONFİRMASYON / SPAM ÖNLEME ==="
input bool     InpRequireConfirm    = true;    // Konfirmasyon Gerekli
input int      InpConfirmBars       = 2;       // Konfirmasyon Bar Sayısı
input int      InpCooldownBars      = 10;      // Cooldown Bar Sayısı
input bool     InpResolveConflict   = true;    // Bull/Bear Çatışma Çöz

input group "=== İŞLEM AYARLARI ==="
input double   InpLotSize           = 0.1;     // Lot Büyüklüğü
input bool     InpUseDynamicLot     = false;   // Dinamik Lot Kullan
input double   InpRiskPercent       = 1.0;     // Risk Yüzdesi (Dinamik Lot)
input int      InpSLPips            = 50;      // Stop Loss (Pips)
input int      InpTPPips            = 100;     // Take Profit (Pips)
input bool     InpUseATRStops       = true;    // ATR Tabanlı SL/TP
input double   InpATRSLMult         = 1.5;     // ATR SL Çarpanı
input double   InpRiskReward        = 2.0;     // Risk:Reward Oranı
input int      InpMagicNumber       = 20240301;// Magic Number
input int      InpMaxSpread         = 30;      // Maksimum Spread (Points)
input int      InpSlippage          = 10;      // Slippage (Points)

input group "=== YÜKSEK KALİTE SİNYAL ==="
input int      InpHighScoreMin      = 8;       // Yüksek Kalite Min Skor
input double   InpHighVolRatio      = 2.0;     // Yüksek Kalite Vol Ratio

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+
CTrade         trade;
int            g_digits;

// Indicator handles
int            h_RSI;
int            h_Stoch;
int            h_CCI;
int            h_WR;
int            h_BB;
int            h_MACD;
int            h_MFI;
int            h_MA;
int            h_ATR;
int            h_ADX;
int            h_VolMA_Short;
int            h_VolMA_Long;

// Indicator buffers
double         buf_RSI[];
double         buf_StochK[];
double         buf_StochD[];
double         buf_CCI[];
double         buf_WR[];
double         buf_BBUpper[];
double         buf_BBMiddle[];
double         buf_BBLower[];
double         buf_MACD[];
double         buf_MACDSignal[];
double         buf_MACDHist[];
double         buf_MFI[];
double         buf_MA[];
double         buf_ATR[];
double         buf_ADX[];
double         buf_VolMA_Short[];
double         buf_VolMA_Long[];

// Divergence tracking
double         last_pivot_low;
double         prev_pivot_low;
double         last_pivot_low_rsi;
double         prev_pivot_low_rsi;
double         last_pivot_high;
double         prev_pivot_high;
double         last_pivot_high_rsi;
double         prev_pivot_high_rsi;

// Signal tracking
int            lastSignalBar;
bool           g_firstRun = true;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   g_digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   // Trade setup
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetMarginMode();

   // Initialize indicator handles
   h_RSI = iRSI(_Symbol, PERIOD_CURRENT, InpRSILen, PRICE_CLOSE);
   h_Stoch = iStochastic(_Symbol, PERIOD_CURRENT, InpStochK, InpStochD, InpStochSmooth, MODE_SMA, STO_LOWHIGH);
   h_CCI = iCCI(_Symbol, PERIOD_CURRENT, InpCCILen, PRICE_TYPICAL);
   h_WR = iWPR(_Symbol, PERIOD_CURRENT, InpWRLen);
   h_BB = iBands(_Symbol, PERIOD_CURRENT, InpBBLen, 0, InpBBMult, PRICE_CLOSE);
   h_MACD = iMACD(_Symbol, PERIOD_CURRENT, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
   h_MFI = iMFI(_Symbol, PERIOD_CURRENT, InpMFILen, VOLUME_TICK);
   h_MA = iMA(_Symbol, PERIOD_CURRENT, InpMALen, 0, MODE_EMA, PRICE_CLOSE);
   h_ATR = iATR(_Symbol, PERIOD_CURRENT, InpATRLen);
   h_ADX = iADX(_Symbol, PERIOD_CURRENT, InpADXLen);
   h_VolMA_Short = iMA(_Symbol, PERIOD_CURRENT, 10, 0, MODE_SMA, VOLUME_TICK);
   h_VolMA_Long = iMA(_Symbol, PERIOD_CURRENT, InpVolLen, 0, MODE_SMA, VOLUME_TICK);

   // Validate handles
   if(h_RSI == INVALID_HANDLE || h_Stoch == INVALID_HANDLE || h_CCI == INVALID_HANDLE ||
      h_WR == INVALID_HANDLE || h_BB == INVALID_HANDLE || h_MACD == INVALID_HANDLE ||
      h_MFI == INVALID_HANDLE || h_MA == INVALID_HANDLE || h_ATR == INVALID_HANDLE ||
      h_ADX == INVALID_HANDLE)
   {
      Print("Error creating indicator handles!");
      return INIT_FAILED;
   }

   // Initialize arrays
   ArraySetAsSeries(buf_RSI, true);
   ArraySetAsSeries(buf_StochK, true);
   ArraySetAsSeries(buf_StochD, true);
   ArraySetAsSeries(buf_CCI, true);
   ArraySetAsSeries(buf_WR, true);
   ArraySetAsSeries(buf_BBUpper, true);
   ArraySetAsSeries(buf_BBMiddle, true);
   ArraySetAsSeries(buf_BBLower, true);
   ArraySetAsSeries(buf_MACD, true);
   ArraySetAsSeries(buf_MACDSignal, true);
   ArraySetAsSeries(buf_MACDHist, true);
   ArraySetAsSeries(buf_MFI, true);
   ArraySetAsSeries(buf_MA, true);
   ArraySetAsSeries(buf_ATR, true);
   ArraySetAsSeries(buf_ADX, true);
   ArraySetAsSeries(buf_VolMA_Short, true);
   ArraySetAsSeries(buf_VolMA_Long, true);

   // Initialize divergence tracking
   last_pivot_low = 0;
   prev_pivot_low = 0;
   last_pivot_low_rsi = 0;
   prev_pivot_low_rsi = 0;
   last_pivot_high = 0;
   prev_pivot_high = 0;
   last_pivot_high_rsi = 0;
   prev_pivot_high_rsi = 0;

   // Initialize signal tracking
   lastSignalBar = -InpCooldownBars - 1;

   Print("==============================================");
   Print("Reversal Score EA v1.00 initialized");
   Print("Symbol: ", _Symbol, " | Timeframe: ", EnumToString(Period()));
   Print("Min Score: ", InpMinScore, " | Weighted: ", InpUseWeighted);
   Print("Magic: ", InpMagicNumber);
   Print("==============================================");

   g_firstRun = false;

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Release indicator handles
   if(h_RSI != INVALID_HANDLE) IndicatorRelease(h_RSI);
   if(h_Stoch != INVALID_HANDLE) IndicatorRelease(h_Stoch);
   if(h_CCI != INVALID_HANDLE) IndicatorRelease(h_CCI);
   if(h_WR != INVALID_HANDLE) IndicatorRelease(h_WR);
   if(h_BB != INVALID_HANDLE) IndicatorRelease(h_BB);
   if(h_MACD != INVALID_HANDLE) IndicatorRelease(h_MACD);
   if(h_MFI != INVALID_HANDLE) IndicatorRelease(h_MFI);
   if(h_MA != INVALID_HANDLE) IndicatorRelease(h_MA);
   if(h_ATR != INVALID_HANDLE) IndicatorRelease(h_ATR);
   if(h_ADX != INVALID_HANDLE) IndicatorRelease(h_ADX);
   if(h_VolMA_Short != INVALID_HANDLE) IndicatorRelease(h_VolMA_Short);
   if(h_VolMA_Long != INVALID_HANDLE) IndicatorRelease(h_VolMA_Long);

   Print("Reversal Score EA deinitialized. Reason: ", GetDeinitReasonText(reason));
}

//+------------------------------------------------------------------+
//| Get deinitialization reason text                                  |
//+------------------------------------------------------------------+
string GetDeinitReasonText(int reason)
{
   switch(reason)
   {
      case REASON_PROGRAM:     return "Program removed";
      case REASON_REMOVE:      return "Expert removed";
      case REASON_RECOMPILE:   return "Recompiled";
      case REASON_CHARTCHANGE: return "Symbol/TF changed";
      case REASON_CHARTCLOSE:  return "Chart closed";
      case REASON_PARAMETERS:  return "Parameters changed";
      case REASON_ACCOUNT:     return "Account changed";
      case REASON_TEMPLATE:    return "Template applied";
      case REASON_INITFAILED:  return "Init failed";
      case REASON_CLOSE:       return "Terminal closed";
      default:                 return "Unknown reason";
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check for new bar
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);

   if(lastBarTime == currentBarTime)
      return;

   lastBarTime = currentBarTime;

   // Check spread
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread > InpMaxSpread)
   {
      static datetime lastSpreadWarn = 0;
      if(TimeCurrent() - lastSpreadWarn > 60)
      {
         Print("Spread too high: ", spread, " > ", InpMaxSpread);
         lastSpreadWarn = TimeCurrent();
      }
      return;
   }

   // Copy indicator data
   if(!CopyIndicatorData())
   {
      Print("Failed to copy indicator data");
      return;
   }

   // Update divergence pivots
   UpdateDivergencePivots();

   // Calculate scores
   int bullScore = 0;
   int bearScore = 0;
   bool highQualityBull = false;
   bool highQualityBear = false;

   CalculateScores(bullScore, bearScore, highQualityBull, highQualityBear);

   // Check for existing position
   if(HasOpenPosition())
      return;

   // Check cooldown
   int currentBar = Bars(_Symbol, PERIOD_CURRENT);
   if(currentBar - lastSignalBar <= InpCooldownBars)
      return;

   // Generate signals
   bool bullSignal = false;
   bool bearSignal = false;

   GenerateSignals(bullScore, bearScore, bullSignal, bearSignal);

   // Execute trades
   if(bullSignal)
   {
      if(OpenBuyPosition(bullScore, highQualityBull))
      {
         lastSignalBar = currentBar;
         Print("BULL Signal! Score: ", bullScore, "/10", highQualityBull ? " [HIGH QUALITY]" : "");
      }
   }
   else if(bearSignal)
   {
      if(OpenSellPosition(bearScore, highQualityBear))
      {
         lastSignalBar = currentBar;
         Print("BEAR Signal! Score: ", bearScore, "/10", highQualityBear ? " [HIGH QUALITY]" : "");
      }
   }
}

//+------------------------------------------------------------------+
//| Copy all indicator data                                           |
//+------------------------------------------------------------------+
bool CopyIndicatorData()
{
   int bars_needed = MathMax(InpPivotLen * 2 + 5, 50);

   if(CopyBuffer(h_RSI, 0, 0, bars_needed, buf_RSI) < bars_needed) return false;
   if(CopyBuffer(h_Stoch, 0, 0, bars_needed, buf_StochK) < bars_needed) return false;
   if(CopyBuffer(h_Stoch, 1, 0, bars_needed, buf_StochD) < bars_needed) return false;
   if(CopyBuffer(h_CCI, 0, 0, bars_needed, buf_CCI) < bars_needed) return false;
   if(CopyBuffer(h_WR, 0, 0, bars_needed, buf_WR) < bars_needed) return false;
   if(CopyBuffer(h_BB, 1, 0, bars_needed, buf_BBUpper) < bars_needed) return false;
   if(CopyBuffer(h_BB, 0, 0, bars_needed, buf_BBMiddle) < bars_needed) return false;
   if(CopyBuffer(h_BB, 2, 0, bars_needed, buf_BBLower) < bars_needed) return false;
   if(CopyBuffer(h_MACD, 0, 0, bars_needed, buf_MACD) < bars_needed) return false;
   if(CopyBuffer(h_MACD, 1, 0, bars_needed, buf_MACDSignal) < bars_needed) return false;
   if(CopyBuffer(h_MFI, 0, 0, bars_needed, buf_MFI) < bars_needed) return false;
   if(CopyBuffer(h_MA, 0, 0, bars_needed, buf_MA) < bars_needed) return false;
   if(CopyBuffer(h_ATR, 0, 0, bars_needed, buf_ATR) < bars_needed) return false;
   if(CopyBuffer(h_ADX, 0, 0, bars_needed, buf_ADX) < bars_needed) return false;

   return true;
}

//+------------------------------------------------------------------+
//| Update divergence pivot points                                    |
//+------------------------------------------------------------------+
void UpdateDivergencePivots()
{
   int shift = InpPivotLen;

   // Check for pivot low
   double pivotLow = FindPivotLow(shift);
   if(pivotLow > 0)
   {
      prev_pivot_low = last_pivot_low;
      last_pivot_low = pivotLow;
      prev_pivot_low_rsi = last_pivot_low_rsi;
      last_pivot_low_rsi = buf_RSI[shift];
   }

   // Check for pivot high
   double pivotHigh = FindPivotHigh(shift);
   if(pivotHigh > 0)
   {
      prev_pivot_high = last_pivot_high;
      last_pivot_high = pivotHigh;
      prev_pivot_high_rsi = last_pivot_high_rsi;
      last_pivot_high_rsi = buf_RSI[shift];
   }
}

//+------------------------------------------------------------------+
//| Find pivot low                                                    |
//+------------------------------------------------------------------+
double FindPivotLow(int shift)
{
   double lowVal = iLow(_Symbol, PERIOD_CURRENT, shift);

   for(int i = 1; i <= InpPivotLen; i++)
   {
      if(iLow(_Symbol, PERIOD_CURRENT, shift - i) <= lowVal) return 0;
      if(iLow(_Symbol, PERIOD_CURRENT, shift + i) <= lowVal) return 0;
   }

   return lowVal;
}

//+------------------------------------------------------------------+
//| Find pivot high                                                   |
//+------------------------------------------------------------------+
double FindPivotHigh(int shift)
{
   double highVal = iHigh(_Symbol, PERIOD_CURRENT, shift);

   for(int i = 1; i <= InpPivotLen; i++)
   {
      if(iHigh(_Symbol, PERIOD_CURRENT, shift - i) >= highVal) return 0;
      if(iHigh(_Symbol, PERIOD_CURRENT, shift + i) >= highVal) return 0;
   }

   return highVal;
}

//+------------------------------------------------------------------+
//| Calculate bull and bear scores                                    |
//+------------------------------------------------------------------+
void CalculateScores(int &bullScore, int &bearScore, bool &highBull, bool &highBear)
{
   int idx = 1; // Use closed bar

   // Individual indicator signals
   bool bull_1 = false, bear_1 = false; // RSI
   bool bull_2 = false, bear_2 = false; // Stoch
   bool bull_3 = false, bear_3 = false; // CCI
   bool bull_4 = false, bear_4 = false; // W%R
   bool bull_5 = false, bear_5 = false; // BB
   bool bull_6 = false, bear_6 = false; // MACD
   bool bull_7 = false, bear_7 = false; // MFI
   bool bull_8 = false, bear_8 = false; // Volume
   bool bull_9 = false, bear_9 = false; // Divergence
   bool bull_10 = false, bear_10 = false; // Candle

   // 1. RSI
   bull_1 = buf_RSI[idx] <= InpRSIOS;
   bear_1 = buf_RSI[idx] >= InpRSIOB;

   // 2. Stochastic
   bull_2 = (buf_StochK[idx] < InpStochOS) && (buf_StochD[idx] < InpStochOS);
   bear_2 = (buf_StochK[idx] > InpStochOB) && (buf_StochD[idx] > InpStochOB);

   // 3. CCI
   bull_3 = buf_CCI[idx] <= -InpCCILevel;
   bear_3 = buf_CCI[idx] >= InpCCILevel;

   // 4. Williams %R (MT5 returns -100 to 0)
   bull_4 = buf_WR[idx] <= -InpWROS;
   bear_4 = buf_WR[idx] >= -InpWROB;

   // 5. Bollinger Bands (taşma + geri dönüş)
   double low1 = iLow(_Symbol, PERIOD_CURRENT, idx);
   double high1 = iHigh(_Symbol, PERIOD_CURRENT, idx);
   double close1 = iClose(_Symbol, PERIOD_CURRENT, idx);

   bull_5 = (low1 < buf_BBLower[idx]) && (close1 > buf_BBLower[idx]);
   bear_5 = (high1 > buf_BBUpper[idx]) && (close1 < buf_BBUpper[idx]);

   // 6. MACD Cross
   bool macdCrossUp = (buf_MACD[idx] > buf_MACDSignal[idx]) && (buf_MACD[idx+1] <= buf_MACDSignal[idx+1]);
   bool macdCrossDown = (buf_MACD[idx] < buf_MACDSignal[idx]) && (buf_MACD[idx+1] >= buf_MACDSignal[idx+1]);

   bull_6 = macdCrossUp && (buf_MACD[idx] < 0);
   bear_6 = macdCrossDown && (buf_MACD[idx] > 0);

   // 7. MFI
   bull_7 = buf_MFI[idx] <= InpMFIOS;
   bear_7 = buf_MFI[idx] >= InpMFIOB;

   // 8. Volume
   double volume1 = (double)iVolume(_Symbol, PERIOD_CURRENT, idx);
   double volMA_Long = GetVolumeMA(InpVolLen, idx);
   double volMA_Short = GetVolumeMA(10, idx);
   double open1 = iOpen(_Symbol, PERIOD_CURRENT, idx);

   bool volUp = volMA_Short > volMA_Long;
   bool volSpike = (volMA_Long > 0) && (volume1 >= volMA_Long * InpVolMult);
   double volRatio = (volMA_Long > 0) ? volume1 / volMA_Long : 0;

   bull_8 = volSpike && (close1 > open1) && volUp && (volRatio > 1.5);
   bear_8 = volSpike && (close1 < open1) && volUp && (volRatio > 1.5);

   // 9. RSI Divergence
   if(prev_pivot_low > 0 && last_pivot_low > 0)
   {
      bull_9 = (last_pivot_low < prev_pivot_low) &&
               (last_pivot_low_rsi > prev_pivot_low_rsi) &&
               (last_pivot_low_rsi < 50);
   }

   if(prev_pivot_high > 0 && last_pivot_high > 0)
   {
      bear_9 = (last_pivot_high > prev_pivot_high) &&
               (last_pivot_high_rsi < prev_pivot_high_rsi) &&
               (last_pivot_high_rsi > 50);
   }

   // 10. Candle Patterns
   double body = MathAbs(close1 - open1);
   double range = high1 - low1;
   double upperWick = high1 - MathMax(close1, open1);
   double lowerWick = MathMin(close1, open1) - low1;

   bool smallBody = (body > 0) && (body <= range * 0.35);
   bool hammer = smallBody && (lowerWick >= body * 2.0) && (upperWick <= body * 0.6);
   bool shootingStar = smallBody && (upperWick >= body * 2.0) && (lowerWick <= body * 0.6);

   // Engulfing patterns
   double close2 = iClose(_Symbol, PERIOD_CURRENT, idx + 1);
   double open2 = iOpen(_Symbol, PERIOD_CURRENT, idx + 1);

   bool bullEngulf = (close1 > open1) && (close2 < open2) && (close1 >= open2) && (open1 <= close2);
   bool bearEngulf = (close1 < open1) && (close2 > open2) && (close1 <= open2) && (open1 >= close2);

   bull_10 = hammer || bullEngulf;
   bear_10 = shootingStar || bearEngulf;

   // Calculate weighted scores
   int maxPossible = InpWeightRSI + InpWeightStoch + InpWeightCCI + InpWeightWR +
                     InpWeightBB + InpWeightMACD + InpWeightMFI + InpWeightVol +
                     InpWeightDiv + InpWeightCandle;

   int bullWeighted = (bull_1 ? InpWeightRSI : 0) + (bull_2 ? InpWeightStoch : 0) +
                      (bull_3 ? InpWeightCCI : 0) + (bull_4 ? InpWeightWR : 0) +
                      (bull_5 ? InpWeightBB : 0) + (bull_6 ? InpWeightMACD : 0) +
                      (bull_7 ? InpWeightMFI : 0) + (bull_8 ? InpWeightVol : 0) +
                      (bull_9 ? InpWeightDiv : 0) + (bull_10 ? InpWeightCandle : 0);

   int bearWeighted = (bear_1 ? InpWeightRSI : 0) + (bear_2 ? InpWeightStoch : 0) +
                      (bear_3 ? InpWeightCCI : 0) + (bear_4 ? InpWeightWR : 0) +
                      (bear_5 ? InpWeightBB : 0) + (bear_6 ? InpWeightMACD : 0) +
                      (bear_7 ? InpWeightMFI : 0) + (bear_8 ? InpWeightVol : 0) +
                      (bear_9 ? InpWeightDiv : 0) + (bear_10 ? InpWeightCandle : 0);

   if(InpUseWeighted)
   {
      bullScore = NormalizeScore(bullWeighted, maxPossible);
      bearScore = NormalizeScore(bearWeighted, maxPossible);
   }
   else
   {
      bullScore = (bull_1?1:0) + (bull_2?1:0) + (bull_3?1:0) + (bull_4?1:0) + (bull_5?1:0) +
                  (bull_6?1:0) + (bull_7?1:0) + (bull_8?1:0) + (bull_9?1:0) + (bull_10?1:0);
      bearScore = (bear_1?1:0) + (bear_2?1:0) + (bear_3?1:0) + (bear_4?1:0) + (bear_5?1:0) +
                  (bear_6?1:0) + (bear_7?1:0) + (bear_8?1:0) + (bear_9?1:0) + (bear_10?1:0);
   }

   // High quality signals
   highBull = (bullScore >= InpHighScoreMin) && volUp && (volRatio > InpHighVolRatio) && (bull_9 || bull_10);
   highBear = (bearScore >= InpHighScoreMin) && volUp && (volRatio > InpHighVolRatio) && (bear_9 || bear_10);
}

//+------------------------------------------------------------------+
//| Normalize score to 0-10 range                                     |
//+------------------------------------------------------------------+
int NormalizeScore(int weighted, int maxPossible)
{
   if(maxPossible == 0) return 0;
   double normalized = (double)weighted * 10.0 / (double)maxPossible;
   return (int)MathMin(MathMax(MathRound(normalized), 0), 10);
}

//+------------------------------------------------------------------+
//| Get volume moving average                                         |
//+------------------------------------------------------------------+
double GetVolumeMA(int period, int shift)
{
   double sum = 0;
   for(int i = 0; i < period; i++)
   {
      sum += (double)iVolume(_Symbol, PERIOD_CURRENT, shift + i);
   }
   return sum / period;
}

//+------------------------------------------------------------------+
//| Generate trading signals                                          |
//+------------------------------------------------------------------+
void GenerateSignals(int bullScore, int bearScore, bool &bullSignal, bool &bearSignal)
{
   int idx = 1;
   double close1 = iClose(_Symbol, PERIOD_CURRENT, idx);
   double open1 = iOpen(_Symbol, PERIOD_CURRENT, idx);

   // Context filters
   bool bullCtx = close1 < buf_MA[idx]; // Counter-trend: price below MA
   bool bearCtx = close1 > buf_MA[idx]; // Counter-trend: price above MA

   // Overextension filter
   bool overext = MathAbs(close1 - buf_MA[idx]) > buf_ATR[idx] * InpATRMult;

   // ADX filter (momentum_ok when ADX is not too strong)
   bool momentumOk = (!InpUseADXFilter) || (buf_ADX[idx] <= InpADXThreshold);

   // Base signals
   bool baseBull = bullScore >= InpMinScore;
   bool baseBear = bearScore >= InpMinScore;

   // Apply filters
   bool bullFiltered = baseBull && bullCtx && overext && momentumOk;
   bool bearFiltered = baseBear && bearCtx && overext && momentumOk;

   // Apply confirmation
   bool bullConfirmed = bullFiltered;
   bool bearConfirmed = bearFiltered;

   if(InpRequireConfirm)
   {
      if(InpConfirmBars == 1)
      {
         bullConfirmed = bullFiltered && (close1 > open1);
         bearConfirmed = bearFiltered && (close1 < open1);
      }
      else
      {
         // Check multiple bars for confirmation
         int bullishBars = 0;
         int bearishBars = 0;

         for(int i = 1; i <= InpConfirmBars; i++)
         {
            double c = iClose(_Symbol, PERIOD_CURRENT, i);
            double o = iOpen(_Symbol, PERIOD_CURRENT, i);
            if(c > o) bullishBars++;
            if(c < o) bearishBars++;
         }

         double bullFrac = (double)bullishBars / InpConfirmBars;
         double bearFrac = (double)bearishBars / InpConfirmBars;

         bullConfirmed = bullFiltered && (bullFrac >= 0.67);
         bearConfirmed = bearFiltered && (bearFrac >= 0.67);
      }
   }

   // Resolve conflict
   bullSignal = bullConfirmed;
   bearSignal = bearConfirmed;

   if(InpResolveConflict && bullConfirmed && bearConfirmed)
   {
      bullSignal = bullScore > bearScore;
      bearSignal = bearScore > bullScore;
   }
}

//+------------------------------------------------------------------+
//| Check if there's an open position                                 |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         {
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Calculate lot size                                                |
//+------------------------------------------------------------------+
double CalculateLotSize(double slPips)
{
   if(!InpUseDynamicLot)
      return InpLotSize;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * InpRiskPercent / 100.0;

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   if(tickValue == 0 || tickSize == 0 || point == 0)
      return InpLotSize;

   double pipValue = tickValue * (point * 10) / tickSize;
   double lots = riskAmount / (slPips * pipValue);

   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(minLot, MathMin(maxLot, lots));

   return lots;
}

//+------------------------------------------------------------------+
//| Calculate stop loss price                                         |
//+------------------------------------------------------------------+
double CalculateSL(bool isBuy, double &slPips)
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double price = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(InpUseATRStops)
   {
      double atr = buf_ATR[1];
      slPips = (atr * InpATRSLMult) / point / 10;

      // Clamp to reasonable limits
      slPips = MathMax(10, MathMin(200, slPips));
   }
   else
   {
      slPips = InpSLPips;
   }

   if(isBuy)
      return NormalizeDouble(price - slPips * 10 * point, g_digits);
   else
      return NormalizeDouble(price + slPips * 10 * point, g_digits);
}

//+------------------------------------------------------------------+
//| Calculate take profit price                                       |
//+------------------------------------------------------------------+
double CalculateTP(bool isBuy, double slPips)
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double price = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double tpPips;
   if(InpUseATRStops)
   {
      tpPips = slPips * InpRiskReward;
   }
   else
   {
      tpPips = InpTPPips;
   }

   if(isBuy)
      return NormalizeDouble(price + tpPips * 10 * point, g_digits);
   else
      return NormalizeDouble(price - tpPips * 10 * point, g_digits);
}

//+------------------------------------------------------------------+
//| Open buy position                                                 |
//+------------------------------------------------------------------+
bool OpenBuyPosition(int score, bool highQuality)
{
   double slPips = 0;
   double sl = CalculateSL(true, slPips);
   double tp = CalculateTP(true, slPips);
   double lots = CalculateLotSize(slPips);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   string comment = StringFormat("RS_BUY_%d%s", score, highQuality ? "_HQ" : "");

   if(trade.Buy(lots, _Symbol, ask, sl, tp, comment))
   {
      Print("BUY opened: Lots=", lots, " SL=", sl, " TP=", tp, " Score=", score);
      return true;
   }
   else
   {
      Print("BUY failed: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Open sell position                                                |
//+------------------------------------------------------------------+
bool OpenSellPosition(int score, bool highQuality)
{
   double slPips = 0;
   double sl = CalculateSL(false, slPips);
   double tp = CalculateTP(false, slPips);
   double lots = CalculateLotSize(slPips);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   string comment = StringFormat("RS_SELL_%d%s", score, highQuality ? "_HQ" : "");

   if(trade.Sell(lots, _Symbol, bid, sl, tp, comment))
   {
      Print("SELL opened: Lots=", lots, " SL=", sl, " TP=", tp, " Score=", score);
      return true;
   }
   else
   {
      Print("SELL failed: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
      return false;
   }
}

//+------------------------------------------------------------------+
//| OnTrade event handler                                             |
//+------------------------------------------------------------------+
void OnTrade()
{
   static ulong lastDealTicket = 0;

   // Check for closed deals
   HistorySelect(0, TimeCurrent());
   int totalDeals = HistoryDealsTotal();

   for(int i = totalDeals - 1; i >= 0; i--)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket <= lastDealTicket) break;

      if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) == _Symbol &&
         HistoryDealGetInteger(dealTicket, DEAL_MAGIC) == InpMagicNumber)
      {
         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);

         if(entry == DEAL_ENTRY_OUT)
         {
            double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
            double volume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
            string comment = HistoryDealGetString(dealTicket, DEAL_COMMENT);

            Print("Trade closed: Profit=", profit, " Volume=", volume, " Comment=", comment);

            lastDealTicket = dealTicket;
         }
      }
   }
}
//+------------------------------------------------------------------+
