import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/models/jewelry.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/repositories/jewelry_repository.dart';

final jewelryRepositoryProvider = Provider<JewelryRepository>(
  (ref) => JewelryRepositoryImpl(),
);

class JewelryRepositoryImpl implements JewelryRepository {
  List<Jewelry>? _cache;

  static const _categoryAssets = {
    'Bracelets': 'public/images/jewelryCategoryImages/bracelet.webp',
    'Necklaces': 'public/images/jewelryCategoryImages/necklace.webp',
    'Earrings': 'public/images/jewelryCategoryImages/earrings.webp',
    'Rings': 'public/images/jewelryCategoryImages/ring.webp',
    'Chains': 'public/images/jewelryCategoryImages/necklace.webp',
    'Pendants': 'public/images/jewelryCategoryImages/necklace.webp',
    'Anklets': 'public/images/jewelryCategoryImages/bracelet.webp',
    'Nose Pins': 'public/images/jewelryCategoryImages/earrings.webp',
    'Mangalsutra': 'public/images/jewelryCategoryImages/necklace.webp',
    'All Accessories': 'public/images/jewelryCategoryImages/set.webp',
  };

  static const _names = [
    'Natural Diamond Solitaire Ring',
    'Pearl Pendant Necklace',
    'Rose Gold Bracelet',
    'Emerald Drop Earrings',
    'Classic Gold Chain',
    'Center Stone Showcase Accessories',
    'Halo Diamond Ring',
    'Temple Work Necklace',
    'Delicate Anklet',
    'Traditional Mangalsutra',
  ];

  static const _badges = [
    'New',
    'Best Seller',
    'Trending',
    'Limited Edition',
    'Exclusive',
    null,
    null,
    null,
  ];

  List<Jewelry> _catalog() => _cache ??= _generateCatalog();

