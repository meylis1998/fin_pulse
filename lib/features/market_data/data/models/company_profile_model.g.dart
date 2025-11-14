// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompanyProfileModel _$CompanyProfileModelFromJson(Map<String, dynamic> json) =>
    CompanyProfileModel(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      country: json['country'] as String?,
      industry: json['industry'] as String?,
      sector: json['sector'] as String?,
      logo: json['logo'] as String?,
      description: json['description'] as String?,
      marketCap: (json['marketCap'] as num?)?.toDouble(),
      exchange: json['exchange'] as String?,
      currency: json['currency'] as String?,
      webUrl: json['webUrl'] as String?,
    );

Map<String, dynamic> _$CompanyProfileModelToJson(
        CompanyProfileModel instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'name': instance.name,
      'country': instance.country,
      'industry': instance.industry,
      'sector': instance.sector,
      'logo': instance.logo,
      'description': instance.description,
      'marketCap': instance.marketCap,
      'exchange': instance.exchange,
      'currency': instance.currency,
      'webUrl': instance.webUrl,
    };
