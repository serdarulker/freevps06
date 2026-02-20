//+------------------------------------------------------------------+
//|                                     Reversal_Score_Indicator.mq5 |
//|                         Reversal Score [10] - PRO v6 Indicator   |
//|                     10 Indicator Weighted Scoring System         |
//+------------------------------------------------------------------+
#property copyright "Reversal Score Indicator"
#property link      ""
#property version   "1.00"
#property description "10 Indicator Reversal Scoring System"
#property description "RSI, Stoch, CCI, W%R, BB, MACD, MFI, Volume, Divergence, Candle"

#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   6

// Plot 1: MA
#property indicator_label1  "Trend MA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGray
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

// Plot 2: BB Upper
#property indicator_label2  "BB Upper"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

// Plot 3: BB Middle
#property indicator_label3  "BB Middle"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDodgerBlue
#property indicator_style3  STYLE_DOT
#property indicator_width3  1

// Plot 4: BB Lower
#property indicator_label4  "BB Lower"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrDodgerBlue
#property indicator_style4  STYLE_DOT
#property indicator_width4  1

// Plot 5: Bull Signal (Arrow Up)
#property indicator_label5  "Bull Signal"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrLime
#property indicator_width5  3

// Plot 6: Bear Signal (Arrow Down)
#property indicator_label6  "Bear Signal"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrRed
#property indicator_width6  3

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

input group "=== GÖRSEL AYARLAR ==="
input bool     InpShowLabels        = true;    // Skor Etiketi Göster
input bool     InpShowPanel         = true;    // Skor Paneli Göster
input bool     InpShowBB            = true;    // Bollinger Bands Göster
input bool     InpShowMA            = true;    // Trend MA Göster
input color    InpBullColor         = clrLime; // Bull Sinyal Rengi
input color    InpBearColor         = clrRed;  // Bear Sinyal Rengi
input int      InpArrowSize         = 3;       // Ok Boyutu (1-5)

input group "=== YÜKSEK KALİTE SİNYAL ==="
input int      InpHighScoreMin      = 8;       // Yüksek Kalite Min Skor
input double   InpHighVolRatio      = 2.0;     // Yüksek Kalite Vol Ratio

input group "=== ALERT AYARLARI ==="
input bool     InpAlertPopup        = true;    // Popup Alert
input bool     InpAlertSound        = true;    // Ses Alert
input bool     InpAlertPush         = false;   // Push Notification
input bool     InpAlertEmail        = false;   // Email Alert

//+------------------------------------------------------------------+
//| INDICATOR BUFFERS                                                 |
//+------------------------------------------------------------------+
double         buf_MA[];
double         buf_BBUpper[];
double         buf_BBMiddle[];
double         buf_BBLower[];
double         buf_BullSignal[];
double         buf_BearSignal[];
double         buf_BullScore[];     // Internal buffer
double         buf_BearScore[];     // Internal buffer

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+
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

