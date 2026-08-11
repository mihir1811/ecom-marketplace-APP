import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/refund_list_page.dart';
import '../models/refund_request.dart';

abstract class RefundRepository {
  Future<Result<RefundRequest, Failure>> create({
    required String orderId,
    required String sellerId,
    required String reason,
    CancelToken? cancelToken,
  });

  Future<Result<RefundListPage, Failure>> listMine({
    required int page,
    int limit = 10,
    String? status,
    CancelToken? cancelToken,
  });

  Future<Result<RefundListPage, Failure>> listSeller({
    required int page,
    int limit = 10,
    String? status,
    CancelToken? cancelToken,
  });

  Future<Result<RefundRequest, Failure>> getById({
    required String id,
    CancelToken? cancelToken,
  });

  Future<Result<RefundRequest, Failure>> accept({
    required String id,
    CancelToken? cancelToken,
  });

  Future<Result<RefundRequest, Failure>> reject({
    required String id,
    String? sellerNote,
    CancelToken? cancelToken,
  });

  Future<Result<RefundRequest, Failure>> cancel({
    required String id,
    CancelToken? cancelToken,
  });
}
