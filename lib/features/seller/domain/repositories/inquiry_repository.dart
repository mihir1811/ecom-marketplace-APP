import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/inquiry_list_page.dart';
import '../models/seller_inquiry.dart';

abstract class InquiryRepository {
  Future<Result<InquiryListPage, Failure>> listInquiries({
    required InquiryCategory category,
    required int page,
    int limit = 10,
    CancelToken? cancelToken,
  });

  Future<Result<SellerInquiry, Failure>> getInquiry({
    required InquiryCategory category,
    required String id,
    CancelToken? cancelToken,
  });

  Future<Result<SellerInquiry, Failure>> createInquiry({
    required InquiryCategory category,
    required Map<String, dynamic> body,
    CancelToken? cancelToken,
  });

  Future<Result<SellerInquiry, Failure>> updateInquiry({
    required InquiryCategory category,
    required String id,
    required Map<String, dynamic> body,
    CancelToken? cancelToken,
  });

  Future<Result<void, Failure>> deleteInquiry({
    required InquiryCategory category,
    required String id,
    CancelToken? cancelToken,
  });
}
