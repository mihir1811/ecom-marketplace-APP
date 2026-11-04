import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/product_share_repository_impl.dart';
import '../domain/models/product_share.dart';
import '../domain/repositories/product_share_repository.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

class ProductShareController extends Notifier<AsyncValue<void>>
    with DisposeTolerantNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  ProductShareRepository get _repo => ref.read(productShareRepositoryProvider);

  Future<Result<ProductShareLink, Failure>> create({
    required String productType,
    required String productId,
    required ProductShareChannel channel,
    bool includePrice = true,
    bool includeImages = true,
    bool includeVideos = true,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.create(
      productType: productType,
      productId: productId,
      channel: channel,
      includePrice: includePrice,
      includeImages: includeImages,
      includeVideos: includeVideos,
    );
    state = switch (result) {
      Success() => const AsyncValue.data(null),
      ResultFailure(failure: final failure) => AsyncValue.error(
        failure,
        StackTrace.current,
      ),
    };
    return result;
  }

  Future<Result<ProductShareEmailResult, Failure>> sendEmail({
    required String shareId,
    required String email,
    String? name,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.sendEmail(
      shareId: shareId,
      email: email,
      name: name,
    );
    state = switch (result) {
      Success() => const AsyncValue.data(null),
      ResultFailure(failure: final failure) => AsyncValue.error(
        failure,
        StackTrace.current,
      ),
    };
    return result;
  }
}

final productShareControllerProvider =
    NotifierProvider<ProductShareController, AsyncValue<void>>(
      ProductShareController.new,
    );
