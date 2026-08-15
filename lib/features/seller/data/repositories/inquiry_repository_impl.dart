import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/inquiry_list_page.dart';
import '../../domain/models/seller_inquiry.dart';
import '../../domain/repositories/inquiry_repository.dart';
import '../mappers/inquiry_mapper.dart';

final inquiryRepositoryProvider = Provider<InquiryRepository>(
  (ref) => InquiryRepositoryImpl(ref.watch(dioProvider)),
);

class InquiryRepositoryImpl implements InquiryRepository {
  InquiryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<InquiryListPage, Failure>> listInquiries({
    required InquiryCategory category,
    required int page,
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _listPath(category),
        queryParameters: {
          'page': page < 1 ? 1 : page,
          'limit': limit < 1 ? 10 : limit,
        },
        cancelToken: cancelToken,
      );

      final root = response.data ?? const <String, dynamic>{};
      final dataNode = root['data'];
      final payload = dataNode is Map<String, dynamic>
          ? dataNode
          : const <String, dynamic>{};
      final itemsJson = payload['data'];
      final metaJson = payload['meta'];
      final meta =
          metaJson is Map<String, dynamic> ? metaJson : const <String, dynamic>{};

      final list = itemsJson is List ? itemsJson : const [];
      final items = <SellerInquiry>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final inquiry = InquiryMapper.fromJson(item, category: category);
        if (inquiry.id.isEmpty) continue;
        items.add(inquiry);
      }

      final total = _asInt(meta['total']) ?? items.length;
      final currentPage = _asInt(meta['currentPage']) ?? page;
      final lastPage = _asInt(meta['lastPage']) ?? currentPage;
      final perPage = _asInt(meta['perPage']) ?? limit;
      final hasMore = meta.containsKey('next')
          ? meta['next'] != null
          : currentPage < lastPage;

      return Result.success(
        InquiryListPage(
          items: items,
          total: total,
          currentPage: currentPage,
          lastPage: lastPage,
          perPage: perPage,
          hasMore: hasMore,
        ),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<SellerInquiry, Failure>> getInquiry({
    required InquiryCategory category,
    required String id,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _detailPath(category, id),
        cancelToken: cancelToken,
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const ValidationFailure('Inquiry not found.'),
        );
      }
      return Result.success(InquiryMapper.fromJson(data, category: category));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<SellerInquiry, Failure>> createInquiry({
    required InquiryCategory category,
    required Map<String, dynamic> body,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _createPath(category),
        data: body,
        cancelToken: cancelToken,
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const UnknownFailure('Unexpected create response.'),
        );
      }
      return Result.success(InquiryMapper.fromJson(data, category: category));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<SellerInquiry, Failure>> updateInquiry({
    required InquiryCategory category,
    required String id,
    required Map<String, dynamic> body,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        _detailPath(category, id),
        data: body,
        cancelToken: cancelToken,
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const UnknownFailure('Unexpected update response.'),
        );
      }
      return Result.success(InquiryMapper.fromJson(data, category: category));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deleteInquiry({
    required InquiryCategory category,
    required String id,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        _detailPath(category, id),
        cancelToken: cancelToken,
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  String _listPath(InquiryCategory category) => switch (category) {
        InquiryCategory.diamond => ApiEndpoints.diamondInquiryAll,
        InquiryCategory.gemstone => ApiEndpoints.gemstoneInquiryAll,
        InquiryCategory.bullion => ApiEndpoints.bullionInquiryAll,
        InquiryCategory.watch => ApiEndpoints.watchInquiryAll,
        InquiryCategory.jewelry => ApiEndpoints.jewelleryInquiryAll,
      };

  String _createPath(InquiryCategory category) => switch (category) {
        InquiryCategory.diamond => ApiEndpoints.diamondInquiry,
        InquiryCategory.gemstone => ApiEndpoints.gemstoneInquiry,
        InquiryCategory.bullion => ApiEndpoints.bullionInquiry,
        InquiryCategory.watch => ApiEndpoints.watchInquiry,
        InquiryCategory.jewelry => ApiEndpoints.jewelleryInquiry,
      };

  String _detailPath(InquiryCategory category, String id) => switch (category) {
        InquiryCategory.diamond => ApiEndpoints.diamondInquiryById(id),
        InquiryCategory.gemstone => ApiEndpoints.gemstoneInquiryById(id),
        InquiryCategory.bullion => ApiEndpoints.bullionInquiryById(id),
        InquiryCategory.watch => ApiEndpoints.watchInquiryById(id),
        InquiryCategory.jewelry => ApiEndpoints.jewelleryInquiryById(id),
      };

  int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
