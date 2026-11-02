import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/spotlight_models.dart';
import '../domain/spotlight_seller_models.dart';

final spotlightSellerRepositoryProvider = Provider<SpotlightSellerRepository>(
  (ref) => SpotlightSellerRepository(ref.watch(dioProvider)),
);

/// What an ad shows, by placement type.
class SpotlightBookingRequest {
  const SpotlightBookingRequest({
    required this.placement,
    required this.startDate,
    required this.endDate,
    required this.expectedAmount,
    required this.bookingKey,
    this.category,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.mobileImageUrl,
    this.linkProduct,
    this.products = const [],
  });

  final SpotlightPlacement placement;
  final SpotlightCategory? category;
  final DateTime startDate;
  final DateTime endDate;

  /// pricePerDay × days (× products for sponsored products), in rupees.
  final double expectedAmount;

  /// Made once per booking and sent again on retries, so a repeat returns
  /// the ad already booked and doesn't charge twice.
  final String bookingKey;

  /// Banner title, or the featured seller's tagline.
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final String? mobileImageUrl;

  /// A banner may open one of the seller's products instead of the shop.
  final SpotlightSellerProduct? linkProduct;
  final List<SpotlightSellerProduct> products;

  Map<String, dynamic> toJson() {
    String? clean(String? v) {
      final t = v?.trim();
      return t == null || t.isEmpty ? null : t;
    }

    return {
      'placement': placement.api,
      'category': ?category?.api,
      'startDate': spotlightDate(startDate),
      'endDate': spotlightDate(endDate),
      'title': ?clean(title),
      'subtitle': ?clean(subtitle),
      'imageUrl': ?clean(imageUrl),
      'mobileImageUrl': ?clean(mobileImageUrl),
      if (linkProduct != null) ...{
        'linkProductType': linkProduct!.productType,
        'linkProductId': linkProduct!.productId,
      },
      if (products.isNotEmpty)
        'products': [for (final p in products) p.toBooking()],
      // Whole rupees when the total has no paise.
      'expectedAmount': expectedAmount == expectedAmount.roundToDouble()
          ? expectedAmount.round()
          : expectedAmount,
      'bookingKey': bookingKey,
    };
  }
}

/// An uploaded banner image (POST /spotlight/seller/creatives).
typedef SpotlightCreative = ({String url, int? width, int? height});

/// The seller's Advertising calls, each with the seller's token.
class SpotlightSellerRepository {
  SpotlightSellerRepository(this._dio);

  final Dio _dio;

  Future<Result<SpotlightOverview, SpotlightError>> overview() => _call(
    () => _dio.get<Map<String, dynamic>>(ApiEndpoints.spotlightSellerOverview),
    (data) => SpotlightOverview.fromJson(SpotlightJson.map(data) ?? const {}),
  );

  /// Booked and free slots per day; up to 120 days per call.
  Future<Result<List<SpotlightDay>, SpotlightError>> availability({
    required SpotlightPlacement placement,
    SpotlightCategory? category,
    required DateTime from,
    required DateTime to,
  }) => _call(
    () => _dio.get<Map<String, dynamic>>(
      ApiEndpoints.spotlightSellerAvailability,
      queryParameters: {
        'placement': placement.api,
        'category': ?category?.api,
        'from': spotlightDate(from),
        'to': spotlightDate(to),
      },
    ),
    (data) {
      final map = SpotlightJson.map(data);
      final days = map == null ? data : map['days'];
      return [
        for (final raw in SpotlightJson.list(days)) ?SpotlightDay.fromJson(raw),
      ];
    },
  );

  /// The seller's products that can be sponsored in [category].
  Future<Result<List<SpotlightSellerProduct>, SpotlightError>> products({
    required SpotlightCategory category,
    String? search,
  }) => _call(
    () => _dio.get<Map<String, dynamic>>(
      ApiEndpoints.spotlightSellerProducts,
      queryParameters: {
        'category': category.api,
        if (search?.trim().isNotEmpty ?? false) 'search': search!.trim(),
      },
    ),
    (data) {
      final map = SpotlightJson.map(data);
      final list = map == null ? data : (map['items'] ?? map['products']);
      return [
        for (final raw in SpotlightJson.list(list))
          ?SpotlightSellerProduct.fromJson(raw),
      ];
    },
  );

