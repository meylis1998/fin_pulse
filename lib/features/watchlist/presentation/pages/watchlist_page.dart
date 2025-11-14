import 'package:fin_pulse/features/market_data/presentation/bloc/market_data_bloc.dart';
import 'package:fin_pulse/features/market_data/presentation/bloc/market_data_event.dart';
import 'package:fin_pulse/features/market_data/presentation/bloc/market_data_state.dart';
import 'package:fin_pulse/features/market_data/presentation/widgets/crypto_quote_card.dart';
import 'package:fin_pulse/features/market_data/presentation/widgets/stock_quote_card.dart';
import 'package:fin_pulse/features/watchlist/presentation/bloc/watchlist_bloc.dart';
import 'package:fin_pulse/features/watchlist/presentation/bloc/watchlist_event.dart';
import 'package:fin_pulse/features/watchlist/presentation/bloc/watchlist_state.dart';
import 'package:fin_pulse/injection_container.dart';
import 'package:fin_pulse/shared/theme/app_colors.dart';
import 'package:fin_pulse/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Watchlist page showing tracked stocks and crypto
class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WatchlistBloc>(
            create: (context) =>
                sl<WatchlistBloc>()..add(const LoadWatchlistEvent())),
        BlocProvider<MarketDataBloc>(create: (context) => sl<MarketDataBloc>()),
      ],
      child: const _WatchlistView(),
    );
  }
}

class _WatchlistView extends StatefulWidget {
  const _WatchlistView();

  @override
  State<_WatchlistView> createState() => _WatchlistViewState();
}

class _WatchlistViewState extends State<_WatchlistView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<WatchlistBloc>().add(const RefreshWatchlistEvent());
            },
          ),
          BlocBuilder<WatchlistBloc, WatchlistState>(
            builder: (context, state) {
              final isSubscribed =
                  state is WatchlistLoaded && state.isSubscribed;
              return IconButton(
                icon: Icon(
                  isSubscribed
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: isSubscribed ? AppColors.bullish : null,
                ),
                onPressed: () {
                  if (isSubscribed) {
                    context
                        .read<WatchlistBloc>()
                        .add(const UnsubscribeFromWatchlistUpdatesEvent());
                  } else {
                    context
                        .read<WatchlistBloc>()
                        .add(const SubscribeToWatchlistUpdatesEvent());
                  }
                },
                tooltip: isSubscribed
                    ? 'Unsubscribe from updates'
                    : 'Subscribe to real-time updates',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search symbols...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<WatchlistBloc>()
                              .add(const ClearSearchEvent());
                        },
                      )
                    : null,
              ),
              onChanged: (query) {
                context.read<WatchlistBloc>().add(SearchSymbolEvent(query));
              },
            ),
          ),

          // Watchlist content
          Expanded(
            child: BlocBuilder<WatchlistBloc, WatchlistState>(
              builder: (context, state) {
                if (state is WatchlistLoading) {
                  return ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) => const CardShimmer(),
                  );
                }

                if (state is WatchlistError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context
                                .read<WatchlistBloc>()
                                .add(const LoadWatchlistEvent());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is WatchlistSearchResults) {
                  return _buildSearchResults(context, state);
                }

                if (state is WatchlistLoaded || state is WatchlistUpdated) {
                  final items = state is WatchlistLoaded
                      ? state.items
                      : (state as WatchlistUpdated).items;

                  if (items.isEmpty) {
                    return const Center(
                      child: Text('No symbols in watchlist'),
                    );
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _WatchlistItemWidget(item: item);
                    },
                  );
                }

                return const Center(child: Text('Unknown state'));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddSymbolDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchResults(
      BuildContext context, WatchlistSearchResults state) {
    return ListView.builder(
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final symbol = state.results[index];
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(symbol),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              context.read<WatchlistBloc>().add(
                    AddToWatchlistEvent(symbol: symbol),
                  );
              _searchController.clear();
            },
          ),
        );
      },
    );
  }

  void _showAddSymbolDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Symbol'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Symbol',
            hintText: 'e.g., AAPL, bitcoin',
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<WatchlistBloc>().add(
                      AddToWatchlistEvent(symbol: controller.text.trim()),
                    );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _WatchlistItemWidget extends StatelessWidget {
  final WatchlistItem item;

  const _WatchlistItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    // Fetch quote data for this symbol
    return BlocProvider<MarketDataBloc>(
      create: (context) => sl<MarketDataBloc>()
        ..add(
          item.isCrypto
              ? FetchCryptoQuoteEvent(item.symbol)
              : FetchStockQuoteEvent(item.symbol),
        ),
      child: BlocBuilder<MarketDataBloc, MarketDataState>(
        builder: (context, state) {
          if (state is MarketDataLoading) {
            return const CardShimmer();
          }

          if (state is StockQuoteLoaded) {
            return Dismissible(
              key: Key(item.symbol),
              direction: DismissDirection.endToStart,
              background: Container(
                color: AppColors.error,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                context
                    .read<WatchlistBloc>()
                    .add(RemoveFromWatchlistEvent(item.symbol));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.symbol} removed')),
                );
              },
              child: StockQuoteCard(quote: state.quote),
            );
          }

          if (state is CryptoQuoteLoaded) {
            return Dismissible(
              key: Key(item.symbol),
              direction: DismissDirection.endToStart,
              background: Container(
                color: AppColors.error,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                context
                    .read<WatchlistBloc>()
                    .add(RemoveFromWatchlistEvent(item.symbol));
              },
              child: CryptoQuoteCard(quote: state.quote),
            );
          }

          if (state is MarketDataError) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading:
                    const Icon(Icons.error_outline, color: AppColors.error),
                title: Text(item.symbol),
                subtitle: Text(state.message),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<MarketDataBloc>().add(
                          item.isCrypto
                              ? FetchCryptoQuoteEvent(item.symbol)
                              : FetchStockQuoteEvent(item.symbol),
                        );
                  },
                ),
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
