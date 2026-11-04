import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/promotions_repository_impl.dart';
import '../domain/models/promotion.dart';
import '../domain/repositories/promotions_repository.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

class SellerPromotionsState {
  const SellerPromotionsState({
    this.discounts = const [],
    this.promoCodes = const [],
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
  });

  final List<Discount> discounts;
  final List<PromoCode> promoCodes;
  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;

  SellerPromotionsState copyWith({
    List<Discount>? discounts,
    List<PromoCode>? promoCodes,
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SellerPromotionsState(
      discounts: discounts ?? this.discounts,
      promoCodes: promoCodes ?? this.promoCodes,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SellerPromotionsNotifier extends Notifier<SellerPromotionsState>
    with DisposeTolerantNotifier<SellerPromotionsState> {
  PromotionsRepository get _repo => ref.read(promotionsRepositoryProvider);

  @override
  SellerPromotionsState build() {
    Future.microtask(refresh);
    return const SellerPromotionsState(isLoading: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final discountsResult = await _repo.listDiscounts();
    if (!ref.mounted) return;
    final promoResult = await _repo.listPromoCodes();
    if (!ref.mounted) return;
    switch ((discountsResult, promoResult)) {
      case (Success(value: final discounts), Success(value: final promos)):
        state = SellerPromotionsState(discounts: discounts, promoCodes: promos);
      case (ResultFailure(failure: final f), _):
        state = SellerPromotionsState(errorMessage: f.message);
      case (_, ResultFailure(failure: final f)):
        state = SellerPromotionsState(errorMessage: f.message);
    }
  }

  Future<Result<Discount, Failure>> createDiscount(DiscountInput input) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await _repo.createDiscount(input);
    switch (result) {
      case Success(value: final discount):
        state = SellerPromotionsState(
          discounts: [...state.discounts, discount],
          promoCodes: state.promoCodes,
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isMutating: false,
          errorMessage: failure.message,
        );
    }
    return result;
  }

  Future<Result<PromoCode, Failure>> createPromoCode(
    PromoCodeInput input,
  ) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await _repo.createPromoCode(input);
    switch (result) {
      case Success(value: final promo):
        state = SellerPromotionsState(
          discounts: state.discounts,
          promoCodes: [...state.promoCodes, promo],
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isMutating: false,
          errorMessage: failure.message,
        );
    }
    return result;
  }

  Future<Result<Discount, Failure>> deleteDiscount(String id) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await _repo.deleteDiscount(id);
    switch (result) {
      case Success():
        state = SellerPromotionsState(
          discounts: state.discounts.where((d) => d.id != id).toList(),
          promoCodes: state.promoCodes,
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isMutating: false,
          errorMessage: failure.message,
        );
    }
    return result;
  }

  Future<Result<PromoCode, Failure>> deletePromoCode(String id) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await _repo.deletePromoCode(id);
    switch (result) {
      case Success():
        state = SellerPromotionsState(
          discounts: state.discounts,
          promoCodes: state.promoCodes.where((p) => p.id != id).toList(),
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isMutating: false,
          errorMessage: failure.message,
        );
    }
    return result;
  }
}

final sellerPromotionsProvider =
    NotifierProvider<SellerPromotionsNotifier, SellerPromotionsState>(
      SellerPromotionsNotifier.new,
    );
