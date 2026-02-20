//+------------------------------------------------------------------+
//|                                     Reversal_Score_Indicator.mq5 |
//|                         Reversal Score [10] - PRO v6 Indicator   |
//|                     10 Indicator Weighted Scoring System         |
//+------------------------------------------------------------------+
#property copyright "Reversal Score Indicator"
#property link      ""
#property version   "2.00"
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

input group "=== FİLTRELER (OPSİYONEL) ==="
input int      InpMALen             = 50;      // Trend MA Periyot
input int      InpATRLen            = 14;      // ATR Periyot
input bool     InpUseContextFilter  = false;   // Context Filtresi (Counter-trend)
input bool     InpUseOverextFilter  = false;   // Overextension Filtresi
input double   InpATRMult           = 1.2;     // Overextension ATR Çarpanı
input bool     InpUseADXFilter      = false;   // ADX Filtresi Kullan
input int      InpADXLen            = 14;      // ADX Periyot
input double   InpADXThreshold      = 28.0;    // ADX Eşik (üstü güçlü trend)
input int      InpPivotLen          = 5;       // Diverjans Pivot Periyot

input group "=== KONFİRMASYON / SPAM ÖNLEME ==="
input bool     InpRequireConfirm    = false;   // Konfirmasyon Gerekli
input int      InpConfirmBars       = 2;       // Konfirmasyon Bar Sayısı
input int      InpCooldownBars      = 3;       // Cooldown Bar Sayısı
input bool     InpResolveConflict   = true;    // Bull/Bear Çatışma Çöz