  List<Jewelry> _generateCatalog() {
    final rng = Random(42);
    final items = <Jewelry>[];
    var id = 20001;
    final categories = JewelryFilterState.parentCategories
        .where((c) => c != 'All Accessories')
        .toList();

    for (var i = 0; i < 120; i++) {
      final category = categories[rng.nextInt(categories.length)];
      final subs = JewelryFilterState.subCategoriesFor(category);
      final subCategory =
          subs.isEmpty ? null : subs[rng.nextInt(subs.length)];
      final metalColor = JewelryFilterState.metalColorOptions[
          rng.nextInt(JewelryFilterState.metalColorOptions.length)];
      final metalType = JewelryFilterState.metalTypeOptions[
          rng.nextInt(JewelryFilterState.metalTypeOptions.length)];
      final variants = <String>{metalColor};
      while (variants.length < 2 + rng.nextInt(3)) {
        variants.add(JewelryFilterState.metalColorOptions[
            rng.nextInt(JewelryFilterState.metalColorOptions.length)]);
      }
      final price = 8000 + rng.nextDouble() * 180000;
      final hasDiscount = rng.nextDouble() > 0.7;
      final rating = 3.8 + rng.nextDouble() * 1.2;
      final stoneCategory = JewelryFilterState.stoneCategoryOptions[
          rng.nextInt(JewelryFilterState.stoneCategoryOptions.length)];
      final stoneCount = stoneCategory == 'None'
          ? 0
          : 1 + rng.nextInt(4);
      final braceletSize = category == 'Bracelets'
          ? JewelryFilterState.braceletSizeOptions[
              rng.nextInt(JewelryFilterState.braceletSizeOptions.length)]
          : null;
      final braceletLength = category == 'Bracelets'
          ? JewelryFilterState.braceletLengthOptions[
              rng.nextInt(JewelryFilterState.braceletLengthOptions.length)]
          : null;
      final chainLength = category == 'Chains'
          ? JewelryFilterState.chainLengthOptions[
              rng.nextInt(JewelryFilterState.chainLengthOptions.length)]
          : null;
      final necklaceLength = category == 'Necklaces'
          ? JewelryFilterState.necklaceLengthOptions[
              rng.nextInt(JewelryFilterState.necklaceLengthOptions.length)]
          : null;
      final ringSize = category == 'Rings'
          ? JewelryFilterState.ringSizeOptions[
              rng.nextInt(JewelryFilterState.ringSizeOptions.length)]
          : null;
      final sizeOptions = switch (category) {
        'Bracelets' => List<String>.from(
            JewelryFilterState.braceletSizeOptions,
          )..shuffle(rng),
        'Chains' => List<String>.from(JewelryFilterState.chainLengthOptions)
          ..shuffle(rng),
        'Necklaces' => List<String>.from(
            JewelryFilterState.necklaceLengthOptions,
          )..shuffle(rng),
        'Rings' => List<String>.from(JewelryFilterState.ringSizeOptions)
          ..shuffle(rng),
        _ => <String>[],
      };
      if (sizeOptions.length > 4) {
        sizeOptions.removeRange(4, sizeOptions.length);
      }
      final skuPrefix = category.length >= 4
          ? category.substring(0, 4).toUpperCase()
          : category.toUpperCase();

      items.add(Jewelry(
        id: 'J-$id',
        sku: '$skuPrefix-${(100 + i).toString().padLeft(3, '0')}',
        name: '${_names[rng.nextInt(_names.length)]} — $category',
        category: category,
        subCategory: subCategory,
        price: double.parse(price.toStringAsFixed(0)),
        metalType: metalType,
        metalColor: metalColor,
        metalPurity: JewelryFilterState.metalPurityOptions[
            rng.nextInt(JewelryFilterState.metalPurityOptions.length)],
        gender: JewelryFilterState
            .genderOptions[rng.nextInt(JewelryFilterState.genderOptions.length)],
        occasion: JewelryFilterState.occasionOptions[
            rng.nextInt(JewelryFilterState.occasionOptions.length)],
        condition: JewelryFilterState.conditionOptions[
            rng.nextInt(JewelryFilterState.conditionOptions.length)],
        availability: JewelryFilterState.availabilityOptions[
            rng.nextInt(JewelryFilterState.availabilityOptions.length)],
        stoneType: JewelryFilterState
            .stoneTypeOptions[rng.nextInt(JewelryFilterState.stoneTypeOptions.length)],
        stoneCategory: stoneCategory,
        stoneShape: JewelryFilterState.stoneShapeOptions[
            rng.nextInt(JewelryFilterState.stoneShapeOptions.length)],
        certification: JewelryFilterState.certificationOptions[
            rng.nextInt(JewelryFilterState.certificationOptions.length)],
        metalWeightG: 1 + rng.nextDouble() * 40,
        stoneWeightCt: rng.nextDouble() * 8,
        stoneCount: stoneCount,
        colorVariants: variants.toList(),
        sizeOptions: sizeOptions,
        braceletSize: braceletSize,
        braceletLength: braceletLength,
        chainLength: chainLength,
        necklaceLength: necklaceLength,
        ringSize: ringSize,
        badge: _badges[rng.nextInt(_badges.length)],
        imageAsset: _categoryAssets[category] ?? _categoryAssets['All Accessories'],
        discount: hasDiscount ? (8 + rng.nextInt(25)).toDouble() : null,
        hasMedia: rng.nextDouble() > 0.08,
        rating: double.parse(rating.toStringAsFixed(1)),
        reviewCount: 12 + rng.nextInt(400),
      ));
      id++;
    }
    return items;
  }

