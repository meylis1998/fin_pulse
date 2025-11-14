import 'dart:math' as math;

/// Technical Analysis Service
///
/// Implements financial technical indicators:
/// - Moving Averages (SMA, EMA)
/// - Momentum Indicators (RSI)
/// - Trend Indicators (MACD)
/// - Volatility Indicators (Bollinger Bands, ATR)
class TechnicalAnalysisService {
  /// Calculate Simple Moving Average (SMA)
  ///
  /// [prices] - List of price data
  /// [period] - Period for calculation (e.g., 20, 50, 200)
  List<double?> calculateSMA(List<double> prices, int period) {
    if (prices.length < period) {
      return List.filled(prices.length, null);
    }

    final sma = <double?>[];

    for (int i = 0; i < prices.length; i++) {
      if (i < period - 1) {
        sma.add(null);
      } else {
        double sum = 0;
        for (int j = 0; j < period; j++) {
          sum += prices[i - j];
        }
        sma.add(sum / period);
      }
    }

    return sma;
  }

  /// Calculate Exponential Moving Average (EMA)
  ///
  /// [prices] - List of price data
  /// [period] - Period for calculation (e.g., 12, 26)
  List<double?> calculateEMA(List<double> prices, int period) {
    if (prices.isEmpty) return [];
    if (prices.length < period) {
      return List.filled(prices.length, null);
    }

    final ema = <double?>[];
    final multiplier = 2.0 / (period + 1);

    // First EMA is SMA
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += prices[i];
      if (i < period - 1) {
        ema.add(null);
      }
    }
    ema.add(sum / period);

    // Subsequent EMAs
    for (int i = period; i < prices.length; i++) {
      final currentEma = (prices[i] - ema.last!) * multiplier + ema.last!;
      ema.add(currentEma);
    }

