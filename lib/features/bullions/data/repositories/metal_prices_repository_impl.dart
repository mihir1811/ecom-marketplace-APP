import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_config.dart';
import '../../domain/models/metal_spot_price.dart';
import '../../domain/repositories/metal_prices_repository.dart';

final metalPricesRepositoryProvider = Provider<MetalPricesRepository>(
  (ref) => MetalPricesRepositoryImpl(),
);

/// Spot prices via AURUM free API, cached locally for [cacheTtl].
///
/// Uses a dedicated Dio (no app baseUrl / Content-Type) so Flutter web CORS
/// stays simple. Cache hit within 2 hours skips the network.
class MetalPricesRepositoryImpl implements MetalPricesRepository {
  MetalPricesRepositoryImpl({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: ApiConfig.connectTimeout,
                receiveTimeout: ApiConfig.receiveTimeout,
                headers: const {'Accept': 'application/json'},
                responseType: ResponseType.json,
              ),
            );

  final Dio _dio;

  static const cacheTtl = Duration(hours: 2);
  static const _cachePayloadKey = 'bullion_metal_spot_prices_v1';
  static const _cacheFetchedAtKey = 'bullion_metal_spot_prices_fetched_at_v1';

  static const _endpoint = 'https://aurumrates.com/api/v1/spot';
  static const _metals = 'gold,silver,platinum,palladium,copper';

  static const _order = <String>[
    'gold',
    'silver',
    'palladium',
    'copper',
    'platinum',
  ];

  static const _meta = <String, ({String name, String code, String unit})>{
    'gold': (name: 'Gold', code: 'XAU', unit: '/oz'),
    'silver': (name: 'Silver', code: 'XAG', unit: '/oz'),
    'platinum': (name: 'Platinum', code: 'XPT', unit: '/oz'),
    'palladium': (name: 'Palladium', code: 'XPD', unit: '/oz'),
    'copper': (name: 'Copper', code: 'HG', unit: '/lb'),
  };

  @override
  Future<Result<List<MetalSpotPrice>, Failure>> fetchSpotPrices() async {
    try {
      final cached = await _readCacheIfFresh();
      if (cached != null && cached.isNotEmpty) {
        return Result.success(cached);
      }

      final network = await _fetchFromNetwork();
      switch (network) {
        case Success(value: final prices):
          try {
            await _writeCache(prices);
          } catch (_) {}
          return Result.success(prices);
        case ResultFailure(failure: final failure):
          final stale = await _readCacheIgnoringTtl();
          if (stale != null && stale.isNotEmpty) {
            return Result.success(stale);
          }
          return Result.failure(failure);
      }
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Future<Result<List<MetalSpotPrice>, Failure>> _fetchFromNetwork() async {
    try {
      final response = await _dio.get<dynamic>(
        _endpoint,
        queryParameters: const {'metals': _metals},
      );

      final root = _asStringKeyedMap(response.data);
      if (root == null) {
        return Result.failure(
          const UnknownFailure('Metal prices response was not JSON.'),
        );
      }

      final data = _asStringKeyedMap(root['data']);
      if (data == null) {
        return Result.failure(
          const UnknownFailure('Metal prices response missing data.'),
        );
      }

      final out = <MetalSpotPrice>[];
      for (final id in _order) {
        final row = _asStringKeyedMap(data[id]);
        if (row == null) continue;
        final meta = _meta[id];
        if (meta == null) continue;
        final price = _asDouble(row['price']);
        if (price == null) continue;
        out.add(
          MetalSpotPrice(
            id: id,
            name: meta.name,
            code: meta.code,
            priceUsd: price,
            changePercent: _asDouble(row['change_pct']) ?? 0,
            unitLabel: meta.unit,
          ),
        );
      }

      if (out.isEmpty) {
        return Result.failure(
          const UnknownFailure('No metal prices returned.'),
        );
      }

      return Result.success(out);
    } on DioException catch (e) {
      return Result.failure(NetworkFailure.fromDioException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Future<List<MetalSpotPrice>?> _readCacheIfFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fetchedAtMs = prefs.getInt(_cacheFetchedAtKey);
      if (fetchedAtMs == null) return null;

      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(fetchedAtMs),
      );
      if (age > cacheTtl) return null;

      return _decodeCache(prefs.getString(_cachePayloadKey));
    } catch (_) {
      return null;
    }
  }

  Future<List<MetalSpotPrice>?> _readCacheIgnoringTtl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _decodeCache(prefs.getString(_cachePayloadKey));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(List<MetalSpotPrice> prices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cachePayloadKey,
      jsonEncode(prices.map((p) => p.toJson()).toList()),
    );
    await prefs.setInt(
      _cacheFetchedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static List<MetalSpotPrice>? _decodeCache(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      final out = <MetalSpotPrice>[];
      for (final item in decoded) {
        final map = _asStringKeyedMap(item);
        if (map == null) continue;
        final price = MetalSpotPrice.fromJson(map);
        if (price.id.isEmpty) continue;
        out.add(price);
      }
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  /// Normalizes JS/Dart JSON maps that may not be `Map<String, dynamic>`.
  static Map<String, dynamic>? _asStringKeyedMap(Object? value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return {
        for (final entry in value.entries) entry.key.toString(): entry.value,
      };
    }
    if (value is String) {
      try {
        return _asStringKeyedMap(jsonDecode(value));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