  bool _matches(Jewelry j, JewelryFilterState f) {
    final q = f.searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      final hay =
          '${j.name} ${j.sku} ${j.category} ${j.metalType} ${j.metalPurity} ${j.stoneCategory} ${j.id}'
              .toLowerCase();
      if (!hay.contains(q)) return false;
    }
    if (f.category != null &&
        f.category != 'All Accessories' &&
        j.category != f.category) {
      return false;
    }
    if (f.subCategories.isNotEmpty &&
        (j.subCategory == null || !f.subCategories.contains(j.subCategory))) {
      return false;
    }
    if (f.availability.isNotEmpty && !f.availability.contains(j.availability)) {
      return false;
    }
    if (f.withMediaOnly && !j.hasMedia) return false;
    if (f.genders.isNotEmpty && !f.genders.contains(j.gender)) return false;
    if (j.price < f.priceMin || j.price > f.priceMax) return false;
    if (f.occasions.isNotEmpty && !f.occasions.contains(j.occasion)) {
      return false;
    }
    if (f.metalTypes.isNotEmpty && !f.metalTypes.contains(j.metalType)) {
      return false;
    }
    if (f.metalColors.isNotEmpty && !f.metalColors.contains(j.metalColor)) {
      return false;
    }
    if (f.metalPurities.isNotEmpty && !f.metalPurities.contains(j.metalPurity)) {
      return false;
    }
    if (j.metalWeightG < f.metalWeightMin || j.metalWeightG > f.metalWeightMax) {
      return false;
    }
    if (f.stoneType != null && j.stoneType != f.stoneType) return false;
    if (f.stoneCategories.isNotEmpty &&
        !f.stoneCategories.contains(j.stoneCategory)) {
      return false;
    }
    if (f.stoneShapes.isNotEmpty && !f.stoneShapes.contains(j.stoneShape)) {
      return false;
    }
    if (j.stoneWeightCt < f.stoneWeightMin ||
        j.stoneWeightCt > f.stoneWeightMax) {
      return false;
    }
    if (f.braceletSizes.isNotEmpty &&
        (j.braceletSize == null ||
            !f.braceletSizes.contains(j.braceletSize))) {
      return false;
    }
    if (f.braceletLengths.isNotEmpty &&
        (j.braceletLength == null ||
            !f.braceletLengths.contains(j.braceletLength))) {
      return false;
    }
    if (f.chainLengths.isNotEmpty &&
        (j.chainLength == null || !f.chainLengths.contains(j.chainLength))) {
      return false;
    }
    if (f.necklaceLengths.isNotEmpty &&
        (j.necklaceLength == null ||
            !f.necklaceLengths.contains(j.necklaceLength))) {
      return false;
    }
    if (f.ringSizes.isNotEmpty &&
        (j.ringSize == null || !f.ringSizes.contains(j.ringSize))) {
      return false;
    }
    if (f.certifications.isNotEmpty &&
        !f.certifications.contains(j.certification)) {
      return false;
    }
    if (f.conditions.isNotEmpty && !f.conditions.contains(j.condition)) {
      return false;
    }
    return true;
  }

  List<Jewelry> _applySort(List<Jewelry> items, JewelrySortOption sort) {
    final sorted = List<Jewelry>.from(items);
    switch (sort) {
      case JewelrySortOption.featured:
        break;
      case JewelrySortOption.newest:
        sorted.sort((a, b) => b.id.compareTo(a.id));
      case JewelrySortOption.priceLowToHigh:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case JewelrySortOption.priceHighToLow:
        sorted.sort((a, b) => b.price.compareTo(a.price));
      case JewelrySortOption.popularity:
      case JewelrySortOption.bestSelling:
        sorted.sort(
          (a, b) => (b.reviewCount ?? 0).compareTo(a.reviewCount ?? 0),
        );
      case JewelrySortOption.highestRated:
        sorted.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      case JewelrySortOption.discount:
        sorted.sort(
          (a, b) => (b.discount ?? 0).compareTo(a.discount ?? 0),
        );
    }
    return sorted;
  }

  @override
  Future<Result<JewelryListResponse, Failure>> getJewelry({
    required JewelryFilterState filters,
    required int page,
    int pageSize = 20,
    JewelrySortOption sort = JewelrySortOption.featured,
  }) async {
    await Future.delayed(Duration(milliseconds: 220 + Random().nextInt(180)));
    try {
      final filtered = _catalog().where((j) => _matches(j, filters)).toList();
      final sorted = _applySort(filtered, sort);
      final start = (page - 1) * pageSize;
      final end = start + pageSize;
      final paged = start >= sorted.length
          ? <Jewelry>[]
          : sorted.sublist(start, end > sorted.length ? sorted.length : end);
      return Result.success(JewelryListResponse(
        items: paged,
        totalCount: filtered.length,
        hasMore: end < filtered.length,
        page: page,
      ));
    } catch (_) {
      return Result.failure(
        const NetworkFailure('Failed to load jewelry. Please try again.'),
      );
    }
  }
}
