// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_news_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarketNewsModel _$MarketNewsModelFromJson(Map<String, dynamic> json) =>
    MarketNewsModel(
      id: (json['id'] as num).toInt(),
      headline: json['headline'] as String,
      summary: json['summary'] as String,
      source: json['source'] as String,
      url: json['url'] as String,
      imageUrl: json['imageUrl'] as String?,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      sentiment: json['sentiment'] as String?,
      relatedSymbols: (json['relatedSymbols'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MarketNewsModelToJson(MarketNewsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'headline': instance.headline,
      'summary': instance.summary,
      'source': instance.source,
      'url': instance.url,
      'imageUrl': instance.imageUrl,
      'publishedAt': instance.publishedAt.toIso8601String(),
      'sentiment': instance.sentiment,
      'relatedSymbols': instance.relatedSymbols,
    };
