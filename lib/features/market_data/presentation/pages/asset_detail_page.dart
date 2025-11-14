import 'package:fin_pulse/features/market_data/domain/entities/candlestick.dart';
import 'package:fin_pulse/features/market_data/presentation/bloc/market_data_bloc.dart';
import 'package:fin_pulse/features/market_data/presentation/bloc/market_data_event.dart';
import 'package:fin_pulse/features/market_data/presentation/bloc/market_data_state.dart';
import 'package:fin_pulse/features/market_data/presentation/widgets/candlestick_chart.dart';
import 'package:fin_pulse/features/technical_analysis/domain/services/technical_analysis_service.dart';
import 'package:fin_pulse/features/technical_analysis/presentation/widgets/rsi_indicator_widget.dart';
import 'package:fin_pulse/features/technical_analysis/presentation/widgets/macd_indicator_widget.dart';
import 'package:fin_pulse/injection_container.dart';
import 'package:fin_pulse/shared/theme/app_colors.dart';
import 'package:fin_pulse/shared/widgets/loading_shimmer.dart';
import 'package:fin_pulse/shared/widgets/price_change_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Asset Detail Page with candlestick charts and technical analysis
class AssetDetailPage extends StatelessWidget {
  final String symbol;
  final bool isCrypto;

  const AssetDetailPage({
    super.key,
    required this.symbol,
    this.isCrypto = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MarketDataBloc>(
      create: (context) {
        final bloc = sl<MarketDataBloc>();
        bloc.add(
          isCrypto
              ? FetchCryptoQuoteEvent(symbol)
              : FetchStockQuoteEvent(symbol),
        );
        bloc.add(FetchCompanyProfileEvent(symbol));
        return bloc;
      },
      child: _AssetDetailView(symbol: symbol, isCrypto: isCrypto),
    );
  }
}

class _AssetDetailView extends StatefulWidget {
  final String symbol;
  final bool isCrypto;

  const _AssetDetailView({required this.symbol, required this.isCrypto});

  @override
  State<_AssetDetailView> createState() => _AssetDetailViewState();
}

class _AssetDetailViewState extends State<_AssetDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeframe = '1D';
  final _technicalAnalysisService = TechnicalAnalysisService();

