import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/wishlist_item.dart';

/// Contract for authenticated `/favorites` APIs.
abstract class FavoritesRepository {
  Future<Result<WishlistItem, Failure>> add({
    required String productId,
    required String productType,
    CancelToken? cancelToken,
  });

  Future<Result<WishlistPage, Failure>> list({
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  });

  Future<Result<WishlistItem, Failure>> getOne({
    required String productId,
    required String productType,
    CancelToken? cancelToken,
  });

  Future<Result<void, Failure>> remove({
    required String productId,
    required String productType,
    CancelToken? cancelToken,
  });
}
