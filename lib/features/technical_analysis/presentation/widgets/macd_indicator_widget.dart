import 'package:fin_pulse/shared/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// MACD (Moving Average Convergence Divergence) indicator chart widget
class MACDIndicatorWidget extends StatelessWidget {
  final List<double?> macdLine;
  final List<double?> signalLine;
  final List<double?> histogram;
  final List<DateTime>? timestamps;

  const MACDIndicatorWidget({
    super.key,
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
    this.timestamps,
  });

  @override
  Widget build(BuildContext context) {
    if (macdLine.isEmpty || signalLine.isEmpty || histogram.isEmpty) {
      return const Center(child: Text('No MACD data available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text(
                'MACD (12, 26, 9)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              _buildLegendItem('MACD', AppColors.macdLine),
              const SizedBox(width: 8),
              _buildLegendItem('Signal', AppColors.macdSignal),
              const SizedBox(width: 8),
              _buildLegendItem('Histogram', AppColors.macdHistogram),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildMACDChart(),
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
          height: 2,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildMACDChart() {
    // Find min/max values for scaling
    final allValues = <double>[];
    allValues.addAll(macdLine.whereType<double>());
    allValues.addAll(signalLine.whereType<double>());
    allValues.addAll(histogram.whereType<double>());

    if (allValues.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final padding = range * 0.1;

    // Create histogram bars
    final histogramBars = <BarChartGroupData>[];
    for (int i = 0; i < histogram.length; i++) {
      if (histogram[i] != null) {
        final value = histogram[i]!;
        histogramBars.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: value,
                fromY: 0,
                color: value >= 0 ? AppColors.bullish : AppColors.bearish,
                width: 2,
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
        );
      }
    }

    return Stack(
      children: [
        // Histogram (background)
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            minY: minValue - padding,
            maxY: maxValue + padding,
            barGroups: histogramBars,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: range / 5,
              getDrawingHorizontalLine: (value) {
                if (value == 0) {
                  return FlLine(
                    color: Colors.grey,
                    strokeWidth: 1,
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
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        value.toStringAsFixed(2),
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
            barTouchData: BarTouchData(enabled: false),
          ),
        ),
        // MACD and Signal lines (foreground)
        LineChart(
          LineChartData(
            minY: minValue - padding,
            maxY: maxValue + padding,
            minX: -0.5,
            maxX: macdLine.length - 0.5,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              // MACD line
              _buildLine(macdLine, AppColors.macdLine),
              // Signal line
              _buildLine(signalLine, AppColors.macdSignal),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  if (touchedSpots.isEmpty) return [];
                  final index = touchedSpots.first.spotIndex;

                  final macdValue = macdLine[index];
                  final signalValue = signalLine[index];
                  final histValue = histogram[index];

                  return [
                    LineTooltipItem(
                      'MACD: ${macdValue?.toStringAsFixed(4) ?? 'N/A'}\n'
                      'Signal: ${signalValue?.toStringAsFixed(4) ?? 'N/A'}\n'
                      'Histogram: ${histValue?.toStringAsFixed(4) ?? 'N/A'}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ];
                },
              ),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: 0,
                  color: Colors.grey,
                  strokeWidth: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildLine(List<double?> values, Color color) {
    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      if (values[i] != null) {
        spots.add(FlSpot(i.toDouble(), values[i]!));
      }
    }

    return LineChartBarData(
      spots: spots,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}
