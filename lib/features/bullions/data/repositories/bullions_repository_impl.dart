import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/models/billion.dart';
import '../../domain/models/bullions_filter_state.dart';
import '../../domain/repositories/bullions_repository.dart';

final bullionsRepositoryProvider = Provider<BullionsRepository>(
  (ref) => BullionsRepositoryImpl(),
);

class BullionsRepositoryImpl implements BullionsRepository {
  List<Bullion>? _cache;

  List<Bullion> _catalog() => _cache ??= _generateCatalog();

  static List<Bullion> _generateCatalog() {
    return [
      const Bullion(
        id: 'G-1000-24K-1',
        metal: BullionMetal.gold,
        name: 'Royal Mint Gold Bar',
        presetVariant: '24K',
        shape: 'Bar',
        weightLabel: '1kg',
        weightGrams: 1000,
        purity: 999.9,
        price: 25800,
        quantityAvailable: 8,
        condition: 'New',
        certification: 'LBMA Good Delivery',
        mintMark: 'LBMA',
        lengthMm: 117,
        widthMm: 52,
        heightMm: 9,
      ),
      const Bullion(
        id: 'G-1000-24K-2',
        metal: BullionMetal.gold,
        name: 'Investment Gold 1000g',
        presetVariant: '24K',
        shape: 'Bar',
        weightLabel: '1kg',
        weightGrams: 1000,
        purity: 999.9,
        price: 26500,
        quantityAvailable: 6,
        condition: 'New',
        certification: 'PAMP Certificate',
        mintMark: 'PAMP Suisse',
        lengthMm: 116,
        widthMm: 51,
        heightMm: 8,
      ),
      const Bullion(
        id: 'G-500-22K-1',
        metal: BullionMetal.gold,
        name: 'Gold Reserve 500g',
        presetVariant: '22K',
        shape: 'Bar',
        weightLabel: '500g',
        weightGrams: 500,
        purity: 916.7,
        price: 13250,
        quantityAvailable: 10,
        condition: 'Brilliant Uncirculated',
        certification: 'PAMP Certificate',
        mintMark: 'PAMP Suisse',
        lengthMm: 95,
        widthMm: 42,
        heightMm: 7,
      ),
      const Bullion(
        id: 'G-31-22K-2',
        metal: BullionMetal.gold,
        name: 'Gold Sovereign Coin',
        presetVariant: '22K',
        shape: 'Coin',
        weightLabel: '1oz',
        weightGrams: 31.1,
        purity: 916.7,
        price: 2150,
        quantityAvailable: 24,
        condition: 'Brilliant Uncirculated',
        certification: 'US Mint Certificate',
        mintMark: 'US Mint',
        lengthMm: 32,
        widthMm: 32,
        heightMm: 2,
      ),
      const Bullion(
        id: 'G-10-18K-1',
        metal: BullionMetal.gold,
        name: 'Collector Gold Round',
        presetVariant: '18K',
        shape: 'Round',
        weightLabel: '10g',
        weightGrams: 10,
        purity: 750.0,
        price: 640,
        quantityAvailable: 32,
        condition: 'Circulated',
        certification: 'RCM Certificate',
        mintMark: 'Royal Canadian Mint',
        lengthMm: 21,
        widthMm: 21,
        heightMm: 2,
      ),

      const Bullion(
        id: 'S-5000-999-1',
        metal: BullionMetal.silver,
        name: 'Silver Stack 5000g',
        presetVariant: '999',
        shape: 'Bar',
        weightLabel: '5kg',
        weightGrams: 5000,
        purity: 999.9,
        price: 11950,
        quantityAvailable: 4,
        condition: 'New',
        certification: 'LBMA Good Delivery',
        mintMark: 'LBMA',
        lengthMm: 181,
        widthMm: 78,
        heightMm: 16,
      ),
      const Bullion(
        id: 'S-1000-999-2',
        metal: BullionMetal.silver,
        name: 'Silver Bullion 1000g',
        presetVariant: '999',
        shape: 'Bar',
        weightLabel: '1kg',
        weightGrams: 1000,
        purity: 999.9,
        price: 2450,
        quantityAvailable: 11,
        condition: 'New',
        certification: 'PAMP Certificate',
        mintMark: 'PAMP Suisse',
        lengthMm: 120,
        widthMm: 56,
        heightMm: 13,
      ),
      const Bullion(
        id: 'S-31-925-1',
        metal: BullionMetal.silver,
        name: 'Sterling Silver Round',
        presetVariant: '925',
        shape: 'Round',
        weightLabel: '1oz',
        weightGrams: 31.1,
        purity: 925.0,
        price: 42,
        quantityAvailable: 100,
        condition: 'Brilliant Uncirculated',
        certification: 'RCM Certificate',
        mintMark: 'Royal Canadian Mint',
        lengthMm: 38,
        widthMm: 38,
        heightMm: 3,
      ),
      const Bullion(
        id: 'S-5-Sterling-1',
        metal: BullionMetal.silver,
        name: 'Silver Granules Pack',
        presetVariant: 'Sterling',
        shape: 'Granules',
        weightLabel: '5g',
        weightGrams: 5,
        purity: 925.0,
        price: 12,
        quantityAvailable: 250,
        condition: 'New',
        certification: 'US Mint Certificate',
        mintMark: 'US Mint',
        lengthMm: 10,
        widthMm: 10,
        heightMm: 5,
      ),

      const Bullion(
        id: 'P-1000-9995-1',
        metal: BullionMetal.platinum,
        name: 'Platinum Vault 1000g',
        presetVariant: '999.5',
        shape: 'Bar',
        weightLabel: '1kg',
        weightGrams: 1000,
        purity: 999.5,
        price: 23000,
        quantityAvailable: 3,
        condition: 'New',
        certification: 'LBMA Good Delivery',
        mintMark: 'LBMA',
        lengthMm: 118,
        widthMm: 52,
        heightMm: 8,
      ),
      const Bullion(
        id: 'P-500-950-2',
        metal: BullionMetal.platinum,
        name: 'Platinum Reserve 500g',
        presetVariant: '950',
        shape: 'Bar',
        weightLabel: '500g',
        weightGrams: 500,
        purity: 950.0,
        price: 11500,
        quantityAvailable: 5,
        condition: 'Brilliant Uncirculated',
        certification: 'PAMP Certificate',
        mintMark: 'PAMP Suisse',
        lengthMm: 94,
        widthMm: 41,
        heightMm: 7,
      ),
      const Bullion(
        id: 'P-31-9995-3',
        metal: BullionMetal.platinum,
        name: 'Platinum Eagle Round',
        presetVariant: '999.5',
        shape: 'Coin',
        weightLabel: '1oz',
        weightGrams: 31.1,
        purity: 999.5,
        price: 1210,
        quantityAvailable: 15,
        condition: 'New',
        certification: 'US Mint Certificate',
        mintMark: 'US Mint',
        lengthMm: 32,
        widthMm: 32,
        heightMm: 2,
      ),

      const Bullion(
        id: 'Pd-250-9995-1',
        metal: BullionMetal.palladium,
        name: 'Palladium Coin 250g',
        presetVariant: '999.5',
        shape: 'Coin',
        weightLabel: '250g',
        weightGrams: 250,
        purity: 999.5,
        price: 8900,
        quantityAvailable: 7,
        condition: 'Brilliant Uncirculated',
        certification: 'RCM Certificate',
        mintMark: 'Royal Canadian Mint',
        lengthMm: 44,
        widthMm: 44,
        heightMm: 4,
      ),
      const Bullion(
        id: 'Pd-31-950-2',
        metal: BullionMetal.palladium,
        name: 'Palladium Mint Round',
        presetVariant: '950',
        shape: 'Round',
        weightLabel: '1oz',
        weightGrams: 31.1,
        purity: 950.0,
        price: 1180,
        quantityAvailable: 13,
        condition: 'New',
        certification: 'US Mint Certificate',
        mintMark: 'US Mint',
        lengthMm: 34,
        widthMm: 34,
        heightMm: 2,
      ),
    ];
  }