// Internal indicator buffers
double         ind_RSI[];
double         ind_StochK[];
double         ind_StochD[];
double         ind_CCI[];
double         ind_WR[];
double         ind_BBUpper[];
double         ind_BBMiddle[];
double         ind_BBLower[];
double         ind_MACD[];
double         ind_MACDSignal[];
double         ind_MFI[];
double         ind_MA[];
double         ind_ATR[];
double         ind_ADX[];

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
string         panelName = "RS_Panel";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit()
{
   // Set indicator buffers
   SetIndexBuffer(0, buf_MA, INDICATOR_DATA);
   SetIndexBuffer(1, buf_BBUpper, INDICATOR_DATA);
   SetIndexBuffer(2, buf_BBMiddle, INDICATOR_DATA);
   SetIndexBuffer(3, buf_BBLower, INDICATOR_DATA);
   SetIndexBuffer(4, buf_BullSignal, INDICATOR_DATA);
   SetIndexBuffer(5, buf_BearSignal, INDICATOR_DATA);
   SetIndexBuffer(6, buf_BullScore, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, buf_BearScore, INDICATOR_CALCULATIONS);

   // Set arrow codes
   PlotIndexSetInteger(4, PLOT_ARROW, 233);  // Arrow up
   PlotIndexSetInteger(5, PLOT_ARROW, 234);  // Arrow down

   // Set arrow colors
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, InpBullColor);
   PlotIndexSetInteger(5, PLOT_LINE_COLOR, InpBearColor);

   // Set arrow width
   PlotIndexSetInteger(4, PLOT_LINE_WIDTH, InpArrowSize);
   PlotIndexSetInteger(5, PLOT_LINE_WIDTH, InpArrowSize);

   // Set empty values
   PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(5, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   // Show/hide plots
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, InpShowMA ? DRAW_LINE : DRAW_NONE);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, InpShowBB ? DRAW_LINE : DRAW_NONE);
   PlotIndexSetInteger(2, PLOT_DRAW_TYPE, InpShowBB ? DRAW_LINE : DRAW_NONE);
   PlotIndexSetInteger(3, PLOT_DRAW_TYPE, InpShowBB ? DRAW_LINE : DRAW_NONE);

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

   // Validate handles
   if(h_RSI == INVALID_HANDLE || h_Stoch == INVALID_HANDLE || h_CCI == INVALID_HANDLE ||
      h_WR == INVALID_HANDLE || h_BB == INVALID_HANDLE || h_MACD == INVALID_HANDLE ||
      h_MFI == INVALID_HANDLE || h_MA == INVALID_HANDLE || h_ATR == INVALID_HANDLE ||
      h_ADX == INVALID_HANDLE)
   {
      Print("Error creating indicator handles!");
      return INIT_FAILED;
   }

   // Initialize arrays as series
   ArraySetAsSeries(ind_RSI, true);
   ArraySetAsSeries(ind_StochK, true);
   ArraySetAsSeries(ind_StochD, true);
   ArraySetAsSeries(ind_CCI, true);
   ArraySetAsSeries(ind_WR, true);
   ArraySetAsSeries(ind_BBUpper, true);
   ArraySetAsSeries(ind_BBMiddle, true);
   ArraySetAsSeries(ind_BBLower, true);
   ArraySetAsSeries(ind_MACD, true);
   ArraySetAsSeries(ind_MACDSignal, true);
   ArraySetAsSeries(ind_MFI, true);
   ArraySetAsSeries(ind_MA, true);
   ArraySetAsSeries(ind_ATR, true);
   ArraySetAsSeries(ind_ADX, true);

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

   // Set indicator name
   IndicatorSetString(INDICATOR_SHORTNAME, "Reversal Score [10]");
   IndicatorSetInteger(INDICATOR_DIGITS, 0);

   // Create panel
   if(InpShowPanel)
      CreatePanel();

   Print("Reversal Score Indicator v1.00 initialized");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
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

   // Delete labels and panel
   ObjectsDeleteAll(0, "RS_");

   Comment("");
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                               |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   // Check for minimum bars
   if(rates_total < MathMax(InpMALen, InpBBLen) + 50)
      return 0;

   // Set arrays as series
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(tick_volume, true);
   ArraySetAsSeries(buf_MA, true);
   ArraySetAsSeries(buf_BBUpper, true);
   ArraySetAsSeries(buf_BBMiddle, true);
   ArraySetAsSeries(buf_BBLower, true);
   ArraySetAsSeries(buf_BullSignal, true);
   ArraySetAsSeries(buf_BearSignal, true);
   ArraySetAsSeries(buf_BullScore, true);
   ArraySetAsSeries(buf_BearScore, true);

   // Copy indicator data
   int bars_to_copy = rates_total - prev_calculated + 1;
   if(prev_calculated == 0) bars_to_copy = rates_total;

   if(CopyBuffer(h_RSI, 0, 0, bars_to_copy, ind_RSI) < bars_to_copy) return 0;
   if(CopyBuffer(h_Stoch, 0, 0, bars_to_copy, ind_StochK) < bars_to_copy) return 0;
   if(CopyBuffer(h_Stoch, 1, 0, bars_to_copy, ind_StochD) < bars_to_copy) return 0;
   if(CopyBuffer(h_CCI, 0, 0, bars_to_copy, ind_CCI) < bars_to_copy) return 0;
   if(CopyBuffer(h_WR, 0, 0, bars_to_copy, ind_WR) < bars_to_copy) return 0;
   if(CopyBuffer(h_BB, 1, 0, bars_to_copy, ind_BBUpper) < bars_to_copy) return 0;
   if(CopyBuffer(h_BB, 0, 0, bars_to_copy, ind_BBMiddle) < bars_to_copy) return 0;
   if(CopyBuffer(h_BB, 2, 0, bars_to_copy, ind_BBLower) < bars_to_copy) return 0;
   if(CopyBuffer(h_MACD, 0, 0, bars_to_copy, ind_MACD) < bars_to_copy) return 0;
   if(CopyBuffer(h_MACD, 1, 0, bars_to_copy, ind_MACDSignal) < bars_to_copy) return 0;
   if(CopyBuffer(h_MFI, 0, 0, bars_to_copy, ind_MFI) < bars_to_copy) return 0;
   if(CopyBuffer(h_MA, 0, 0, bars_to_copy, ind_MA) < bars_to_copy) return 0;
   if(CopyBuffer(h_ATR, 0, 0, bars_to_copy, ind_ATR) < bars_to_copy) return 0;
   if(CopyBuffer(h_ADX, 0, 0, bars_to_copy, ind_ADX) < bars_to_copy) return 0;

   // Calculate start position
   int start = prev_calculated == 0 ? rates_total - InpPivotLen * 2 - 10 : rates_total - prev_calculated;
   if(start < 1) start = 1;

   // Main calculation loop
   for(int i = start; i >= 0; i--)
   {
      // Copy MA and BB values to display buffers
      buf_MA[i] = ind_MA[i];
      buf_BBUpper[i] = ind_BBUpper[i];
      buf_BBMiddle[i] = ind_BBMiddle[i];
      buf_BBLower[i] = ind_BBLower[i];

      // Initialize signal buffers
      buf_BullSignal[i] = EMPTY_VALUE;
      buf_BearSignal[i] = EMPTY_VALUE;
      buf_BullScore[i] = 0;
      buf_BearScore[i] = 0;

      // Skip if not enough data
      if(i + InpPivotLen + 1 >= ArraySize(ind_RSI)) continue;

      // Update divergence pivots
      UpdateDivergencePivots(i, low, high);

      // Calculate scores
      int bullScore = 0;
      int bearScore = 0;
      bool highQualityBull = false;
      bool highQualityBear = false;
      bool volUp = false;

      CalculateScores(i, open, high, low, close, tick_volume,
                      bullScore, bearScore, highQualityBull, highQualityBear, volUp);

      buf_BullScore[i] = bullScore;
      buf_BearScore[i] = bearScore;

      // Generate signals only for bar 1 (closed bar) when at bar 0
      if(i == 0)
      {
         int idx = 1;
         bool bullSignal = false;
         bool bearSignal = false;

         GenerateSignals(idx, open, close, (int)buf_BullScore[idx], (int)buf_BearScore[idx],
                         bullSignal, bearSignal);

         // Check cooldown
         int currentBar = rates_total;
         bool canFire = (InpCooldownBars == 0) || (currentBar - lastSignalBar > InpCooldownBars);

         if(canFire)
         {
            if(bullSignal)
            {
               buf_BullSignal[idx] = low[idx] - ind_ATR[idx] * 0.5;
               lastSignalBar = currentBar;

               // Create label
               if(InpShowLabels)
                  CreateSignalLabel(time[idx], buf_BullSignal[idx], (int)buf_BullScore[idx], true, highQualityBull);

               // Send alerts
               SendAlert("BULL", (int)buf_BullScore[idx], highQualityBull);
            }
            else if(bearSignal)
            {
               buf_BearSignal[idx] = high[idx] + ind_ATR[idx] * 0.5;
               lastSignalBar = currentBar;

               // Create label
               if(InpShowLabels)
                  CreateSignalLabel(time[idx], buf_BearSignal[idx], (int)buf_BearScore[idx], false, highQualityBear);

               // Send alerts
               SendAlert("BEAR", (int)buf_BearScore[idx], highQualityBear);
            }
         }

         // Update panel
         if(InpShowPanel)
            UpdatePanel((int)buf_BullScore[1], (int)buf_BearScore[1]);
      }
   }

   return rates_total;
}

