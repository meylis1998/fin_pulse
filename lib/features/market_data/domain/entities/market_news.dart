import 'package:equatable/equatable.dart';

/// Market news entity
class MarketNews extends Equatable {
  final int id;
  final String headline;
  final String summary;
  final String source;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final String? sentiment; // 'bullish', 'bearish', 'neutral'
  final List<String> relatedSymbols;

  const MarketNews({
    required this.id,
    required this.headline,
    required this.summary,
    required this.source,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    this.sentiment,
    this.relatedSymbols = const [],
  });

  @override
  List<Object?> get props => [
        id,
        headline,
        summary,
        source,
        url,
        imageUrl,
        publishedAt,
        sentiment,
        relatedSymbols,
      ];
}
