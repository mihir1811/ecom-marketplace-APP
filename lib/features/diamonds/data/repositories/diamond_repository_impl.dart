import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../core/error/failure.dart';
import '../../domain/models/diamond.dart';
import '../../domain/models/diamond_filter_state.dart';
import '../../domain/models/sorting_criteria.dart';
import '../../domain/repositories/diamond_repository.dart';

final diamondRepositoryProvider = Provider<DiamondRepository>(
  (ref) => DiamondRepositoryImpl(),
);

class DiamondRepositoryImpl implements DiamondRepository {
  List<Diamond>? _naturalCache;
  List<Diamond>? _labGrownCache;

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

  static const _naturalCertificates = ['GIA', 'HRD', 'IGI', 'EGL', 'AGS'];
  static const _labGrownCertificates = ['IGI', 'GCAL', 'GIA', 'HRD'];

  static const _polish = ['Ideal', 'Excellent', 'Very Good', 'Good'];
  static const _symmetry = ['Ideal', 'Excellent', 'Very Good', 'Good'];
  static const _fluorescence = ['None', 'Faint', 'Medium', 'Strong'];

  List<Diamond> _generateCatalog({
    required bool isLabGrown,
    required int count,
    required int seed,
    required String idPrefix,
    required List<String> certificates,
    required double caratMin,
    required double caratSpan,
    required double basePricePerCarat,
    required double priceNoise,
  }) {
    final rng = Random(seed);
    final diamonds = <Diamond>[];

    for (int i = 0; i < count; i++) {
      final shape = _shapes[rng.nextInt(_shapes.length)];
      final carat = caratMin + rng.nextDouble() * caratSpan;
      final basePrice = carat * basePricePerCarat + rng.nextDouble() * priceNoise;
      final cut = _cuts[rng.nextInt(_cuts.length)];
      final colorIdx = rng.nextInt(_colors.length);
      final color = _colors[colorIdx];
      final clarity = _clarities[rng.nextInt(_clarities.length)];
      final certificate = certificates[rng.nextInt(certificates.length)];
      final price = basePrice * (1.0 + (10 - colorIdx) * 0.05);
      final hasDiscount = rng.nextDouble() > (isLabGrown ? 0.55 : 0.7);
      final discount = hasDiscount ? (5 + rng.nextInt(40)).toDouble() : null;

      diamonds.add(Diamond(
        id: '$idPrefix-${100001 + i}',
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
        isLabGrown: isLabGrown,
      ));
    }

    return diamonds;
  }

  List<Diamond> _naturalDiamonds() {
    return _naturalCache ??= _generateCatalog(
      isLabGrown: false,
      count: 215,
      seed: 42,
      idPrefix: 'DM',
      certificates: _naturalCertificates,
      caratMin: 0.2,
      caratSpan: 9.8,
      basePricePerCarat: 3000,
      priceNoise: 20000,
    );
  }

  List<Diamond> _labGrownDiamonds() {
    return _labGrownCache ??= _generateCatalog(
      isLabGrown: true,
      count: 180,
      seed: 84,
      idPrefix: 'LG',
      certificates: _labGrownCertificates,
      caratMin: 0.18,
      caratSpan: 7.5,
      basePricePerCarat: 900,
      priceNoise: 6000,
    );
  }

