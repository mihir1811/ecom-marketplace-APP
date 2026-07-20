import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/models/watch.dart';
import '../../domain/models/watch_filter_state.dart';
import '../../domain/repositories/watch_repository.dart';
import 'watch_brand_assets_data.dart';

final watchRepositoryProvider = Provider<WatchRepository>(
  (ref) => WatchRepositoryImpl(),
);

class WatchRepositoryImpl implements WatchRepository {
  List<Watch>? _cache;

  static String caseSizeRangeFor(int mm) {
    if (mm <= 30) return '28–30 mm';
    if (mm <= 34) return '31–34 mm';
    if (mm <= 38) return '35–38 mm';
    if (mm <= 42) return '39–42 mm';
    return '43–46 mm';
  }

  static String waterLabel(int meters) => '${meters}m';

  List<Watch> _catalog() => _cache ??= _generateCatalog();

  List<Watch> _generateCatalog() {
    final rng = Random(77);
    final watches = <Watch>[];
    var id = 10001;
    const brands = WatchCatalogBrands.catalogBrands;
    const modelsByBrand = WatchCatalogBrands.modelsByBrand;

    for (final brand in brands) {
      final models = modelsByBrand[brand] ?? ['Classic'];
      for (var i = 0; i < 8; i++) {
        final caseSize = 28 + rng.nextInt(19);
        final price = _priceForBrand(brand, rng);
        final configs = <String>[];
        if (rng.nextBool()) configs.add('Chronograph');
        if (rng.nextBool()) configs.add('Date');
        if (configs.isEmpty) configs.add('Date');

        final mats = <String>[
          WatchFilterState.materialOptions[
              rng.nextInt(WatchFilterState.materialOptions.length)],
        ];
        if (rng.nextDouble() > 0.6) {
          mats.add(WatchFilterState.materialOptions[
              rng.nextInt(WatchFilterState.materialOptions.length)]);
        }

        final stones = rng.nextInt(5);
        final precious = <String>[];
        if (stones > 0 && rng.nextBool()) {
          precious.add(WatchFilterState.preciousStoneTypeOptions[
              rng.nextInt(WatchFilterState.preciousStoneTypeOptions.length)]);
        }

        final waterM = [30, 50, 100, 150, 200, 300, 500][rng.nextInt(7)];
        final year = 2020 + rng.nextInt(5);
        final hasDiscount = rng.nextDouble() > 0.75;

        watches.add(Watch(
          id: 'W-$id',
          brand: brand,
          model: models[rng.nextInt(models.length)],
          collection: ['Heritage', 'Sport', 'Classic', 'Iconic'][rng.nextInt(4)],
          year: year,
          price: double.parse(price.toStringAsFixed(0)),
          condition: WatchFilterState
              .conditionOptions[rng.nextInt(WatchFilterState.conditionOptions.length)],
          caseSizeMm: caseSize,
          caseSizeRange: caseSizeRangeFor(caseSize),
          caseMaterial: WatchFilterState.caseMaterialOptions[
              rng.nextInt(WatchFilterState.caseMaterialOptions.length)],
          caseShape: WatchFilterState.caseShapeOptions[
              rng.nextInt(WatchFilterState.caseShapeOptions.length)],
          caseBack: WatchFilterState.caseBackOptions[
              rng.nextInt(WatchFilterState.caseBackOptions.length)],
          dialColor: WatchFilterState.dialColorOptions[
              rng.nextInt(WatchFilterState.dialColorOptions.length)],
          strapColor: WatchFilterState.strapColorOptions[
              rng.nextInt(WatchFilterState.strapColorOptions.length)],
          strapMaterial: WatchFilterState.strapMaterialOptions[
              rng.nextInt(WatchFilterState.strapMaterialOptions.length)],
          crownType: WatchFilterState.crownTypeOptions[
              rng.nextInt(WatchFilterState.crownTypeOptions.length)],
          claspType: WatchFilterState.claspTypeOptions[
              rng.nextInt(WatchFilterState.claspTypeOptions.length)],
          movement: WatchFilterState
              .movementOptions[rng.nextInt(WatchFilterState.movementOptions.length)],
          gender: WatchFilterState
              .genderOptions[rng.nextInt(WatchFilterState.genderOptions.length)],
          waterResistanceM: waterM,
          glassMaterial: WatchFilterState.glassMaterialOptions[
              rng.nextInt(WatchFilterState.glassMaterialOptions.length)],
          powerReserveRange: WatchFilterState.powerReserveOptions[
              rng.nextInt(WatchFilterState.powerReserveOptions.length)],
          authentication: WatchFilterState.authenticationOptions[
              rng.nextInt(WatchFilterState.authenticationOptions.length)],
          certification: WatchFilterState.certificationOptions[
              rng.nextInt(WatchFilterState.certificationOptions.length)],
          bezelType: WatchFilterState.bezelTypeOptions[
              rng.nextInt(WatchFilterState.bezelTypeOptions.length)],
          bezelMaterial: WatchFilterState.bezelMaterialOptions[
              rng.nextInt(WatchFilterState.bezelMaterialOptions.length)],
          stonesOnDial: stones,
          configurations: configs,
          materials: mats.toSet().toList(),
          preciousStoneTypes: precious,
          indexes: WatchFilterState
              .indexesOptions[rng.nextInt(WatchFilterState.indexesOptions.length)],
          category: WatchFilterState
              .categoryOptions[rng.nextInt(WatchFilterState.categoryOptions.length)],
          discount: hasDiscount ? (10 + rng.nextInt(31)).toDouble() : null,
          inStock: rng.nextDouble() > 0.12,
        ));
        id++;
      }
    }
    return watches;
  }