  /// Uploads a banner image (JPEG, PNG or WebP, up to 5 MB, at least
  /// 600 px wide). Only URLs from here are accepted on a booking.
  Future<Result<SpotlightCreative, SpotlightError>> uploadCreative(
    XFile file, {
    void Function(double progress)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final name = file.name.trim().isEmpty ? 'banner.jpg' : file.name;
    return _call(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.spotlightSellerCreatives,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: name,
            contentType: DioMediaType.parse(spotlightImageMime(name)),
          ),
        }),
        onSendProgress: onProgress == null
            ? null
            : (sent, total) {
                if (total > 0) onProgress(sent / total);
              },
      ),
      (data) {
        final map = SpotlightJson.map(data) ?? const {};
        final url = SpotlightJson.text(map['url']);
        if (url == null) throw const FormatException('No image URL');
        return (
          url: url,
          width: SpotlightJson.integer(map['width']),
          height: SpotlightJson.integer(map['height']),
        );
      },
    );
  }

  /// Books the ad and pays from the wallet at once. The answer is the new
  /// ad, waiting for GemWorld's review.
  Future<Result<SpotlightSellerAd, SpotlightError>> book(
    SpotlightBookingRequest request,
  ) => _call(
    () => _dio.post<Map<String, dynamic>>(
      ApiEndpoints.spotlightSeller,
      data: request.toJson(),
    ),
    _ad,
  );

  /// The seller's ads, newest first (up to 200), with views and clicks.
  Future<Result<List<SpotlightSellerAd>, SpotlightError>> myAds() => _call(
    () => _dio.get<Map<String, dynamic>>(ApiEndpoints.spotlightSeller),
    (data) {
      final map = SpotlightJson.map(data);
      final list = map == null ? data : (map['items'] ?? map['ads']);
      return [
        for (final raw in SpotlightJson.list(list))
          if (SpotlightJson.map(raw) case final j?) SpotlightSellerAd.fromJson(j),
      ];
    },
  );

  /// One ad, with its products and daily views and clicks.
  Future<Result<SpotlightSellerAd, SpotlightError>> ad(String id) => _call(
    () => _dio.get<Map<String, dynamic>>(ApiEndpoints.spotlightSellerById(id)),
    _ad,
  );

  /// Cancels an ad that hasn't started; what's left goes back to the wallet.
  Future<Result<SpotlightSellerAd, SpotlightError>> cancel(String id) => _call(
    () => _dio.post<Map<String, dynamic>>(
      ApiEndpoints.spotlightSellerCancel(id),
    ),
    _ad,
  );

  static SpotlightSellerAd _ad(Object? data) {
    final map = SpotlightJson.map(data) ?? const <String, dynamic>{};
    final nested = SpotlightJson.map(map['ad']);
    return SpotlightSellerAd.fromJson(nested ?? map);
  }

  Future<Result<T, SpotlightError>> _call<T>(
    Future<Response<Map<String, dynamic>>> Function() send,
    T Function(Object? data) parse,
  ) async {
    try {
      final response = await send();
      return Result.success(parse(response.data?['data']));
    } on DioException catch (e) {
      return Result.failure(_error(e));
    } catch (e) {
      return Result.failure(
        const SpotlightError('Something went wrong. Please try again.'),
      );
    }
  }

  static SpotlightError _error(DioException e) {
    final body = SpotlightJson.map(e.response?.data) ?? const {};
    final status = e.response?.statusCode;
    final message =
        ApiError.extractMessage(body) ??
        (status == 403
            ? 'Advertising is available to verified seller accounts only.'
            : ApiError.fromDio(e).message);
    final extra = <String, dynamic>{
      ...body,
      ...?SpotlightJson.map(body['data']),
    };
    return SpotlightError(
      message,
      code: ApiError.extractCode(body) ?? SpotlightJson.text(extra['code']),
      status: status,
      data: extra,
    );
  }
}

/// MIME type for an image upload, by file extension.
String spotlightImageMime(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}