  bool _matchesFilters(Diamond d, DiamondFilterState f) {
    if (f.shapes.isNotEmpty && !f.shapes.contains(d.shape)) return false;
    if (d.price < f.minPrice || d.price > f.maxPrice) return false;
    if (d.pricePerCarat != null) {
      if (d.pricePerCarat! < f.minPricePerCarat ||
          d.pricePerCarat! > f.maxPricePerCarat) {
        return false;
      }
    }
    if (d.carat < f.minCarat || d.carat > f.maxCarat) return false;

    final colorIdx = _colors.indexOf(d.color);
    if (colorIdx >= 0) {
      if (colorIdx < f.minColorIndex || colorIdx > f.maxColorIndex) return false;
    }
    if (f.selectedStandardColors.isNotEmpty &&
        !f.selectedStandardColors.contains(d.color)) {
      return false;
    }

    final clarityIdx = _clarities.indexOf(d.clarity);
    if (clarityIdx >= 0) {
      if (clarityIdx < f.minClarityIndex || clarityIdx > f.maxClarityIndex) {
        return false;
      }
    }
    if (f.selectedClarityGrades.isNotEmpty &&
        !f.selectedClarityGrades.contains(d.clarity)) {
      return false;
    }
    if (f.selectedCuts.isNotEmpty && !f.selectedCuts.contains(d.cut)) {
      return false;
    }
    if (f.selectedPolish.isNotEmpty &&
        d.polish != null &&
        !f.selectedPolish.contains(d.polish)) {
      return false;
    }
    if (f.selectedSymmetry.isNotEmpty &&
        d.symmetry != null &&
        !f.selectedSymmetry.contains(d.symmetry)) {
      return false;
    }
    if (f.selectedFluorescence.isNotEmpty &&
        d.fluorescence != null &&
        !f.selectedFluorescence.contains(d.fluorescence)) {
      return false;
    }
    if (f.selectedLabs.isNotEmpty &&
        d.lab != null &&
        !f.selectedLabs.contains(d.lab)) {
      return false;
    }
    if (f.eyeClean) {
      if (!['FL', 'IF', 'VVS1', 'VVS2', 'VS1'].contains(d.clarity)) return false;
    }
    if (f.searchByMedia && !d.hasVideo && !d.hasImage) return false;

    return true;
  }

  Comparable _sortValue(Diamond d, String fieldKey) {
    return switch (fieldKey) {
      'price' => d.price,
      'pricePerCarat' => d.pricePerCarat ?? 0,
      'carat' => d.carat,
      'discount' => d.discount ?? 0,
      'color' => _colors.indexOf(d.color),
      'clarity' => _clarities.indexOf(d.clarity),
      'cut' => _cuts.indexOf(d.cut),
      'polish' =>
        d.polish != null ? _polish.indexOf(d.polish!) : _polish.length,
      'symmetry' =>
        d.symmetry != null ? _symmetry.indexOf(d.symmetry!) : _symmetry.length,
      'shape' => d.shape,
      'fluorescence' => d.fluorescence != null
          ? _fluorescence.indexOf(d.fluorescence!)
          : _fluorescence.length,
      _ => d.id,
    };
  }

  List<Diamond> _applyMultiSort(
    List<Diamond> diamonds,
    List<SortingCriteria> sorting,
  ) {
    if (sorting.isEmpty) return diamonds;

    final sorted = List<Diamond>.from(diamonds);
    sorted.sort((a, b) {
      for (final criteria in sorting) {
        final aVal = _sortValue(a, criteria.fieldKey);
        final bVal = _sortValue(b, criteria.fieldKey);
        var cmp = aVal.compareTo(bVal);
        if (criteria.direction == SortDirection.descending) cmp = -cmp;
        if (cmp != 0) return cmp;
      }
      return 0;
    });
    return sorted;
  }

  @override
  Future<Result<DiamondListResponse, Failure>> getDiamonds({
    required DiamondFilterState filters,
    required int page,
    int pageSize = 20,
    List<SortingCriteria> sorting = const [],
    bool isLabGrown = false,
  }) async {
    await Future.delayed(Duration(milliseconds: 300 + Random().nextInt(200)));

    try {
      final all = isLabGrown ? _labGrownDiamonds() : _naturalDiamonds();
      final filtered = all.where((d) => _matchesFilters(d, filters)).toList();
      final sorted = _applyMultiSort(filtered, sorting);

      final start = (page - 1) * pageSize;
      final end = start + pageSize;
      final paged =
          sorted.sublist(start, end > sorted.length ? sorted.length : end);

      return Result.success(DiamondListResponse(
        diamonds: paged,
        totalCount: filtered.length,
        hasMore: end < filtered.length,
        page: page,
      ));
    } catch (e) {
      return Result.failure(
        const NetworkFailure('Failed to load diamonds. Please try again.'),
      );
    }
  }
}
