import 'package:equatable/equatable.dart';

/// Company profile entity
class CompanyProfile extends Equatable {
  final String symbol;
  final String name;
  final String? country;
  final String? industry;
  final String? sector;
  final String? logo;
  final String? description;
  final double? marketCap;
  final String? exchange;
  final String? currency;
  final String? webUrl;

  const CompanyProfile({
    required this.symbol,
    required this.name,
    this.country,
    this.industry,
    this.sector,
    this.logo,
    this.description,
    this.marketCap,
    this.exchange,
    this.currency,
    this.webUrl,
  });

  /// Alias for webUrl for convenience
  String get website => webUrl ?? '';

  @override
  List<Object?> get props => [
        symbol,
        name,
        country,
        industry,
        sector,
        logo,
        description,
        marketCap,
        exchange,
        currency,
        webUrl,
      ];
}