  bool _matchesSearch(Bullion b, String q) {
    if (q.isEmpty) return true;
    final qq = q.trim().toLowerCase();
    final hay = [
      b.name,
      b.presetVariant,
      b.shape,
      b.weightLabel,
      b.condition,
      b.certification,
      b.mintMark,
      b.purity.toStringAsFixed(1),
    ].join(' ').toLowerCase();
    return hay.contains(qq);
  }

  bool _matchesRange(double value, double min, double max) {
    if (min > 0 && value < min) return false;
    if (max > 0 && value > max) return false;
    return true;
  }

  bool _matchesWeightChip(Bullion b, Set<String> chips) {
    if (chips.isEmpty) return true;
    return chips.contains(b.weightLabel);
  }

  bool _matches(Bullion b, BullionsFilterState f) {
    final metal = f.metalFilter.metal;
    if (metal != null && b.metal != metal) return false;
    if (f.selectedVariant != null && b.presetVariant != f.selectedVariant) {
      return false;
    }
    if (!_matchesSearch(b, f.searchQuery)) return false;
    if (f.shapes.isNotEmpty && !f.shapes.contains(b.shape)) return false;
    if (!_matchesWeightChip(b, f.weightChips)) return false;
    if (f.conditions.isNotEmpty && !f.conditions.contains(b.condition)) {
      return false;
    }
    if (f.certifications.isNotEmpty &&
        !f.certifications.contains(b.certification)) {
      return false;
    }
    if (f.mintMarks.isNotEmpty && !f.mintMarks.contains(b.mintMark)) {
      return false;
    }
    if (!_matchesRange(b.price, f.priceMin, f.priceMax)) return false;
    if (!_matchesRange(b.weightGrams, f.weightMin, f.weightMax)) return false;
    if (!_matchesRange(
      b.quantityAvailable.toDouble(),
      f.quantityMin,
      f.quantityMax,
    )) {
      return false;
    }
    if (!_matchesRange(b.lengthMm, f.lengthMin, f.lengthMax)) return false;
    if (!_matchesRange(b.widthMm, f.widthMin, f.widthMax)) return false;
    if (!_matchesRange(b.heightMm, f.heightMin, f.heightMax)) return false;
    return true;
  }

