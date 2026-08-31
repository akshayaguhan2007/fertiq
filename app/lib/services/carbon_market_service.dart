import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cache_service.dart';

/// Real-time carbon credit market prices.
///
/// Price chain (first success wins):
///   1. Ember Climate API  — voluntary carbon market spot price (USD/tCO₂e)
///   2. World Bank CCKP    — compliance market reference price (USD/tCO₂e)
///   3. Cached last price  — whatever was last successfully fetched
///   4. Hard floor         — ₹800/credit (ICM BEE minimum floor, 2024)
class CarbonMarketPrice {
  final double priceInr;       // ₹ per ton CO₂e
  final double priceUsd;       // $ per ton CO₂e
  final double usdToInr;       // exchange rate used
  final String source;         // 'ember' | 'worldbank' | 'cache' | 'floor'
  final DateTime fetchedAt;

  const CarbonMarketPrice({
    required this.priceInr,
    required this.priceUsd,
    required this.usdToInr,
    required this.source,
    required this.fetchedAt,
  });

  /// Farmer receives 90% after platform fee
  double farmerPayout(double credits) => credits * priceInr * 0.90;

  Map<String, dynamic> toJson() => {
    'priceInr': priceInr, 'priceUsd': priceUsd,
    'usdToInr': usdToInr, 'source': source,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory CarbonMarketPrice.fromJson(Map<String, dynamic> j) => CarbonMarketPrice(
    priceInr:  (j['priceInr']  as num).toDouble(),
    priceUsd:  (j['priceUsd']  as num).toDouble(),
    usdToInr:  (j['usdToInr']  as num).toDouble(),
    source:    j['source']    as String,
    fetchedAt: DateTime.parse(j['fetchedAt'] as String),
  );

  /// ICM BEE floor price (₹800/credit as of 2024 notification)
  static CarbonMarketPrice get floor => CarbonMarketPrice(
    priceInr: 800, priceUsd: 9.6, usdToInr: 83.5,
    source: 'floor', fetchedAt: DateTime.now(),
  );
}

class CarbonMarketService {
  CarbonMarketService._();
  static final instance = CarbonMarketService._();

  final _cache = CacheService();
  static const _cacheKey = 'carbon_market_price';
  static const _cacheTtlHours = 6;

  CarbonMarketPrice? _inMemory;

  Future<CarbonMarketPrice> fetchPrice() async {
    // Return in-memory if fresh (< 6 hours)
    if (_inMemory != null &&
        DateTime.now().difference(_inMemory!.fetchedAt).inHours < _cacheTtlHours) {
      return _inMemory!;
    }

    // 1. Fetch USD→INR exchange rate (exchangerate-api free tier, no key)
    double usdToInr = 83.5; // fallback
    try {
      final fxRes = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/USD'),
      ).timeout(const Duration(seconds: 8));
      if (fxRes.statusCode == 200) {
        final fx = jsonDecode(fxRes.body) as Map<String, dynamic>;
        final rates = fx['rates'] as Map<String, dynamic>?;
        if (rates != null && rates['INR'] != null) {
          usdToInr = (rates['INR'] as num).toDouble();
        }
      }
    } catch (_) {}

    // 2. Ember Climate voluntary carbon market price (free, no key)
    // Ember publishes global carbon price data via their open API
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.ember-climate.org/v2/carbon-price/latest'
          '?series=voluntary_market&format=json',
        ),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = (body['data'] as List?)?.cast<Map<String, dynamic>>();
        if (data != null && data.isNotEmpty) {
          final priceUsd = (data.first['price'] as num?)?.toDouble();
          if (priceUsd != null && priceUsd > 0) {
            final price = CarbonMarketPrice(
              priceUsd:  priceUsd,
              priceInr:  priceUsd * usdToInr,
              usdToInr:  usdToInr,
              source:    'ember',
              fetchedAt: DateTime.now(),
            );
            await _saveCache(price);
            return _inMemory = price;
          }
        }
      }
    } catch (_) {}

    // 3. World Bank Carbon Pricing Dashboard API (free, no key)
    // Uses the EU ETS spot price as a global reference benchmark
    try {
      final res = await http.get(
        Uri.parse(
          'https://carbonpricingdashboard.worldbank.org/api/instrument'
          '?format=json&instrument_id=EU_ETS',
        ),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body is List ? body : (body['data'] as List?))
            ?.cast<Map<String, dynamic>>();
        if (list != null && list.isNotEmpty) {
          // Find latest price entry
          final sorted = list
              .where((e) => e['price'] != null)
              .toList()
            ..sort((a, b) => (b['year'] as int? ?? 0)
                .compareTo(a['year'] as int? ?? 0));
          if (sorted.isNotEmpty) {
            final priceUsd = (sorted.first['price'] as num).toDouble();
            if (priceUsd > 0) {
              final price = CarbonMarketPrice(
                priceUsd:  priceUsd,
                priceInr:  priceUsd * usdToInr,
                usdToInr:  usdToInr,
                source:    'worldbank',
                fetchedAt: DateTime.now(),
              );
              await _saveCache(price);
              return _inMemory = price;
            }
          }
        }
      }
    } catch (_) {}

    // 4. Persistent cache (last successful fetch, any age)
    try {
      final cached = await _cache.get(_cacheKey, ttlHours: 24 * 30);
      if (cached != null) {
        final price = CarbonMarketPrice.fromJson(cached)
            .._copyWithSource('cache');
        return _inMemory = price;
      }
    } catch (_) {}

    // 5. Hard floor — ICM BEE minimum ₹800/credit
    return _inMemory = CarbonMarketPrice.floor;
  }

  Future<void> _saveCache(CarbonMarketPrice price) async {
    await _cache.set(_cacheKey, price.toJson());
  }
}

// Extension to allow copying source label
extension _PriceCopy on CarbonMarketPrice {
  CarbonMarketPrice _copyWithSource(String src) => CarbonMarketPrice(
    priceInr: priceInr, priceUsd: priceUsd,
    usdToInr: usdToInr, source: src, fetchedAt: fetchedAt,
  );
}
