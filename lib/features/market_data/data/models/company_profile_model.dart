import 'package:fin_pulse/features/market_data/domain/entities/company_profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'company_profile_model.g.dart';

@JsonSerializable()
class CompanyProfileModel extends CompanyProfile {
  const CompanyProfileModel({
    required super.symbol,
    required super.name,
    super.country,
    super.industry,
    super.sector,
    super.logo,
    super.description,
    super.marketCap,
    super.exchange,
    super.currency,
    super.webUrl,
  });

  factory CompanyProfileModel.fromJson(Map<String, dynamic> json) =>
      _$CompanyProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$CompanyProfileModelToJson(this);

  /// Create from Finnhub API response
  factory CompanyProfileModel.fromFinnhub(Map<String, dynamic> json) {
    return CompanyProfileModel(
      symbol: json['ticker'] as String? ?? '',
      name: json['name'] as String,
      country: json['country'] as String?,
      industry: json['finnhubIndustry'] as String?,
      sector: json['finnhubIndustry'] as String?,
      logo: json['logo'] as String?,
      description: json['description'] as String?,
      marketCap: (json['marketCapitalization'] as num?)?.toDouble(),
      exchange: json['exchange'] as String?,
      currency: json['currency'] as String?,
      webUrl: json['weburl'] as String?,
    );
  }

  CompanyProfile toEntity() => CompanyProfile(
        symbol: symbol,
        name: name,
        country: country,
        industry: industry,
        sector: sector,
        logo: logo,
        description: description,
        marketCap: marketCap,
        exchange: exchange,
        currency: currency,
        webUrl: webUrl,
      );
}
