import 'package:fin_pulse/features/market_data/domain/entities/candlestick.dart';
import 'package:fin_pulse/shared/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Candlestick chart widget with technical indicator overlays
class CandlestickChart extends StatefulWidget {
  final List<Candlestick> candles;
  final List<double?>? sma20;
  final List<double?>? sma50;
  final List<double?>? ema12;
  final List<double?>? ema26;
  final Map<String, List<double?>>? bollingerBands;
  final bool showVolume;
  final String timeframe;

  const CandlestickChart({
    super.key,
    required this.candles,
    this.sma20,
    this.sma50,
    this.ema12,
    this.ema26,
    this.bollingerBands,
    this.showVolume = true,
    this.timeframe = '1D',
  });

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart> {
  double _chartHeight = 0.7;

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final prices =
        widget.candles.map((c) => [c.low, c.high]).expand((e) => e).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    final maxVolume = widget.candles
        .map((c) => c.volume)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      children: [
        // Main price chart
        Expanded(
          flex: (widget.showVolume ? _chartHeight * 100 : 100).toInt(),
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 16),
            child: LineChart(
              _buildMainChartData(minPrice, maxPrice, priceRange),
              duration: const Duration(milliseconds: 150),
            ),
          ),
        ),

        // Volume chart
        if (widget.showVolume)
          Expanded(
            flex: ((1 - _chartHeight) * 100).toInt(),
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 8),
              child: BarChart(
                _buildVolumeChartData(maxVolume),
                duration: const Duration(milliseconds: 150),
              ),
            ),
          ),
      ],
    );
  }

  LineChartData _buildMainChartData(
      double minPrice, double maxPrice, double priceRange) {
    final candleBars = <CandlestickBar>[];

    for (int i = 0; i < widget.candles.length; i++) {
      final candle = widget.candles[i];
      candleBars.add(CandlestickBar(
        x: i.toDouble(),
        open: candle.open,
        high: candle.high,
        low: candle.low,
        close: candle.close,
        isBullish: candle.isBullish,
      ));
    }

    return LineChartData(
      minY: minPrice - (priceRange * 0.1),
      maxY: maxPrice + (priceRange * 0.1),
      minX: -0.5,
      maxX: widget.candles.length - 0.5,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: priceRange / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  '\$${value.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval:
                widget.candles.length > 30 ? widget.candles.length / 6 : 5,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < 0 || value.toInt() >= widget.candles.length) {
                return const SizedBox();
              }
              final date = widget.candles[value.toInt()].timestamp;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${date.month}/${date.day}',
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        // SMA 20
        if (widget.sma20 != null)
          _buildIndicatorLine(widget.sma20!, AppColors.sma20),
        // SMA 50
        if (widget.sma50 != null)
          _buildIndicatorLine(widget.sma50!, AppColors.sma50),
        // EMA 12
        if (widget.ema12 != null)
          _buildIndicatorLine(widget.ema12!, AppColors.ema12),
        // EMA 26
        if (widget.ema26 != null)
          _buildIndicatorLine(widget.ema26!, AppColors.ema26),
        // Bollinger Bands
        if (widget.bollingerBands != null) ...[
          _buildIndicatorLine(
              widget.bollingerBands!['upper']!, AppColors.bollingerBand),
          _buildIndicatorLine(
              widget.bollingerBands!['middle']!, AppColors.sma20),
          _buildIndicatorLine(
              widget.bollingerBands!['lower']!, AppColors.bollingerBand),
        ],
      ],
      extraLinesData: ExtraLinesData(
        horizontalLines: candleBars.map((bar) {
          return HorizontalLine(
            y: bar.high,
            color: Colors.transparent,
            strokeWidth: 0,
            label: HorizontalLineLabel(
              show: false,
            ),
          );
        }).toList(),
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return [];
            final index = touchedSpots.first.x.toInt();
            if (index < 0 || index >= widget.candles.length) return [];

            final candle = widget.candles[index];
            return [
              LineTooltipItem(
                'O: \$${candle.open.toStringAsFixed(2)}\n'
                'H: \$${candle.high.toStringAsFixed(2)}\n'
                'L: \$${candle.low.toStringAsFixed(2)}\n'
                'C: \$${candle.close.toStringAsFixed(2)}\n'
                'V: ${_formatVolume(candle.volume)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ];
          },
        ),
      ),
      showingTooltipIndicators: [],
      betweenBarsData: candleBars.map((bar) {
        return BetweenBarsData(
          fromIndex: bar.x.toInt(),
          toIndex: bar.x.toInt(),
          color: Colors.transparent,
        );
      }).toList(),
    );
  }

  LineChartBarData _buildIndicatorLine(List<double?> values, Color color) {
    final spots = <FlSpot>[];
    for (int i = 0; i < values.length && i < widget.candles.length; i++) {
      if (values[i] != null) {
        spots.add(FlSpot(i.toDouble(), values[i]!));
      }
    }

    return LineChartBarData(
      spots: spots,
      color: color,
      barWidth: 1.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  BarChartData _buildVolumeChartData(double maxVolume) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxVolume * 1.2,
      barGroups: widget.candles.asMap().entries.map((entry) {
        final index = entry.key;
        final candle = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: candle.volume.toDouble(),
              color: candle.isBullish
                  ? AppColors.candleGreen.withOpacity(0.5)
                  : AppColors.candleRed.withOpacity(0.5),
              width: 2,
              borderRadius: BorderRadius.zero,
            ),
          ],
        );
      }).toList(),
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(enabled: false),
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(2)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(2)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(2)}K';
    }
    return volume.toString();
  }
}

/// Custom data class for candlestick bars
class CandlestickBar {
  final double x;
  final double open;
  final double high;
  final double low;
  final double close;
  final bool isBullish;

  CandlestickBar({
    required this.x,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.isBullish,
  });
}