  double _priceForBrand(String brand, Random rng) {
    return switch (brand) {
      'Richard Mille' => 180000 + rng.nextDouble() * 420000,
      'Patek Philippe' => 35000 + rng.nextDouble() * 180000,
      'Audemars Piguet' => 28000 + rng.nextDouble() * 120000,
      'Rolex' => 9000 + rng.nextDouble() * 45000,
      'Vacheron Constantin' => 20000 + rng.nextDouble() * 90000,
      'Cartier' => 4500 + rng.nextDouble() * 28000,
      'Hublot' => 8000 + rng.nextDouble() * 40000,
      'Omega' => 3500 + rng.nextDouble() * 12000,
      'Breitling' => 3000 + rng.nextDouble() * 10000,
      'TAG Heuer' => 1500 + rng.nextDouble() * 7000,
      'Grand Seiko' => 2500 + rng.nextDouble() * 9000,
      'Panerai' => 4000 + rng.nextDouble() * 15000,
      'Tissot' => 400 + rng.nextDouble() * 1800,
      'Seiko' => 250 + rng.nextDouble() * 1200,
      _ => 500 + rng.nextDouble() * 8000,
    };
  }

  bool _matchesPriceRange(double price, String range) {
    return switch (range) {
      'Under \$500' => price < 500,
      '\$500 – \$1,000' => price >= 500 && price < 1000,
      '\$1,000 – \$5,000' => price >= 1000 && price < 5000,
      '\$5,000 – \$15,000' => price >= 5000 && price < 15000,
      '\$15,000 – \$50,000' => price >= 15000 && price < 50000,
      '\$50,000+' => price >= 50000,
      _ => true,
    };
  }

