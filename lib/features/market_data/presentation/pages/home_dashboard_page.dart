import 'package:fin_pulse/features/watchlist/presentation/pages/watchlist_page.dart';
import 'package:fin_pulse/injection_container.dart';
import 'package:fin_pulse/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_pulse/features/market_data/presentation/bloc/market_data_bloc.dart';
import 'package:fin_pulse/features/market_data/presentation/bloc/market_data_event.dart';
import 'package:fin_pulse/features/market_data/presentation/bloc/market_data_state.dart';
import 'package:fin_pulse/features/market_data/presentation/widgets/stock_quote_card.dart';
import 'package:fin_pulse/features/market_data/presentation/widgets/crypto_quote_card.dart';

/// Home Dashboard - Main entry point of the app
class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _DashboardView(),
    const WatchlistPage(),
    const _PortfolioView(),
    const _SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Watchlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Dashboard view showing market overview
class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MarketDataBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('FinPulse'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // TODO: Show notifications
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<MarketDataBloc>().add(const RefreshMarketDataEvent());
            await Future.delayed(const Duration(seconds: 2));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Welcome section
              Text(
                'Market Overview',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Stay updated with real-time market data',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Market indices
              _buildMarketIndices(context),
              const SizedBox(height: 24),

              // Featured stocks section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trending Stocks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to full stocks list
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildFeaturedStocks(context),
              const SizedBox(height: 24),

              // Featured crypto section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Cryptocurrencies',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to full crypto list
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildFeaturedCrypto(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketIndices(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildIndexCard(
            context,
            'S&P 500',
            '4,783.45',
            '+1.24%',
            true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildIndexCard(
            context,
            'NASDAQ',
            '15,095.14',
            '+0.87%',
            true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildIndexCard(
            context,
            'BTC',
            '\$43,250',
            '-2.15%',
            false,
          ),
        ),
      ],
    );
  }

  Widget _buildIndexCard(
    BuildContext context,
    String name,
    String value,
    String change,
    bool isPositive,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(
                color: isPositive ? AppColors.bullish : AppColors.bearish,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedStocks(BuildContext context) {
    final symbols = ['AAPL', 'MSFT', 'GOOGL'];

    return Column(
      children: symbols.map((symbol) {
        return BlocProvider(
          create: (_) =>
              sl<MarketDataBloc>()..add(FetchStockQuoteEvent(symbol)),
          child: BlocBuilder<MarketDataBloc, MarketDataState>(
            builder: (context, state) {
              if (state is StockQuoteLoaded) {
                return StockQuoteCard(quote: state.quote);
              }
              return const SizedBox();
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeaturedCrypto(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MarketDataBloc>()
        ..add(const FetchCryptoQuotesEvent(
          ids: ['bitcoin', 'ethereum'],
          limit: 2,
        )),
      child: BlocBuilder<MarketDataBloc, MarketDataState>(
        builder: (context, state) {
          if (state is CryptoQuotesLoaded) {
            return Column(
              children: state.quotes
                  .map((quote) => CryptoQuoteCard(quote: quote))
                  .toList(),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

/// Portfolio view (placeholder)
class _PortfolioView extends StatelessWidget {
  const _PortfolioView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Portfolio Tracking',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Track your investments and P&L',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Add portfolio
              },
              child: const Text('Add Holdings'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings view (placeholder)
class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Account'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Notifications'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('Appearance'),
            trailing: Icon(Icons.chevron_right),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('FinPulse v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'FinPulse',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 FinPulse Team',
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'A production-ready financial dashboard with real-time market data, '
                    'intelligent caching, and advanced technical analysis.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