//+------------------------------------------------------------------+
//| Update divergence pivot points                                    |
//+------------------------------------------------------------------+
void UpdateDivergencePivots(int idx, const double &low[], const double &high[])
{
   int shift = idx + InpPivotLen;

   // Check for pivot low
   double pivotLow = FindPivotLow(shift, low);
   if(pivotLow > 0)
   {
      prev_pivot_low = last_pivot_low;
      last_pivot_low = pivotLow;
      prev_pivot_low_rsi = last_pivot_low_rsi;
      last_pivot_low_rsi = ind_RSI[shift];
   }

   // Check for pivot high
   double pivotHigh = FindPivotHigh(shift, high);
   if(pivotHigh > 0)
   {
      prev_pivot_high = last_pivot_high;
      last_pivot_high = pivotHigh;
      prev_pivot_high_rsi = last_pivot_high_rsi;
      last_pivot_high_rsi = ind_RSI[shift];
   }
}

//+------------------------------------------------------------------+
//| Find pivot low                                                    |
//+------------------------------------------------------------------+
double FindPivotLow(int shift, const double &low[])
{
   if(shift + InpPivotLen >= ArraySize(low) || shift - InpPivotLen < 0)
      return 0;

   double lowVal = low[shift];

   for(int i = 1; i <= InpPivotLen; i++)
   {
      if(low[shift - i] <= lowVal) return 0;
      if(low[shift + i] <= lowVal) return 0;
   }

   return lowVal;
}