  // Technical indicator toggles
  bool _showSMA20 = false;
  bool _showSMA50 = false;
  bool _showEMA = false;
  bool _showBollinger = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.symbol),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_outlined),
            onPressed: () {
              // TODO: Add price alert
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share asset
            },
          ),
        ],
      ),
      body: BlocBuilder<MarketDataBloc, MarketDataState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // Price header
              SliverToBoxAdapter(child: _buildPriceHeader(context, state)),

              // Chart section
              SliverToBoxAdapter(child: _buildChartSection(context, state)),

              // Tabs for details
              SliverToBoxAdapter(
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Statistics'),
                    Tab(text: 'News'),
                  ],
                ),
              ),

              // Tab content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(context, state),
                    _buildStatisticsTab(context, state),
                    _buildNewsTab(context, state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPriceHeader(BuildContext context, MarketDataState state) {
    if (state is StockQuoteLoaded) {
      final quote = state.quote;
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quote.symbol,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$${quote.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                PriceChangeIndicator(
                  change: quote.change,
                  changePercent: quote.changePercent,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (state is CryptoQuoteLoaded) {
      final quote = state.quote;
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quote.name,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              quote.symbol.toUpperCase(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$${quote.currentPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                PriceChangeIndicator(
                  change: quote.priceChange24h,
                  changePercent: quote.priceChangePercentage24h,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return const Padding(padding: EdgeInsets.all(16.0), child: CardShimmer());
  }

  Widget _buildChartSection(BuildContext context, MarketDataState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Timeframe selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['1D', '1W', '1M', '3M', '1Y', 'ALL'].map((timeframe) {
              return ChoiceChip(
                label: Text(timeframe),
                selected: _selectedTimeframe == timeframe,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedTimeframe = timeframe);
                    // TODO: Fetch historical data for timeframe
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Indicator toggles
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('SMA 20'),
                selected: _showSMA20,
                onSelected: (selected) => setState(() => _showSMA20 = selected),
                selectedColor: AppColors.sma20.withOpacity(0.3),
              ),
              FilterChip(
                label: const Text('SMA 50'),
                selected: _showSMA50,
                onSelected: (selected) => setState(() => _showSMA50 = selected),
                selectedColor: AppColors.sma50.withOpacity(0.3),
              ),
              FilterChip(
                label: const Text('EMA'),
                selected: _showEMA,
                onSelected: (selected) => setState(() => _showEMA = selected),
                selectedColor: AppColors.ema12.withOpacity(0.3),
              ),
              FilterChip(
                label: const Text('Bollinger'),
                selected: _showBollinger,
                onSelected: (selected) =>
                    setState(() => _showBollinger = selected),
                selectedColor: AppColors.bollingerBand.withOpacity(0.3),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(height: 300, child: _buildChart(context, state)),
          const SizedBox(height: 24),

          // RSI Indicator
          _buildRSIIndicator(context),
          const SizedBox(height: 24),

          // MACD Indicator
          _buildMACDIndicator(context),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, MarketDataState state) {
    // Generate sample candlestick data for demo
    final candles = _generateSampleCandles();

    if (candles.isEmpty) {
      return const Center(child: Text('No chart data available'));
    }

    final prices = candles.map((c) => c.close).toList();

    List<double?>? sma20;
    List<double?>? sma50;
    List<double?>? ema12;
    List<double?>? ema26;
    Map<String, List<double?>>? bollingerBands;

    if (_showSMA20) {
      sma20 = _technicalAnalysisService.calculateSMA(prices, 20);
    }
    if (_showSMA50) {
      sma50 = _technicalAnalysisService.calculateSMA(prices, 50);
    }
    if (_showEMA) {
      ema12 = _technicalAnalysisService.calculateEMA(prices, 12);
      ema26 = _technicalAnalysisService.calculateEMA(prices, 26);
    }
    if (_showBollinger) {
      bollingerBands = _technicalAnalysisService.calculateBollingerBands(
        prices,
      );
    }

    return CandlestickChart(
      candles: candles,
      sma20: sma20,
      sma50: sma50,
      ema12: ema12,
      ema26: ema26,
      bollingerBands: bollingerBands,
      showVolume: true,
      timeframe: _selectedTimeframe,
    );
  }

  Widget _buildRSIIndicator(BuildContext context) {
    final candles = _generateSampleCandles();
    final prices = candles.map((c) => c.close).toList();
    final rsiValues = _technicalAnalysisService.calculateRSI(prices);
    final timestamps = candles.map((c) => c.timestamp).toList();

    return RSIIndicatorWidget(rsiValues: rsiValues, timestamps: timestamps);
  }

  Widget _buildMACDIndicator(BuildContext context) {
    final candles = _generateSampleCandles();
    final prices = candles.map((c) => c.close).toList();
    final macdData = _technicalAnalysisService.calculateMACD(prices);
    final timestamps = candles.map((c) => c.timestamp).toList();

    return MACDIndicatorWidget(
      macdLine: macdData['macd']!,
      signalLine: macdData['signal']!,
      histogram: macdData['histogram']!,
      timestamps: timestamps,
    );
  }

  Widget _buildOverviewTab(BuildContext context, MarketDataState state) {
    if (state is CompanyProfileLoaded) {
      final profile = state.profile;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('About', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(profile.description ?? 'No description available'),
          const SizedBox(height: 16),
          if (profile.country != null)
            _buildInfoRow('Country', profile.country!),
          if (profile.industry != null)
            _buildInfoRow('Industry', profile.industry!),
          if (profile.sector != null) _buildInfoRow('Sector', profile.sector!),
          if (profile.website.isNotEmpty)
            _buildInfoRow('Website', profile.website),
        ],
      );
    }

    return const Center(child: Text('Loading company information...'));
  }

  Widget _buildStatisticsTab(BuildContext context, MarketDataState state) {
    if (state is StockQuoteLoaded) {
      final quote = state.quote;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard('Price Statistics', [
            _buildStatRow('Open', '\$${quote.open.toStringAsFixed(2)}'),
            _buildStatRow('High', '\$${quote.high.toStringAsFixed(2)}'),
            _buildStatRow('Low', '\$${quote.low.toStringAsFixed(2)}'),
            _buildStatRow(
              'Previous Close',
              '\$${quote.previousClose.toStringAsFixed(2)}',
            ),
          ]),
          const SizedBox(height: 16),
          _buildStatCard('Trading Activity', [
            _buildStatRow('Volume', _formatVolume(quote.volume)),
            _buildStatRow('Change', '\$${quote.change.toStringAsFixed(2)}'),
            _buildStatRow(
              'Change %',
              '${quote.changePercent.toStringAsFixed(2)}%',
            ),
          ]),
        ],
      );
    }

    if (state is CryptoQuoteLoaded) {
      final quote = state.quote;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard('Price Statistics', [
            _buildStatRow(
              'Current Price',
              '\$${quote.currentPrice.toStringAsFixed(2)}',
            ),
            _buildStatRow('24h High', '\$${quote.high24h.toStringAsFixed(2)}'),
            _buildStatRow('24h Low', '\$${quote.low24h.toStringAsFixed(2)}'),
            _buildStatRow('Market Cap Rank', '#${quote.marketCapRank}'),
          ]),
          const SizedBox(height: 16),
          _buildStatCard('Market Data', [
            _buildStatRow(
              'Market Cap',
              '\$${_formatLargeNumber(quote.marketCap)}',
            ),
            _buildStatRow(
              '24h Volume',
              '\$${_formatLargeNumber(quote.totalVolume)}',
            ),
            _buildStatRow(
              '24h Change',
              '\$${quote.priceChange24h.toStringAsFixed(2)}',
            ),
            _buildStatRow(
              '24h Change %',
              '${quote.priceChangePercentage24h.toStringAsFixed(2)}%',
            ),
          ]),
        ],
      );
    }

    return const Center(child: Text('Loading statistics...'));
  }

  Widget _buildNewsTab(BuildContext context, MarketDataState state) {
    // TODO: Implement news feed
    return const Center(child: Text('News feed coming soon...'));
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
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

  String _formatLargeNumber(double number) {
    if (number >= 1000000000000) {
      return '${(number / 1000000000000).toStringAsFixed(2)}T';
    } else if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    }
    return number.toStringAsFixed(2);
  }

  // Generate sample candlestick data for demonstration
  List<Candlestick> _generateSampleCandles() {
    final now = DateTime.now();
    final candles = <Candlestick>[];
    double basePrice = 150.0;

    for (int i = 0; i < 60; i++) {
      final date = now.subtract(Duration(days: 60 - i));

      // Simulate price movement
      final random = (i * 17) % 100 / 100;
      final change = (random - 0.5) * 10;
      basePrice += change;

      final open = basePrice + ((i * 13) % 100 / 100 - 0.5) * 2;
      final close = basePrice + ((i * 19) % 100 / 100 - 0.5) * 2;
      final high =
          [open, close].reduce((a, b) => a > b ? a : b) +
          ((i * 7) % 100 / 100) * 3;
      final low =
          [open, close].reduce((a, b) => a < b ? a : b) -
          ((i * 11) % 100 / 100) * 3;
      final volume = 1000000 + (i * 50000);

      candles.add(
        Candlestick(
          timestamp: date,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        ),
      );
    }

    return candles;
  }
}