    return ema;
  }

  /// Calculate Relative Strength Index (RSI)
  ///
  /// [prices] - List of closing prices
  /// [period] - Period for calculation (typically 14)
  List<double?> calculateRSI(List<double> prices, {int period = 14}) {
    if (prices.length < period + 1) {
      return List.filled(prices.length, null);
    }

    final rsi = <double?>[];
    final gains = <double>[];
    final losses = <double>[];

    // Calculate price changes
    for (int i = 1; i < prices.length; i++) {
      final change = prices[i] - prices[i - 1];
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? change.abs() : 0);
    }

    // First RSI calculation uses SMA
    double avgGain = 0;
    double avgLoss = 0;

    for (int i = 0; i < period; i++) {
      avgGain += gains[i];
      avgLoss += losses[i];
      rsi.add(null);
    }

    avgGain /= period;
    avgLoss /= period;

    // First RSI value
    if (avgLoss == 0) {
      rsi.add(100);
    } else {
      final rs = avgGain / avgLoss;
      rsi.add(100 - (100 / (1 + rs)));
    }

    // Subsequent RSI values using EMA
    for (int i = period; i < gains.length; i++) {
      avgGain = ((avgGain * (period - 1)) + gains[i]) / period;
      avgLoss = ((avgLoss * (period - 1)) + losses[i]) / period;

      if (avgLoss == 0) {
        rsi.add(100);
      } else {
        final rs = avgGain / avgLoss;
        rsi.add(100 - (100 / (1 + rs)));
      }
    }

    return rsi;
  }

  /// Calculate MACD (Moving Average Convergence Divergence)
  ///
  /// Returns a map with 'macd', 'signal', and 'histogram' keys
  Map<String, List<double?>> calculateMACD(
    List<double> prices, {
    int fastPeriod = 12,
    int slowPeriod = 26,
    int signalPeriod = 9,
  }) {
    final fastEMA = calculateEMA(prices, fastPeriod);
    final slowEMA = calculateEMA(prices, slowPeriod);

    // Calculate MACD line (fast EMA - slow EMA)
    final macdLine = <double?>[];
    for (int i = 0; i < prices.length; i++) {
      if (fastEMA[i] == null || slowEMA[i] == null) {
        macdLine.add(null);
      } else {
        macdLine.add(fastEMA[i]! - slowEMA[i]!);
      }
    }

    // Calculate signal line (EMA of MACD line)
    final nonNullMacd = macdLine.whereType<double>().toList();
    final signalEMA = calculateEMA(nonNullMacd, signalPeriod);

    // Pad signal line to match original length
    final signalLine = <double?>[];
    int signalIndex = 0;
    for (int i = 0; i < macdLine.length; i++) {
      if (macdLine[i] == null) {
        signalLine.add(null);
      } else {
        signalLine.add(
            signalIndex < signalEMA.length ? signalEMA[signalIndex] : null);
        signalIndex++;
      }
    }

    // Calculate histogram (MACD - Signal)
    final histogram = <double?>[];
    for (int i = 0; i < prices.length; i++) {
      if (macdLine[i] == null || signalLine[i] == null) {
        histogram.add(null);
      } else {
        histogram.add(macdLine[i]! - signalLine[i]!);
      }
    }

    return {
      'macd': macdLine,
      'signal': signalLine,
      'histogram': histogram,
    };
  }

  /// Calculate Bollinger Bands
  ///
  /// Returns a map with 'upper', 'middle', and 'lower' keys
  Map<String, List<double?>> calculateBollingerBands(
    List<double> prices, {
    int period = 20,
    double stdDevMultiplier = 2.0,
  }) {
    final sma = calculateSMA(prices, period);
    final upper = <double?>[];
    final lower = <double?>[];

    for (int i = 0; i < prices.length; i++) {
      if (sma[i] == null) {
        upper.add(null);
        lower.add(null);
      } else {
        // Calculate standard deviation
        double sumSquaredDiff = 0;
        for (int j = 0; j < period; j++) {
          final diff = prices[i - j] - sma[i]!;
          sumSquaredDiff += diff * diff;
        }
        final stdDev = math.sqrt(sumSquaredDiff / period);

        upper.add(sma[i]! + (stdDevMultiplier * stdDev));
        lower.add(sma[i]! - (stdDevMultiplier * stdDev));
      }
    }

    return {
      'upper': upper,
      'middle': sma,
      'lower': lower,
    };
  }

  /// Calculate Average True Range (ATR)
  ///
  /// [high] - List of high prices
  /// [low] - List of low prices
  /// [close] - List of closing prices
  /// [period] - Period for calculation (typically 14)
  List<double?> calculateATR({
    required List<double> high,
    required List<double> low,
    required List<double> close,
    int period = 14,
  }) {
    if (high.length != low.length || low.length != close.length) {
      throw ArgumentError('All price lists must have the same length');
    }

    if (high.length < period + 1) {
      return List.filled(high.length, null);
    }

    final trueRanges = <double>[];

    // First TR is just high - low
    trueRanges.add(high[0] - low[0]);

    // Subsequent TRs
    for (int i = 1; i < high.length; i++) {
      final tr1 = high[i] - low[i];
      final tr2 = (high[i] - close[i - 1]).abs();
      final tr3 = (low[i] - close[i - 1]).abs();
      trueRanges.add(math.max(tr1, math.max(tr2, tr3)));
    }

    // Calculate ATR using SMA for first value, then EMA
    final atr = <double?>[];

    // Pad with nulls
    for (int i = 0; i < period - 1; i++) {
      atr.add(null);
    }

    // First ATR is SMA of TR
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += trueRanges[i];
    }
    atr.add(sum / period);

    // Subsequent ATRs using EMA
    for (int i = period; i < trueRanges.length; i++) {
      final currentATR = ((atr.last! * (period - 1)) + trueRanges[i]) / period;
      atr.add(currentATR);
    }

    return atr;
  }

  /// Identify Golden Cross (bullish signal)
  ///
  /// Returns true when fast MA crosses above slow MA
  bool detectGoldenCross(
    List<double?> fastMA,
    List<double?> slowMA,
    int index,
  ) {
    if (index < 1) return false;
    if (fastMA[index] == null || slowMA[index] == null) return false;
    if (fastMA[index - 1] == null || slowMA[index - 1] == null) return false;

    return fastMA[index - 1]! < slowMA[index - 1]! &&
        fastMA[index]! > slowMA[index]!;
  }

  /// Identify Death Cross (bearish signal)
  ///
  /// Returns true when fast MA crosses below slow MA
  bool detectDeathCross(
    List<double?> fastMA,
    List<double?> slowMA,
    int index,
  ) {
    if (index < 1) return false;
    if (fastMA[index] == null || slowMA[index] == null) return false;
    if (fastMA[index - 1] == null || slowMA[index - 1] == null) return false;

    return fastMA[index - 1]! > slowMA[index - 1]! &&
        fastMA[index]! < slowMA[index]!;
  }

  /// Detect RSI overbought/oversold conditions
  Map<String, bool> detectRSIConditions(double? rsi) {
    if (rsi == null) {
      return {'overbought': false, 'oversold': false};
    }

    return {
      'overbought': rsi > 70,
      'oversold': rsi < 30,
    };
  }
}
