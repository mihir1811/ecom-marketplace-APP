import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/models/gemstone.dart';
import '../../domain/models/gemstone_filter_state.dart';
import '../../domain/repositories/gemstone_repository.dart';
import '../../presentation/widgets/gemstone_showcase_card.dart';

final gemstoneRepositoryProvider = Provider<GemstoneRepository>(
  (ref) => GemstoneRepositoryImpl(),
);

class GemstoneRepositoryImpl implements GemstoneRepository {
  List<Gemstone>? _cache;

  static const _types = [
    'Ruby',
    'Sapphire',
    'Emerald',
    'Tanzanite',
    'Amethyst',
    'Aquamarine',
    'Topaz',
    'Garnet',
    'Opal',
    'Tourmaline',
    'Peridot',
    'Morganite',
    'Citrine',
    'Spinel',
    'Jade',
  ];

  static const _origins = [
    'Brazil',
    'Madagascar',
    'Colombia',
    'Sri Lanka',
    'Myanmar',
    'Zambia',
    'India',
    'Tanzania',
  ];

  static const _shapes = [
    'Oval',
    'Emerald',
    'Round',
    'Cushion',
    'Pear',
    'Marquise',
    'Princess',
  ];

  static const _colors = [
    'Blue',
    'Pink',
    'Green',
    'Red',
    'Purple',
    'Yellow',
    'Orange',
    'White',
  ];

  static const _clarities = ['Eye Clean', 'Slightly Included', 'Included'];
  static const _treatments = ['None', 'Heated', 'Oiled', 'Irradiated'];
  static const _labs = ['GIA', 'IGI', 'SSEF', 'Gübelin', 'AGL'];

  List<Gemstone> _catalog() {
    return _cache ??= _generate(count: 160, seed: 21);
  }

  List<Gemstone> _generate({required int count, required int seed}) {
    final rng = Random(seed);
    final list = <Gemstone>[];
    for (var i = 0; i < count; i++) {
      final type = _types[rng.nextInt(_types.length)];
      final carat = 0.4 + rng.nextDouble() * 8.5;
      final price = carat * (80 + rng.nextDouble() * 900) + rng.nextDouble() * 200;
      final length = 4 + rng.nextDouble() * 12;
      final width = 3 + rng.nextDouble() * 10;
      final depth = 2 + rng.nextDouble() * 6;
      final imagePath = gemstoneImagePath(type);

      list.add(
        Gemstone(
          id: 'GS-${100001 + i}',
          type: type,
          carat: double.parse(carat.toStringAsFixed(2)),
          price: double.parse(price.toStringAsFixed(2)),
          origin: _origins[rng.nextInt(_origins.length)],
          color: _colors[rng.nextInt(_colors.length)],
          clarity: _clarities[rng.nextInt(_clarities.length)],
          treatment: _treatments[rng.nextInt(_treatments.length)],
          shape: _shapes[rng.nextInt(_shapes.length)],
          hardness: double.parse(
            (6.5 + rng.nextDouble() * 3).toStringAsFixed(1),
          ),
          lab: '${_labs[rng.nextInt(_labs.length)]}-${9000 + rng.nextInt(999)}',
          dimensions:
              '${length.toStringAsFixed(1)}*${width.toStringAsFixed(1)}*${depth.toStringAsFixed(1)}',
          cut: rng.nextBool() ? null : 'Excellent',
          certificate: rng.nextBool() ? null : 'CERT-${20000 + i}',
          imageUrl: imagePath,
          discount: rng.nextDouble() > 0.75
              ? (5 + rng.nextInt(25)).toDouble()
              : null,
        ),
      );
    }
    return list;
  }

  bool _matches(Gemstone g, GemstoneFilterState f) {
    if (f.selectedGemstoneTypes.isNotEmpty &&
        !f.selectedGemstoneTypes.contains(g.type)) {
      return false;
    }
    if (f.selectedShapes.isNotEmpty && !f.selectedShapes.contains(g.shape)) {
      return false;
    }
    if (g.carat < f.minTotalCarat || g.carat > f.maxTotalCarat) return false;
    if (g.price < f.minPricePerPiece || g.price > f.maxPricePerPiece) {
      return false;
    }
    if (f.selectedColors.isNotEmpty && !f.selectedColors.contains(g.color)) {
      return false;
    }
    return true;
  }

  @override
  Future<Result<GemstoneListResponse, Failure>> getGemstones({
    required GemstoneFilterState filters,
    required int page,
    int pageSize = 20,
  }) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 280));
      final filtered = _catalog().where((g) => _matches(g, filters)).toList();
      final start = (page - 1) * pageSize;
      if (start >= filtered.length) {
        return Success(
          GemstoneListResponse(
            gemstones: const [],
            totalCount: filtered.length,
            hasMore: false,
            page: page,
          ),
        );
      }
      final end = (start + pageSize).clamp(0, filtered.length);
      return Success(
        GemstoneListResponse(
          gemstones: filtered.sublist(start, end),
          totalCount: filtered.length,
          hasMore: end < filtered.length,
          page: page,
        ),
      );
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }
}