input group "=== GÖRSEL AYARLAR ==="
input bool     InpShowLabels        = true;    // Skor Etiketi Göster
input bool     InpShowPanel         = true;    // Skor Paneli Göster
input bool     InpShowBB            = true;    // Bollinger Bands Göster
input bool     InpShowMA            = true;    // Trend MA Göster
input color    InpBullColor         = clrLime; // Bull Sinyal Rengi
input color    InpBearColor         = clrRed;  // Bear Sinyal Rengi
input int      InpArrowSize         = 3;       // Ok Boyutu (1-5)
input int      InpMaxLabels         = 50;      // Maksimum Etiket Sayısı

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
double         buf_BullScore[];
double         buf_BearScore[];

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+
int            h_RSI, h_Stoch, h_CCI, h_WR, h_BB, h_MACD, h_MFI, h_MA, h_ATR, h_ADX;
int            g_labelCount = 0;
int            g_lastAlertBar = -1;

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

   // Set indicator name
   IndicatorSetString(INDICATOR_SHORTNAME, "Reversal Score [10] v2");
   IndicatorSetInteger(INDICATOR_DIGITS, 0);

   // Create panel
   if(InpShowPanel)
      CreatePanel();

   Print("Reversal Score Indicator v2.00 initialized");
   Print("Min Score: ", InpMinScore, " | Filters: Context=", InpUseContextFilter,
         " Overext=", InpUseOverextFilter, " ADX=", InpUseADXFilter);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
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
   // Minimum bars check
   int min_bars = MathMax(InpMALen, InpMACDSlow) + 50;
   if(rates_total < min_bars)
      return 0;

   // Copy indicator data
   double ind_RSI[], ind_StochK[], ind_StochD[], ind_CCI[], ind_WR[];
   double ind_BBUpper[], ind_BBMiddle[], ind_BBLower[];
   double ind_MACD[], ind_MACDSignal[], ind_MFI[], ind_MA[], ind_ATR[], ind_ADX[];

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

   int copy_count = rates_total;
   if(CopyBuffer(h_RSI, 0, 0, copy_count, ind_RSI) <= 0) return 0;
   if(CopyBuffer(h_Stoch, 0, 0, copy_count, ind_StochK) <= 0) return 0;
   if(CopyBuffer(h_Stoch, 1, 0, copy_count, ind_StochD) <= 0) return 0;
   if(CopyBuffer(h_CCI, 0, 0, copy_count, ind_CCI) <= 0) return 0;
   if(CopyBuffer(h_WR, 0, 0, copy_count, ind_WR) <= 0) return 0;
   if(CopyBuffer(h_BB, 1, 0, copy_count, ind_BBUpper) <= 0) return 0;
   if(CopyBuffer(h_BB, 0, 0, copy_count, ind_BBMiddle) <= 0) return 0;
   if(CopyBuffer(h_BB, 2, 0, copy_count, ind_BBLower) <= 0) return 0;
   if(CopyBuffer(h_MACD, 0, 0, copy_count, ind_MACD) <= 0) return 0;
   if(CopyBuffer(h_MACD, 1, 0, copy_count, ind_MACDSignal) <= 0) return 0;
   if(CopyBuffer(h_MFI, 0, 0, copy_count, ind_MFI) <= 0) return 0;
   if(CopyBuffer(h_MA, 0, 0, copy_count, ind_MA) <= 0) return 0;
   if(CopyBuffer(h_ATR, 0, 0, copy_count, ind_ATR) <= 0) return 0;
   if(CopyBuffer(h_ADX, 0, 0, copy_count, ind_ADX) <= 0) return 0;

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

   // Calculate start position
   int start = prev_calculated == 0 ? rates_total - min_bars : rates_total - prev_calculated + 1;
   if(start < 1) start = 1;
   if(start >= rates_total) start = rates_total - 1;

   // Divergence tracking (simple version)
   static double last_pl = 0, prev_pl = 0, last_pl_rsi = 0, prev_pl_rsi = 0;
   static double last_ph = 0, prev_ph = 0, last_ph_rsi = 0, prev_ph_rsi = 0;

   // Track cooldown
   static int lastSignalBar = -100;

   // Main calculation loop
   for(int i = start; i >= 0; i--)
   {
      // Copy display buffers
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
      if(i + 2 >= rates_total) continue;

      //=== CALCULATE 10 INDICATOR SIGNALS ===

      // 1. RSI
      bool bull_1 = ind_RSI[i] <= InpRSIOS;
      bool bear_1 = ind_RSI[i] >= InpRSIOB;

      // 2. Stochastic
      bool bull_2 = (ind_StochK[i] < InpStochOS) && (ind_StochD[i] < InpStochOS);
      bool bear_2 = (ind_StochK[i] > InpStochOB) && (ind_StochD[i] > InpStochOB);

      // 3. CCI
      bool bull_3 = ind_CCI[i] <= -InpCCILevel;
      bool bear_3 = ind_CCI[i] >= InpCCILevel;

      // 4. Williams %R
      bool bull_4 = ind_WR[i] <= -InpWROS;
      bool bear_4 = ind_WR[i] >= -InpWROB;

      // 5. Bollinger Bands (touch + return)
      bool bull_5 = (low[i] < ind_BBLower[i]) && (close[i] > ind_BBLower[i]);
      bool bear_5 = (high[i] > ind_BBUpper[i]) && (close[i] < ind_BBUpper[i]);

      // 6. MACD Cross
      bool macdCrossUp = (ind_MACD[i] > ind_MACDSignal[i]) && (ind_MACD[i+1] <= ind_MACDSignal[i+1]);
      bool macdCrossDown = (ind_MACD[i] < ind_MACDSignal[i]) && (ind_MACD[i+1] >= ind_MACDSignal[i+1]);
      bool bull_6 = macdCrossUp && (ind_MACD[i] < 0);
      bool bear_6 = macdCrossDown && (ind_MACD[i] > 0);

      // 7. MFI
      bool bull_7 = ind_MFI[i] <= InpMFIOS;
      bool bear_7 = ind_MFI[i] >= InpMFIOB;

      // 8. Volume
      double vol = (double)tick_volume[i];
      double volMA = 0;
      for(int v = 0; v < InpVolLen && i + v < rates_total; v++)
         volMA += (double)tick_volume[i + v];
      volMA /= InpVolLen;

      bool volSpike = (volMA > 0) && (vol >= volMA * InpVolMult);
      double volRatio = (volMA > 0) ? vol / volMA : 0;
      bool bull_8 = volSpike && (close[i] > open[i]);
      bool bear_8 = volSpike && (close[i] < open[i]);

      // 9. Divergence (simplified - check last few bars)
      bool bull_9 = false, bear_9 = false;

      // Check for pivot low (bullish divergence)
      if(i + InpPivotLen * 2 < rates_total)
      {
         bool isPivotLow = true;
         double pivotPrice = low[i + InpPivotLen];
         for(int p = 1; p <= InpPivotLen; p++)
         {
            if(low[i + InpPivotLen - p] <= pivotPrice || low[i + InpPivotLen + p] <= pivotPrice)
            {
               isPivotLow = false;
               break;
            }
         }
         if(isPivotLow && prev_pl > 0)
         {
            if(pivotPrice < prev_pl && ind_RSI[i + InpPivotLen] > prev_pl_rsi)
               bull_9 = true;
         }
         if(isPivotLow)
         {
            prev_pl = last_pl;
            prev_pl_rsi = last_pl_rsi;
            last_pl = pivotPrice;
            last_pl_rsi = ind_RSI[i + InpPivotLen];
         }
      }

      // Check for pivot high (bearish divergence)
      if(i + InpPivotLen * 2 < rates_total)
      {
         bool isPivotHigh = true;
         double pivotPrice = high[i + InpPivotLen];
         for(int p = 1; p <= InpPivotLen; p++)
         {
            if(high[i + InpPivotLen - p] >= pivotPrice || high[i + InpPivotLen + p] >= pivotPrice)
            {
               isPivotHigh = false;
               break;
            }
         }
         if(isPivotHigh && prev_ph > 0)
         {
            if(pivotPrice > prev_ph && ind_RSI[i + InpPivotLen] < prev_ph_rsi)
               bear_9 = true;
         }
         if(isPivotHigh)
         {
            prev_ph = last_ph;
            prev_ph_rsi = last_ph_rsi;
            last_ph = pivotPrice;
            last_ph_rsi = ind_RSI[i + InpPivotLen];
         }
      }

      // 10. Candle Patterns
      double body = MathAbs(close[i] - open[i]);
      double range = high[i] - low[i];
      double upperWick = high[i] - MathMax(close[i], open[i]);
      double lowerWick = MathMin(close[i], open[i]) - low[i];

      bool smallBody = (range > 0) && (body <= range * 0.35);
      bool hammer = smallBody && (lowerWick >= body * 2.0) && (upperWick <= body * 0.6);
      bool shootingStar = smallBody && (upperWick >= body * 2.0) && (lowerWick <= body * 0.6);

      bool bullEngulf = (close[i] > open[i]) && (close[i+1] < open[i+1]) &&
                        (close[i] >= open[i+1]) && (open[i] <= close[i+1]);
      bool bearEngulf = (close[i] < open[i]) && (close[i+1] > open[i+1]) &&
                        (close[i] <= open[i+1]) && (open[i] >= close[i+1]);

      bool bull_10 = hammer || bullEngulf;
      bool bear_10 = shootingStar || bearEngulf;

      //=== CALCULATE SCORES ===
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

      int bullScore, bearScore;
      if(InpUseWeighted)
      {
         bullScore = (int)MathRound((double)bullWeighted * 10.0 / maxPossible);
         bearScore = (int)MathRound((double)bearWeighted * 10.0 / maxPossible);
      }
      else
      {
         bullScore = (bull_1?1:0) + (bull_2?1:0) + (bull_3?1:0) + (bull_4?1:0) + (bull_5?1:0) +
                     (bull_6?1:0) + (bull_7?1:0) + (bull_8?1:0) + (bull_9?1:0) + (bull_10?1:0);
         bearScore = (bear_1?1:0) + (bear_2?1:0) + (bear_3?1:0) + (bear_4?1:0) + (bear_5?1:0) +
                     (bear_6?1:0) + (bear_7?1:0) + (bear_8?1:0) + (bear_9?1:0) + (bear_10?1:0);
      }

      buf_BullScore[i] = bullScore;
      buf_BearScore[i] = bearScore;

      //=== APPLY FILTERS ===
      bool bullOK = (bullScore >= InpMinScore);
      bool bearOK = (bearScore >= InpMinScore);

      // Context filter (counter-trend)
      if(InpUseContextFilter)
      {
         bullOK = bullOK && (close[i] < ind_MA[i]);
         bearOK = bearOK && (close[i] > ind_MA[i]);
      }

      // Overextension filter
      if(InpUseOverextFilter)
      {
         bool overext = MathAbs(close[i] - ind_MA[i]) > ind_ATR[i] * InpATRMult;
         bullOK = bullOK && overext;
         bearOK = bearOK && overext;
      }

      // ADX filter
      if(InpUseADXFilter)
      {
         bool momentumOK = ind_ADX[i] <= InpADXThreshold;
         bullOK = bullOK && momentumOK;
         bearOK = bearOK && momentumOK;
      }

      // Confirmation filter
      if(InpRequireConfirm)
      {
         if(InpConfirmBars == 1)
         {
            bullOK = bullOK && (close[i] > open[i]);
            bearOK = bearOK && (close[i] < open[i]);
         }
         else
         {
            int bullishCount = 0, bearishCount = 0;
            for(int c = 0; c < InpConfirmBars && i + c < rates_total; c++)
            {
               if(close[i + c] > open[i + c]) bullishCount++;
               if(close[i + c] < open[i + c]) bearishCount++;
            }
            bullOK = bullOK && (bullishCount >= (int)(InpConfirmBars * 0.67));
            bearOK = bearOK && (bearishCount >= (int)(InpConfirmBars * 0.67));
         }
      }

      // Resolve conflict
      if(InpResolveConflict && bullOK && bearOK)
      {
         bullOK = bullScore > bearScore;
         bearOK = bearScore > bullScore;
      }

      // Cooldown check
      int barIndex = rates_total - 1 - i;
      bool canFire = (InpCooldownBars == 0) || (barIndex - lastSignalBar > InpCooldownBars);

      //=== GENERATE SIGNALS ===
      if(canFire)
      {
         if(bullOK)
         {
            buf_BullSignal[i] = low[i] - ind_ATR[i] * 0.5;
            lastSignalBar = barIndex;

            // Create label
            if(InpShowLabels && g_labelCount < InpMaxLabels)
            {
               string labelName = "RS_L_" + IntegerToString(barIndex);
               ObjectCreate(0, labelName, OBJ_TEXT, 0, time[i], buf_BullSignal[i] - ind_ATR[i] * 0.3);
               ObjectSetString(0, labelName, OBJPROP_TEXT, "B" + IntegerToString(bullScore));
               ObjectSetInteger(0, labelName, OBJPROP_COLOR, InpBullColor);
               ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 9);
               ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Bold");
               ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_TOP);
               g_labelCount++;
            }

            // Alert for current bar only
            if(i == 0 && barIndex != g_lastAlertBar)
            {
               SendAlert("BULL", bullScore, bullScore >= InpHighScoreMin);
               g_lastAlertBar = barIndex;
            }
         }
         else if(bearOK)
         {
            buf_BearSignal[i] = high[i] + ind_ATR[i] * 0.5;
            lastSignalBar = barIndex;

            // Create label
            if(InpShowLabels && g_labelCount < InpMaxLabels)
            {
               string labelName = "RS_L_" + IntegerToString(barIndex);
               ObjectCreate(0, labelName, OBJ_TEXT, 0, time[i], buf_BearSignal[i] + ind_ATR[i] * 0.3);
               ObjectSetString(0, labelName, OBJPROP_TEXT, "S" + IntegerToString(bearScore));
               ObjectSetInteger(0, labelName, OBJPROP_COLOR, InpBearColor);
               ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 9);
               ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Bold");
               ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
               g_labelCount++;
            }

            // Alert for current bar only
            if(i == 0 && barIndex != g_lastAlertBar)
            {
               SendAlert("BEAR", bearScore, bearScore >= InpHighScoreMin);
               g_lastAlertBar = barIndex;
            }
         }
      }
   }

   // Update panel with latest scores
   if(InpShowPanel)
      UpdatePanel((int)buf_BullScore[0], (int)buf_BearScore[0]);

   return rates_total;
}