//+------------------------------------------------------------------+
//| Find pivot high                                                   |
//+------------------------------------------------------------------+
double FindPivotHigh(int shift, const double &high[])
{
   if(shift + InpPivotLen >= ArraySize(high) || shift - InpPivotLen < 0)
      return 0;

   double highVal = high[shift];

   for(int i = 1; i <= InpPivotLen; i++)
   {
      if(high[shift - i] >= highVal) return 0;
      if(high[shift + i] >= highVal) return 0;
   }

   return highVal;
}

//+------------------------------------------------------------------+
//| Calculate bull and bear scores                                    |
//+------------------------------------------------------------------+
void CalculateScores(int idx, const double &open[], const double &high[],
                     const double &low[], const double &close[], const long &tick_volume[],
                     int &bullScore, int &bearScore, bool &highBull, bool &highBear, bool &volUp)
{
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
   bull_1 = ind_RSI[idx] <= InpRSIOS;
   bear_1 = ind_RSI[idx] >= InpRSIOB;

   // 2. Stochastic
   bull_2 = (ind_StochK[idx] < InpStochOS) && (ind_StochD[idx] < InpStochOS);
   bear_2 = (ind_StochK[idx] > InpStochOB) && (ind_StochD[idx] > InpStochOB);

   // 3. CCI
   bull_3 = ind_CCI[idx] <= -InpCCILevel;
   bear_3 = ind_CCI[idx] >= InpCCILevel;

   // 4. Williams %R
   bull_4 = ind_WR[idx] <= -InpWROS;
   bear_4 = ind_WR[idx] >= -InpWROB;

   // 5. Bollinger Bands
   bull_5 = (low[idx] < ind_BBLower[idx]) && (close[idx] > ind_BBLower[idx]);
   bear_5 = (high[idx] > ind_BBUpper[idx]) && (close[idx] < ind_BBUpper[idx]);

   // 6. MACD Cross
   if(idx + 1 < ArraySize(ind_MACD))
   {
      bool macdCrossUp = (ind_MACD[idx] > ind_MACDSignal[idx]) && (ind_MACD[idx+1] <= ind_MACDSignal[idx+1]);
      bool macdCrossDown = (ind_MACD[idx] < ind_MACDSignal[idx]) && (ind_MACD[idx+1] >= ind_MACDSignal[idx+1]);

      bull_6 = macdCrossUp && (ind_MACD[idx] < 0);
      bear_6 = macdCrossDown && (ind_MACD[idx] > 0);
   }

   // 7. MFI
   bull_7 = ind_MFI[idx] <= InpMFIOS;
   bear_7 = ind_MFI[idx] >= InpMFIOB;

   // 8. Volume
   double volume1 = (double)tick_volume[idx];
   double volMA_Long = GetVolumeMA(InpVolLen, idx, tick_volume);
   double volMA_Short = GetVolumeMA(10, idx, tick_volume);

   volUp = volMA_Short > volMA_Long;
   bool volSpike = (volMA_Long > 0) && (volume1 >= volMA_Long * InpVolMult);
   double volRatio = (volMA_Long > 0) ? volume1 / volMA_Long : 0;

   bull_8 = volSpike && (close[idx] > open[idx]) && volUp && (volRatio > 1.5);
   bear_8 = volSpike && (close[idx] < open[idx]) && volUp && (volRatio > 1.5);

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
   double body = MathAbs(close[idx] - open[idx]);
   double range = high[idx] - low[idx];
   double upperWick = high[idx] - MathMax(close[idx], open[idx]);
   double lowerWick = MathMin(close[idx], open[idx]) - low[idx];

   bool smallBody = (body > 0) && (range > 0) && (body <= range * 0.35);
   bool hammer = smallBody && (lowerWick >= body * 2.0) && (upperWick <= body * 0.6);
   bool shootingStar = smallBody && (upperWick >= body * 2.0) && (lowerWick <= body * 0.6);

   // Engulfing patterns
   if(idx + 1 < ArraySize(close))
   {
      bool bullEngulf = (close[idx] > open[idx]) && (close[idx+1] < open[idx+1]) &&
                        (close[idx] >= open[idx+1]) && (open[idx] <= close[idx+1]);
      bool bearEngulf = (close[idx] < open[idx]) && (close[idx+1] > open[idx+1]) &&
                        (close[idx] <= open[idx+1]) && (open[idx] >= close[idx+1]);

      bull_10 = hammer || bullEngulf;
      bear_10 = shootingStar || bearEngulf;
   }
   else
   {
      bull_10 = hammer;
      bear_10 = shootingStar;
   }

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
double GetVolumeMA(int period, int shift, const long &tick_volume[])
{
   if(shift + period >= ArraySize(tick_volume))
      return 0;

   double sum = 0;
   for(int i = 0; i < period; i++)
   {
      sum += (double)tick_volume[shift + i];
   }
   return sum / period;
}

//+------------------------------------------------------------------+
//| Generate trading signals                                          |
//+------------------------------------------------------------------+
void GenerateSignals(int idx, const double &open[], const double &close[],
                     int bullScore, int bearScore, bool &bullSignal, bool &bearSignal)
{
   // Context filters
   bool bullCtx = close[idx] < ind_MA[idx]; // Counter-trend: price below MA
   bool bearCtx = close[idx] > ind_MA[idx]; // Counter-trend: price above MA

   // Overextension filter
   bool overext = MathAbs(close[idx] - ind_MA[idx]) > ind_ATR[idx] * InpATRMult;

   // ADX filter
   bool momentumOk = (!InpUseADXFilter) || (ind_ADX[idx] <= InpADXThreshold);

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
         bullConfirmed = bullFiltered && (close[idx] > open[idx]);
         bearConfirmed = bearFiltered && (close[idx] < open[idx]);
      }
      else
      {
         int bullishBars = 0;
         int bearishBars = 0;

         for(int i = idx; i < idx + InpConfirmBars && i < ArraySize(close); i++)
         {
            if(close[i] > open[i]) bullishBars++;
            if(close[i] < open[i]) bearishBars++;
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
//| Create signal label                                               |
//+------------------------------------------------------------------+
void CreateSignalLabel(datetime time, double price, int score, bool isBull, bool highQuality)
{
   string labelName = "RS_Label_" + TimeToString(time, TIME_DATE|TIME_MINUTES);

   // Delete if exists
   ObjectDelete(0, labelName);

   // Create label
   ObjectCreate(0, labelName, OBJ_TEXT, 0, time, price);

   string text = (isBull ? "B " : "S ") + IntegerToString(score);
   if(highQuality) text += " HQ";

   ObjectSetString(0, labelName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, isBull ? InpBullColor : InpBearColor);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, isBull ? ANCHOR_TOP : ANCHOR_BOTTOM);
}

//+------------------------------------------------------------------+
//| Create score panel                                                |
//+------------------------------------------------------------------+
void CreatePanel()
{
   int x = 10;
   int y = 30;
   int width = 180;
   int height = 80;

   // Background
   string bgName = "RS_Panel_BG";
   ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, bgName, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, bgName, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_COLOR, clrGray);
   ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, bgName, OBJPROP_BACK, false);

   // Title
   string titleName = "RS_Panel_Title";
   ObjectCreate(0, titleName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, titleName, OBJPROP_XDISTANCE, x + width/2);
   ObjectSetInteger(0, titleName, OBJPROP_YDISTANCE, y + 5);
   ObjectSetString(0, titleName, OBJPROP_TEXT, "REVERSAL SCORE");
   ObjectSetInteger(0, titleName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, titleName, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, titleName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, titleName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, titleName, OBJPROP_ANCHOR, ANCHOR_CENTER);

   // Bull label
   string bullLabelName = "RS_Panel_BullLabel";
   ObjectCreate(0, bullLabelName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bullLabelName, OBJPROP_XDISTANCE, x + width - 45);
   ObjectSetInteger(0, bullLabelName, OBJPROP_YDISTANCE, y + 30);
   ObjectSetString(0, bullLabelName, OBJPROP_TEXT, "BULL");
   ObjectSetInteger(0, bullLabelName, OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, bullLabelName, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, bullLabelName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, bullLabelName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);

   // Bear label
   string bearLabelName = "RS_Panel_BearLabel";
   ObjectCreate(0, bearLabelName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bearLabelName, OBJPROP_XDISTANCE, x + 45);
   ObjectSetInteger(0, bearLabelName, OBJPROP_YDISTANCE, y + 30);
   ObjectSetString(0, bearLabelName, OBJPROP_TEXT, "BEAR");
   ObjectSetInteger(0, bearLabelName, OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, bearLabelName, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, bearLabelName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, bearLabelName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);

   // Bull score
   string bullScoreName = "RS_Panel_BullScore";
   ObjectCreate(0, bullScoreName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bullScoreName, OBJPROP_XDISTANCE, x + width - 45);
   ObjectSetInteger(0, bullScoreName, OBJPROP_YDISTANCE, y + 50);
   ObjectSetString(0, bullScoreName, OBJPROP_TEXT, "0 / 10");
   ObjectSetInteger(0, bullScoreName, OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, bullScoreName, OBJPROP_FONTSIZE, 12);
   ObjectSetString(0, bullScoreName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, bullScoreName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);

   // Bear score
   string bearScoreName = "RS_Panel_BearScore";
   ObjectCreate(0, bearScoreName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bearScoreName, OBJPROP_XDISTANCE, x + 45);
   ObjectSetInteger(0, bearScoreName, OBJPROP_YDISTANCE, y + 50);
   ObjectSetString(0, bearScoreName, OBJPROP_TEXT, "0 / 10");
   ObjectSetInteger(0, bearScoreName, OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, bearScoreName, OBJPROP_FONTSIZE, 12);
   ObjectSetString(0, bearScoreName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, bearScoreName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
}

//+------------------------------------------------------------------+
//| Update score panel                                                |
//+------------------------------------------------------------------+
void UpdatePanel(int bullScore, int bearScore)
{
   string bullScoreName = "RS_Panel_BullScore";
   string bearScoreName = "RS_Panel_BearScore";

   ObjectSetString(0, bullScoreName, OBJPROP_TEXT, IntegerToString(bullScore) + " / 10");
   ObjectSetString(0, bearScoreName, OBJPROP_TEXT, IntegerToString(bearScore) + " / 10");

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Send alerts                                                       |
//+------------------------------------------------------------------+
void SendAlert(string direction, int score, bool highQuality)
{
   string hqText = highQuality ? " [HIGH QUALITY]" : "";
   string message = StringFormat("%s: %s Reversal Signal! Score: %d/10%s",
                                 _Symbol, direction, score, hqText);

   if(InpAlertPopup)
      Alert(message);

   if(InpAlertSound)
      PlaySound("alert.wav");

   if(InpAlertPush)
      SendNotification(message);

   if(InpAlertEmail)
      SendMail("Reversal Score Alert - " + _Symbol, message);
}
//+------------------------------------------------------------------+
