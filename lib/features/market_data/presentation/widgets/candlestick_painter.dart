import 'package:fin_pulse/features/market_data/domain/entities/candlestick.dart';
import 'package:fin_pulse/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Custom painter for rendering candlestick charts
class CandlestickPainter extends CustomPainter {
  final List<Candlestick> candles;
  final double minPrice;
  final double maxPrice;
  final double candleWidth;
  final double spacing;

  CandlestickPainter({
    required this.candles,
    required this.minPrice,
    required this.maxPrice,
    this.candleWidth = 8.0,
    this.spacing = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final priceRange = maxPrice - minPrice;
    if (priceRange == 0) return;

    final totalWidth = (candleWidth + spacing) * candles.length;
    final scaleFactor = size.width / totalWidth;
    final actualCandleWidth = candleWidth * scaleFactor;
    final actualSpacing = spacing * scaleFactor;

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = i * (actualCandleWidth + actualSpacing) + actualCandleWidth / 2;

      _drawCandle(
        canvas,
        candle,
        x,
        size.height,
        priceRange,
        actualCandleWidth,
      );
    }
  }

  void _drawCandle(
    Canvas canvas,
    Candlestick candle,
    double x,
    double height,
    double priceRange,
    double width,
  ) {
    final isBullish = candle.close > candle.open;
    final color = isBullish ? AppColors.candleGreen : AppColors.candleRed;

    // Calculate positions
    final highY = _priceToY(candle.high, height, priceRange);
    final lowY = _priceToY(candle.low, height, priceRange);
    final openY = _priceToY(candle.open, height, priceRange);
    final closeY = _priceToY(candle.close, height, priceRange);

    final wickPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final bodyPaint = Paint()
      ..color = color
      ..style = isBullish ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = 1.5;

    // Draw wick (high to low)
    canvas.drawLine(
      Offset(x, highY),
      Offset(x, lowY),
      wickPaint,
    );

    // Draw body (open to close)
    final bodyTop = isBullish ? closeY : openY;
    final bodyBottom = isBullish ? openY : closeY;
    final bodyHeight = (bodyBottom - bodyTop).abs();

    if (bodyHeight < 1) {
      // Draw a line for doji (open == close)
      canvas.drawLine(
        Offset(x - width / 2, bodyTop),
        Offset(x + width / 2, bodyTop),
        bodyPaint,
      );
    } else {
      final bodyRect = Rect.fromLTWH(
        x - width / 2,
        bodyTop,
        width,
        bodyHeight,
      );
      canvas.drawRect(bodyRect, bodyPaint);
    }
  }

  double _priceToY(double price, double height, double priceRange) {
    final normalizedPrice = (price - minPrice) / priceRange;
    return height - (normalizedPrice * height * 0.9) - (height * 0.05);
  }

  @override
  bool shouldRepaint(CandlestickPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.minPrice != minPrice ||
        oldDelegate.maxPrice != maxPrice;
  }
}

/// Widget wrapper for candlestick painter
class CandlestickChartWidget extends StatelessWidget {
  final List<Candlestick> candles;
  final double height;

  const CandlestickChartWidget({
    super.key,
    required this.candles,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No data available')),
      );
    }

    final prices =
        candles.map((c) => [c.low, c.high]).expand((e) => e).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: CandlestickPainter(
          candles: candles,
          minPrice: minPrice,
          maxPrice: maxPrice,
        ),
        child: Container(),
      ),
    );
  }
}
