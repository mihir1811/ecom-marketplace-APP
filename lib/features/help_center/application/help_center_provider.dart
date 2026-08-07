import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/help_center_repository_impl.dart';
import '../domain/models/help_question.dart';
import '../domain/repositories/help_center_repository.dart';

class HelpQuestionListState {
  const HelpQuestionListState({
    this.items = const [],
    this.total = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<HelpQuestion> items;
  final int total;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  HelpQuestionListState copyWith({
    List<HelpQuestion>? items,
    int? total,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HelpQuestionListState(
      items: items ?? this.items,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class HelpQuestionListNotifier extends Notifier<HelpQuestionListState> {
  CancelToken? _cancelToken;

  @override
  HelpQuestionListState build() {
    ref.onDispose(() => _cancelToken?.cancel());
    Future.microtask(refresh);
    return const HelpQuestionListState(isLoading: true);
  }

  HelpCenterRepository get _repo => ref.read(helpCenterRepositoryProvider);

  Future<void> refresh() async {
    _cancelToken?.cancel('refresh');
    _cancelToken = CancelToken();
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repo.listMyQuestions(
      page: 1,
      cancelToken: _cancelToken,
    );

    switch (result) {
      case Success(value: final page):
        state = HelpQuestionListState(
          items: page.items,
          total: page.total,
          currentPage: page.currentPage,
          hasMore: page.hasMore,
        );
      case ResultFailure(failure: final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.currentPage + 1;

    final result = await _repo.listMyQuestions(page: nextPage);

    switch (result) {
      case Success(value: final page):
        state = state.copyWith(
          items: [...state.items, ...page.items],
          total: page.total,
          currentPage: page.currentPage,
          hasMore: page.hasMore,
          isLoadingMore: false,
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        );
    }
  }
}

final helpQuestionListProvider =
    NotifierProvider<HelpQuestionListNotifier, HelpQuestionListState>(
  HelpQuestionListNotifier.new,
);

class HelpCenterMutationNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<Result<HelpQuestion, Failure>> create({
    required HelpIssueType issueType,
    required String subject,
    required String body,
  }) async {
    state = const AsyncValue.loading();
    final result = await ref.read(helpCenterRepositoryProvider).createQuestion(
          issueType: issueType,
          subject: subject,
          body: body,
        );

    state = switch (result) {
      Success() => const AsyncValue.data(null),
      ResultFailure(failure: final failure) =>
        AsyncValue.error(failure, StackTrace.current),
    };

    if (result case Success()) {
      ref.invalidate(helpQuestionListProvider);
    }

    return result;
  }

  Future<Result<HelpQuestion, Failure>> close({required String id}) async {
    state = const AsyncValue.loading();
    final result =
        await ref.read(helpCenterRepositoryProvider).closeQuestion(id: id);

    state = switch (result) {
      Success() => const AsyncValue.data(null),
      ResultFailure(failure: final failure) =>
        AsyncValue.error(failure, StackTrace.current),
    };

    if (result case Success()) {
      ref.invalidate(helpQuestionListProvider);
    }

    return result;
  }
}

final helpCenterMutationProvider =
    NotifierProvider<HelpCenterMutationNotifier, AsyncValue<void>>(
  HelpCenterMutationNotifier.new,
);
