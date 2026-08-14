import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/jewellery_category_admin_repository_impl.dart';
import '../domain/models/jewellery_category_admin.dart';

/// Active jewellery categories for the shopper grid and listing chips.
final jewelleryCategoriesProvider =
    FutureProvider<List<JewelleryCategoryAdmin>>((ref) async {
  final repo = ref.watch(jewelleryCategoryAdminRepositoryProvider);
  final result = await repo.list(page: 1, limit: 50);
  return switch (result) {
    Success(value: final page) => [
        for (final category in page.items)
          if (category.isActive && category.name.trim().isNotEmpty) category,
      ],
    ResultFailure(failure: final failure) => throw failure,
  };
});
