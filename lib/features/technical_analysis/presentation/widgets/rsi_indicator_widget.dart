import 'package:fin_pulse/shared/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// RSI (Relative Strength Index) indicator chart widget
class RSIIndicatorWidget extends StatelessWidget {
  final List<double?> rsiValues;
  final double overboughtLevel;
  final double oversoldLevel;
  final List<DateTime>? timestamps;

  const RSIIndicatorWidget({
    super.key,
    required this.rsiValues,
    this.overboughtLevel = 70.0,
    this.oversoldLevel = 30.0,
    this.timestamps,
  });

  @override
  Widget build(BuildContext context) {
    if (rsiValues.isEmpty) {
      return const Center(child: Text('No RSI data available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text(
                'RSI (14)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              _buildLegendItem('Overbought (>70)', AppColors.bearish),
              const SizedBox(width: 8),
              _buildLegendItem('Oversold (<30)', AppColors.bullish),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: LineChart(
              _buildRSIChartData(),
              duration: const Duration(milliseconds: 150),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  LineChartData _buildRSIChartData() {
    final spots = <FlSpot>[];

    for (int i = 0; i < rsiValues.length; i++) {
      if (rsiValues[i] != null) {
        spots.add(FlSpot(i.toDouble(), rsiValues[i]!));
      }
    }

    // Get current RSI value
    final currentRSI = rsiValues.whereType<double>().lastOrNull;
    Color rsiColor = AppColors.primary;
    if (currentRSI != null) {
      if (currentRSI > overboughtLevel) {
        rsiColor = AppColors.bearish;
      } else if (currentRSI < oversoldLevel) {
        rsiColor = AppColors.bullish;
      }
    }

    return LineChartData(
      minY: 0,
      maxY: 100,
      minX: -0.5,
      maxX: rsiValues.length - 0.5,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) {
          if (value == overboughtLevel || value == oversoldLevel) {
            return FlLine(
              color: value == overboughtLevel
                  ? AppColors.bearish.withOpacity(0.5)
                  : AppColors.bullish.withOpacity(0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          }
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
            reservedSize: 40,
            interval: 20,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          color: rsiColor,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: rsiColor.withOpacity(0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return [];
            final spot = touchedSpots.first;
            return [
              LineTooltipItem(
                'RSI: ${spot.y.toStringAsFixed(2)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ];
          },
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: overboughtLevel,
            color: AppColors.bearish.withOpacity(0.3),
            strokeWidth: 1,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              labelResolver: (line) => '70',
              style: const TextStyle(fontSize: 10),
            ),
          ),
          HorizontalLine(
            y: 50,
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          ),
          HorizontalLine(
            y: oversoldLevel,
            color: AppColors.bullish.withOpacity(0.3),
            strokeWidth: 1,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              labelResolver: (line) => '30',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