  @override
  Future<Result<BullionsCatalogResponse, Failure>> searchBullions({
    required BullionsFilterState filters,
    required int page,
    int pageSize = 20,
  }) async {
    await Future.delayed(
      Duration(milliseconds: 180 + Random().nextInt(120)),
    );

    try {
      final filtered = _catalog().where((b) => _matches(b, filters)).toList()
        ..sort((a, b) {
          final metalCompare = a.metal.index.compareTo(b.metal.index);
          if (metalCompare != 0) return metalCompare;
          return b.price.compareTo(a.price);
        });

      final totalCount = filtered.length;
      final start = (page - 1) * pageSize;
      final end = min(start + pageSize, filtered.length);

      if (start >= filtered.length) {
        return Result.success(
          BullionsCatalogResponse(
            bullions: const [],
            totalCount: totalCount,
            hasMore: false,
            page: page,
          ),
        );
      }

      final pageItems = filtered.sublist(start, end);
      final hasMore = end < filtered.length;

      return Result.success(
        BullionsCatalogResponse(
          bullions: pageItems,
          totalCount: totalCount,
          hasMore: hasMore,
          page: page,
        ),
      );
    } catch (_) {
      return Result.failure(
        const NetworkFailure('Failed to load bullions. Please try again.'),
      );
    }
  }
}

