import 'package:fin_pulse/features/market_data/domain/entities/stock_quote.dart';
import 'package:fin_pulse/features/market_data/presentation/pages/asset_detail_page.dart';
import 'package:fin_pulse/shared/widgets/price_change_indicator.dart';
import 'package:flutter/material.dart';

/// Card widget to display stock quote
class StockQuoteCard extends StatelessWidget {
  final StockQuote quote;
  final VoidCallback? onTap;

  const StockQuoteCard({
    super.key,
    required this.quote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssetDetailPage(
                    symbol: quote.symbol,
                    isCrypto: false,
                  ),
                ),
              );
            },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Symbol and price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    quote.symbol,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '\$${quote.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Change indicator
              PriceChangeIndicator(
                change: quote.change,
                changePercent: quote.changePercent,
              ),
              const SizedBox(height: 12),

              // OHLC data
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn(
                    context,
                    'Open',
                    '\$${quote.open.toStringAsFixed(2)}',
                  ),
                  _buildStatColumn(
                    context,
                    'High',
                    '\$${quote.high.toStringAsFixed(2)}',
                  ),
                  _buildStatColumn(
                    context,
                    'Low',
                    '\$${quote.low.toStringAsFixed(2)}',
                  ),
                  _buildStatColumn(
                    context,
                    'Vol',
                    _formatVolume(quote.volume),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(1)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }
}
