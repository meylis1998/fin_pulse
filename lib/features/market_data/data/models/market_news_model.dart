import 'package:fin_pulse/features/market_data/domain/entities/market_news.dart';
import 'package:json_annotation/json_annotation.dart';

part 'market_news_model.g.dart';

@JsonSerializable()
class MarketNewsModel extends MarketNews {
  const MarketNewsModel({
    required super.id,
    required super.headline,
    required super.summary,
    required super.source,
    required super.url,
    super.imageUrl,
    required super.publishedAt,
    super.sentiment,
    super.relatedSymbols,
  });

  factory MarketNewsModel.fromJson(Map<String, dynamic> json) =>
      _$MarketNewsModelFromJson(json);

  Map<String, dynamic> toJson() => _$MarketNewsModelToJson(this);

  /// Create from Finnhub API response
  factory MarketNewsModel.fromFinnhub(Map<String, dynamic> json) {
    return MarketNewsModel(
      id: json['id'] as int,
      headline: json['headline'] as String,
      summary: json['summary'] as String,
      source: json['source'] as String,
      url: json['url'] as String,
      imageUrl: json['image'] as String?,
      publishedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['datetime'] as num).toInt() * 1000,
      ),
      sentiment: json['sentiment'] as String?,
      relatedSymbols: json['related'] != null
          ? List<String>.from(json['related'] as List)
          : [],
    );
  }

  MarketNews toEntity() => MarketNews(
        id: id,
        headline: headline,
        summary: summary,
        source: source,
        url: url,
        imageUrl: imageUrl,
        publishedAt: publishedAt,
        sentiment: sentiment,
        relatedSymbols: relatedSymbols,
      );
}
