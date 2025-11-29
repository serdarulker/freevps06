# RSI + SuperTrend Trading Strategy

## Overview
This is a professional trading strategy combining RSI (Relative Strength Index) and SuperTrend indicators, optimized for BTC trading on 45-minute timeframe.

## Strategy Components

### 1. SuperTrend Indicator
- **ATR Period**: 10
- **Multiplier**: 3.0
- **Function**: Identifies trend direction
  - Green line = Uptrend
  - Red line = Downtrend

### 2. RSI (Relative Strength Index)
- **Period**: 14
- **Overbought Level**: 70
- **Oversold Level**: 30
- **Function**: Identifies momentum and potential reversal points

## Entry Signals

### Long Entry (BUY)
- RSI crosses above 30 (exits oversold zone)
- AND SuperTrend is bullish (trend = 1)

### Short Entry (SELL)
- RSI crosses below 70 (exits overbought zone)
- AND SuperTrend is bearish (trend = -1)

## Risk Management

### Position Sizing
- **Default**: 100% of equity
- **Pyramiding**: 1 (allows one additional position)

### Exit Strategy
- **Take Profit**: 1.8% from entry
- **Stop Loss**: 0.9% from entry
- **Risk/Reward Ratio**: 1:2

## Visual Features

The strategy includes comprehensive visual indicators:

1. **Background Colors**
   - Light green: Long position active
   - Light red: Short position active
   - Highlighted green: Buy signal triggered
   - Highlighted red: Sell signal triggered

2. **Labels & Arrows**
   - "AL" (Buy) labels below bars
   - "SAT" (Sell) labels above bars
   - Directional arrows for signal confirmation

3. **Price Lines**
   - Yellow line: Entry price
   - Green lines: Take profit levels
   - Red lines: Stop loss levels

## Alert Conditions

The strategy includes built-in alerts:
- **Buy Alert**: "BTCUSDT 45m → RSI+SuperTrend AL!"
- **Sell Alert**: "BTCUSDT 45m → RSI+SuperTrend SAT!"

## Configuration Options

All parameters can be adjusted via inputs:

| Parameter | Default | Description |
|-----------|---------|-------------|
| RSI Period | 14 | RSI calculation period |
| RSI Overbought | 70 | Upper threshold |
| RSI Oversold | 30 | Lower threshold |
| ATR Period | 10 | SuperTrend ATR period |
| ATR Multiplier | 3.0 | SuperTrend sensitivity |
| Take Profit % | 1.8 | Profit target percentage |
| Stop Loss % | 0.9 | Maximum loss percentage |

## How to Use

1. **In TradingView**:
   - Open Pine Editor
   - Paste the code from `rsi_supertrend_strategy.pine`
   - Click "Add to Chart"
   - Set timeframe to 45 minutes
   - Apply to BTCUSDT pair

2. **Backtesting**:
   - Use Strategy Tester panel
   - Review performance metrics
   - Adjust parameters as needed

3. **Live Trading**:
   - Set up alerts for buy/sell signals
   - Monitor positions actively
   - Follow risk management rules

## Strategy Logic Flow

```
1. Calculate SuperTrend (ATR-based)
2. Calculate RSI (14 periods)
3. Check trend direction
4. Wait for RSI crossover signals
5. Enter position if both conditions met
6. Set TP/SL based on entry price
7. Exit at TP, SL, or opposite signal
```

## Important Notes

- **Optimized for**: BTC 45-minute charts
- **Trading Style**: Momentum + Trend following
- **Best Market Conditions**: Trending markets with clear momentum
- **Avoid**: Ranging/choppy markets
- **Risk Warning**: Always use proper position sizing and risk management

## Performance Optimization

To optimize this strategy:

1. **Backtest** on historical data
2. **Adjust** ATR multiplier for volatility
3. **Fine-tune** RSI levels based on market conditions
4. **Test** different TP/SL ratios
5. **Consider** adding volume filters

## Version
- **Version**: 2025
- **Pine Script Version**: 5
- **Status**: Production Ready

## License
This strategy is provided for educational purposes. Use at your own risk.