  bool _matches(Watch w, WatchFilterState f) {
    final q = f.searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      final hay =
          '${w.brand} ${w.model} ${w.collection} ${w.category}'.toLowerCase();
      if (!hay.contains(q)) return false;
    }
    if (f.brands.isNotEmpty && !f.brands.contains(w.brand)) return false;
    if (f.categories.isNotEmpty && !f.categories.contains(w.category)) {
      return false;
    }
    if (f.priceRanges.isNotEmpty &&
        !f.priceRanges.any((r) => _matchesPriceRange(w.price, r))) {
      return false;
    }
    if (f.movements.isNotEmpty && !f.movements.contains(w.movement)) {
      return false;
    }
    if (f.genders.isNotEmpty && !f.genders.contains(w.gender)) {
      return false;
    }
    if (f.conditions.isNotEmpty && !f.conditions.contains(w.condition)) {
      return false;
    }
    if (f.caseMaterials.isNotEmpty &&
        !f.caseMaterials.contains(w.caseMaterial)) {
      return false;
    }
    if (f.dialColors.isNotEmpty && !f.dialColors.contains(w.dialColor)) {
      return false;
    }
    if (f.caseSizeRanges.isNotEmpty &&
        !f.caseSizeRanges.contains(w.caseSizeRange)) {
      return false;
    }
    if (f.caseShapes.isNotEmpty && !f.caseShapes.contains(w.caseShape)) {
      return false;
    }
    if (f.caseBacks.isNotEmpty && !f.caseBacks.contains(w.caseBack)) {
      return false;
    }
    if (f.strapMaterials.isNotEmpty &&
        !f.strapMaterials.contains(w.strapMaterial)) {
      return false;
    }
    if (f.crownTypes.isNotEmpty && !f.crownTypes.contains(w.crownType)) {
      return false;
    }
    if (f.strapColors.isNotEmpty && !f.strapColors.contains(w.strapColor)) {
      return false;
    }
    if (f.claspTypes.isNotEmpty && !f.claspTypes.contains(w.claspType)) {
      return false;
    }
    if (f.glassMaterials.isNotEmpty &&
        !f.glassMaterials.contains(w.glassMaterial)) {
      return false;
    }
    if (f.powerReserves.isNotEmpty &&
        !f.powerReserves.contains(w.powerReserveRange)) {
      return false;
    }
    if (f.waterResistances.isNotEmpty &&
        !f.waterResistances.contains(waterLabel(w.waterResistanceM))) {
      return false;
    }
    if (f.authentications.isNotEmpty &&
        !f.authentications.contains(w.authentication)) {
      return false;
    }
    if (f.modelYears.isNotEmpty &&
        !f.modelYears.contains('${w.year}')) {
      return false;
    }
    if (f.certifications.isNotEmpty &&
        !f.certifications.contains(w.certification)) {
      return false;
    }
    if (f.bezelTypes.isNotEmpty && !f.bezelTypes.contains(w.bezelType)) {
      return false;
    }
    if (f.bezelMaterials.isNotEmpty &&
        !f.bezelMaterials.contains(w.bezelMaterial)) {
      return false;
    }
    if (f.stonesOnDial.isNotEmpty &&
        !f.stonesOnDial.contains('${w.stonesOnDial}')) {
      return false;
    }
    if (f.configurations.isNotEmpty &&
        !f.configurations.any(w.configurations.contains)) {
      return false;
    }
    if (f.materials.isNotEmpty && !f.materials.any(w.materials.contains)) {
      return false;
    }
    if (f.preciousStoneTypes.isNotEmpty &&
        !f.preciousStoneTypes.any(w.preciousStoneTypes.contains)) {
      return false;
    }
    if (f.indexes.isNotEmpty && !f.indexes.contains(w.indexes)) return false;
    return true;
  }

  List<Watch> _applySort(List<Watch> watches, WatchSortOption sort) {
    final sorted = List<Watch>.from(watches);
    switch (sort) {
      case WatchSortOption.featured:
        break;
      case WatchSortOption.priceLowToHigh:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case WatchSortOption.priceHighToLow:
        sorted.sort((a, b) => b.price.compareTo(a.price));
      case WatchSortOption.newest:
        sorted.sort((a, b) => b.year.compareTo(a.year));
      case WatchSortOption.brandAz:
        sorted.sort((a, b) {
          final c = a.brand.compareTo(b.brand);
          return c != 0 ? c : a.model.compareTo(b.model);
        });
    }
    return sorted;
  }

  @override
  Future<Result<WatchListResponse, Failure>> getWatches({
    required WatchFilterState filters,
    required int page,
    int pageSize = 20,
    WatchSortOption sort = WatchSortOption.featured,
  }) async {
    await Future.delayed(Duration(milliseconds: 250 + Random().nextInt(200)));
    try {
      final filtered = _catalog().where((w) => _matches(w, filters)).toList();
      final sorted = _applySort(filtered, sort);
      final start = (page - 1) * pageSize;
      final end = start + pageSize;
      final paged = start >= sorted.length
          ? <Watch>[]
          : sorted.sublist(start, end > sorted.length ? sorted.length : end);
      return Result.success(WatchListResponse(
        watches: paged,
        totalCount: filtered.length,
        hasMore: end < filtered.length,
        page: page,
      ));
    } catch (_) {
      return Result.failure(
        const NetworkFailure('Failed to load watches. Please try again.'),
      );
    }
  }
}
