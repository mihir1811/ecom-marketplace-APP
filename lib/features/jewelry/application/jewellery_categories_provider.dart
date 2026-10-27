import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/repositories/jewelry_repository_impl.dart';
import '../domain/models/marketplace_listing.dart';

/// Marketplace categories (with their styles) for the house grid, style
/// chips and results titles.
final jewelleryCategoriesProvider = FutureProvider<List<MarketplaceCategory>>((
  ref,
) async {
  final result = await ref.watch(jewelryRepositoryProvider).getCategories();
  return switch (result) {
    Success(value: final items) => items,
    ResultFailure(failure: final failure) => throw failure,
  };
});
