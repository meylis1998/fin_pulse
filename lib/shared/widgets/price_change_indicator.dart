import 'package:fin_pulse/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Widget to display price change with colored indicator
class PriceChangeIndicator extends StatelessWidget {
  final double change;
  final double changePercent;
  final bool showPercentage;
  final TextStyle? textStyle;
  final double? size;

  const PriceChangeIndicator({
    super.key,
    required this.change,
    required this.changePercent,
    this.showPercentage = true,
    this.textStyle,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final color = isPositive
        ? AppColors.bullish
        : (change == 0 ? AppColors.neutral : AppColors.bearish);

    final icon = isPositive
        ? Icons.arrow_drop_up
        : (change == 0 ? Icons.remove : Icons.arrow_drop_down);

    final fontSize = size ?? 14;
    final iconSize = (size ?? 14) + 6;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: iconSize),
        const SizedBox(width: 4),
        Text(
          showPercentage
              ? '${changePercent.abs().toStringAsFixed(2)}%'
              : '\$${change.abs().toStringAsFixed(2)}',
          style: (textStyle ?? TextStyle(fontSize: fontSize)).copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
