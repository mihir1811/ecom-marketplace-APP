import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../core/error/failure.dart';
import '../../application/diamond_list_provider.dart';
import '../../domain/models/diamond.dart';
import '../../domain/models/diamond_filter_state.dart';
import '../../domain/repositories/diamond_repository.dart';

final diamondRepositoryProvider = Provider<DiamondRepository>(
  (ref) => DiamondRepositoryImpl(),
);

class DiamondRepositoryImpl implements DiamondRepository {
  List<Diamond>? _cache;

  static const _shapes = [
    'Round', 'Cushion', 'Emerald', 'Pear', 'Oval', 'Princess',
    'Marquise', 'Heart', 'Radiant', 'Asscher', 'Trilliant',
  ];

  static const _cuts = ['Ideal', 'Excellent', 'Very Good', 'Good', 'Fair'];

  static const _colors = [
    'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  ];

  static const _clarities = [
    'FL', 'IF', 'VVS1', 'VVS2', 'VS1', 'VS2', 'SI1', 'SI2',
  ];

  static const _certificates = ['GIA', 'HRD', 'IGI', 'EGL', 'AGS'];

  static const _polish = ['Ideal', 'Excellent', 'Very Good', 'Good'];
  static const _symmetry = ['Ideal', 'Excellent', 'Very Good', 'Good'];
  static const _fluorescence = ['None', 'Faint', 'Medium', 'Strong'];

  List<Diamond> _generateDiamonds() {
    if (_cache != null) return _cache!;
    final rng = Random(42);
    final diamonds = <Diamond>[];

    for (int i = 0; i < 215; i++) {
      final shape = _shapes[rng.nextInt(_shapes.length)];
      final carat = 0.2 + rng.nextDouble() * 9.8;
      final basePrice = carat * 3000 + rng.nextDouble() * 20000;
      final cut = _cuts[rng.nextInt(_cuts.length)];
      final colorIdx = rng.nextInt(_colors.length);
      final color = _colors[colorIdx];
      final clarity = _clarities[rng.nextInt(_clarities.length)];
      final certificate = _certificates[rng.nextInt(_certificates.length)];
      final price = basePrice * (1.0 + (10 - colorIdx) * 0.05);
      final hasDiscount = rng.nextDouble() > 0.7;
      final discount = hasDiscount ? (5 + rng.nextInt(40)).toDouble() : null;

      diamonds.add(Diamond(
        id: 'DM-${100001 + i}',
        shape: shape,
        carat: double.parse(carat.toStringAsFixed(2)),
        price: double.parse(price.toStringAsFixed(2)),
        cut: cut,
        color: color,
        clarity: clarity,
        certificate: certificate,
        pricePerCarat: double.parse((price / carat).toStringAsFixed(2)),
        polish: _polish[rng.nextInt(_polish.length)],
        symmetry: _symmetry[rng.nextInt(_symmetry.length)],
        fluorescence: _fluorescence[rng.nextInt(_fluorescence.length)],
        lab: certificate,
        hasVideo: rng.nextDouble() > 0.6,
        hasImage: rng.nextDouble() > 0.3,
        discount: discount,
      ));
    }

    _cache = diamonds;
    return diamonds;
  }

  bool _matchesFilters(Diamond d, DiamondFilterState f) {
    if (f.shapes.isNotEmpty && !f.shapes.contains(d.shape)) return false;
    if (d.price < f.minPrice || d.price > f.maxPrice) return false;
    if (d.pricePerCarat != null) {
      if (d.pricePerCarat! < f.minPricePerCarat || d.pricePerCarat! > f.maxPricePerCarat) return false;
    }
    if (d.carat < f.minCarat || d.carat > f.maxCarat) return false;

    final colorIdx = _colors.indexOf(d.color);
    if (colorIdx >= 0) {
      if (colorIdx < f.minColorIndex || colorIdx > f.maxColorIndex) return false;
    }
    if (f.selectedStandardColors.isNotEmpty && !f.selectedStandardColors.contains(d.color)) return false;

    final clarityIdx = _clarities.indexOf(d.clarity);
    if (clarityIdx >= 0) {
      if (clarityIdx < f.minClarityIndex || clarityIdx > f.maxClarityIndex) return false;
    }
    if (f.selectedClarityGrades.isNotEmpty && !f.selectedClarityGrades.contains(d.clarity)) return false;
    if (f.selectedCuts.isNotEmpty && !f.selectedCuts.contains(d.cut)) return false;
    if (f.selectedPolish.isNotEmpty && d.polish != null && !f.selectedPolish.contains(d.polish)) return false;
    if (f.selectedSymmetry.isNotEmpty && d.symmetry != null && !f.selectedSymmetry.contains(d.symmetry)) return false;
    if (f.selectedFluorescence.isNotEmpty && d.fluorescence != null && !f.selectedFluorescence.contains(d.fluorescence)) return false;
    if (f.selectedLabs.isNotEmpty && d.lab != null && !f.selectedLabs.contains(d.lab)) return false;
    if (f.eyeClean) {
      if (!['FL', 'IF', 'VVS1', 'VVS2', 'VS1'].contains(d.clarity)) return false;
    }
    if (f.sellersWithVideo && !d.hasVideo) return false;
    if (f.sellersWithImages && !d.hasImage) return false;

    return true;
  }

  Comparable _sortValue(Diamond d, DiamondSortField sort) {
    return switch (sort) {
      DiamondSortField.priceLowHigh => d.price,
      DiamondSortField.priceHighLow => -d.price,
      DiamondSortField.caratLowHigh => d.carat,
      DiamondSortField.caratHighLow => -d.carat,
      DiamondSortField.pricePerCaratLowHigh => d.pricePerCarat ?? 0,
      DiamondSortField.pricePerCaratHighLow => -(d.pricePerCarat ?? 0),
      DiamondSortField.discountHighLow => -(d.discount ?? 0),
      DiamondSortField.popularity => -(d.certificate.length * 100 + d.color.codeUnitAt(0)),
      DiamondSortField.newest => -int.parse(d.id.split('-').last),
      DiamondSortField.cutBestWorst => _cuts.indexOf(d.cut),
      DiamondSortField.colorBestWorst => _colors.indexOf(d.color),
      DiamondSortField.clarityBestWorst => _clarities.indexOf(d.clarity),
      DiamondSortField.shapeAZ => d.shape,
    };
  }

  List<Diamond> _applySorts(List<Diamond> diamonds, DiamondSortField primary, DiamondSortField? secondary) {
    final sorted = List<Diamond>.from(diamonds);
    sorted.sort((a, b) {
      final cmp = _sortValue(a, primary).compareTo(_sortValue(b, primary));
      if (cmp != 0 || secondary == null) return cmp;
      return _sortValue(a, secondary).compareTo(_sortValue(b, secondary));
    });
    return sorted;
  }

  @override
  Future<Result<DiamondListResponse, Failure>> getDiamonds({
    required DiamondFilterState filters,
    required int page,
    int pageSize = 20,
    required DiamondSortField primarySort,
    DiamondSortField? secondarySort,
  }) async {
    await Future.delayed(Duration(milliseconds: 300 + Random().nextInt(200)));

    try {
      final all = _generateDiamonds();
      final filtered = all.where((d) => _matchesFilters(d, filters)).toList();

      final sorted = _applySorts(filtered, primarySort, secondarySort);

      final start = (page - 1) * pageSize;
      final end = start + pageSize;
      final paged = sorted.sublist(start, end > sorted.length ? sorted.length : end);

      return Result.success(DiamondListResponse(
        diamonds: paged,
        totalCount: filtered.length,
        hasMore: end < filtered.length,
        page: page,
      ));
    } catch (e) {
      return Result.failure(const NetworkFailure('Failed to load diamonds. Please try again.'));
    }
  }
}