//+------------------------------------------------------------------+
//| Create score panel                                                |
//+------------------------------------------------------------------+
void CreatePanel()
{
   int x = 10, y = 30, w = 180, h = 80;

   ObjectCreate(0, "RS_PanelBG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "RS_PanelBG", OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, "RS_PanelBG", OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, "RS_PanelBG", OBJPROP_XSIZE, w);
   ObjectSetInteger(0, "RS_PanelBG", OBJPROP_YSIZE, h);
   ObjectSetInteger(0, "RS_PanelBG", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, "RS_PanelBG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "RS_PanelBG", OBJPROP_CORNER, CORNER_RIGHT_UPPER);

   ObjectCreate(0, "RS_Title", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "RS_Title", OBJPROP_XDISTANCE, x + w/2);
   ObjectSetInteger(0, "RS_Title", OBJPROP_YDISTANCE, y + 8);
   ObjectSetString(0, "RS_Title", OBJPROP_TEXT, "REVERSAL SCORE");
   ObjectSetInteger(0, "RS_Title", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "RS_Title", OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, "RS_Title", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "RS_Title", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, "RS_Title", OBJPROP_ANCHOR, ANCHOR_CENTER);

   ObjectCreate(0, "RS_BullLbl", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "RS_BullLbl", OBJPROP_XDISTANCE, x + w - 50);
   ObjectSetInteger(0, "RS_BullLbl", OBJPROP_YDISTANCE, y + 30);
   ObjectSetString(0, "RS_BullLbl", OBJPROP_TEXT, "BULL");
   ObjectSetInteger(0, "RS_BullLbl", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, "RS_BullLbl", OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, "RS_BullLbl", OBJPROP_CORNER, CORNER_RIGHT_UPPER);

   ObjectCreate(0, "RS_BearLbl", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "RS_BearLbl", OBJPROP_XDISTANCE, x + 50);
   ObjectSetInteger(0, "RS_BearLbl", OBJPROP_YDISTANCE, y + 30);
   ObjectSetString(0, "RS_BearLbl", OBJPROP_TEXT, "BEAR");
   ObjectSetInteger(0, "RS_BearLbl", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "RS_BearLbl", OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, "RS_BearLbl", OBJPROP_CORNER, CORNER_RIGHT_UPPER);

   ObjectCreate(0, "RS_BullVal", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "RS_BullVal", OBJPROP_XDISTANCE, x + w - 50);
   ObjectSetInteger(0, "RS_BullVal", OBJPROP_YDISTANCE, y + 52);
   ObjectSetString(0, "RS_BullVal", OBJPROP_TEXT, "0 / 10");
   ObjectSetInteger(0, "RS_BullVal", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, "RS_BullVal", OBJPROP_FONTSIZE, 12);
   ObjectSetString(0, "RS_BullVal", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "RS_BullVal", OBJPROP_CORNER, CORNER_RIGHT_UPPER);

   ObjectCreate(0, "RS_BearVal", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "RS_BearVal", OBJPROP_XDISTANCE, x + 50);
   ObjectSetInteger(0, "RS_BearVal", OBJPROP_YDISTANCE, y + 52);
   ObjectSetString(0, "RS_BearVal", OBJPROP_TEXT, "0 / 10");
   ObjectSetInteger(0, "RS_BearVal", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "RS_BearVal", OBJPROP_FONTSIZE, 12);
   ObjectSetString(0, "RS_BearVal", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "RS_BearVal", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
}

//+------------------------------------------------------------------+
//| Update score panel                                                |
//+------------------------------------------------------------------+
void UpdatePanel(int bullScore, int bearScore)
{
   ObjectSetString(0, "RS_BullVal", OBJPROP_TEXT, IntegerToString(bullScore) + " / 10");
   ObjectSetString(0, "RS_BearVal", OBJPROP_TEXT, IntegerToString(bearScore) + " / 10");
}

//+------------------------------------------------------------------+
//| Send alerts                                                       |
//+------------------------------------------------------------------+
void SendAlert(string direction, int score, bool highQuality)
{
   string hq = highQuality ? " [HQ]" : "";
   string msg = StringFormat("%s: %s Signal! Score: %d/10%s", _Symbol, direction, score, hq);

   if(InpAlertPopup) Alert(msg);
   if(InpAlertSound) PlaySound("alert.wav");
   if(InpAlertPush) SendNotification(msg);
   if(InpAlertEmail) SendMail("Reversal Score - " + _Symbol, msg);
}
//+------------------------------------------------------------------+
