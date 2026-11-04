import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../product_detail/application/catalog_product_detail_loader.dart';
import '../../product_detail/domain/models/product_detail.dart';
import '../data/mappers/shared_product_detail_mapper.dart';
import '../data/repositories/product_share_repository_impl.dart';
import '../domain/models/product_share.dart';

/// Loads a shared product by token and returns a [ProductDetail] for in-app open.
///
/// Prefers a full catalog fetch (richer specs) when possible, then applies the
/// share visibility flags from `GET /product-share/{token}`. Falls back to the
/// embedded share payload when catalog lookup is unavailable.
final sharedProductDetailProvider = FutureProvider.autoDispose
    .family<ProductDetail, String>((ref, token) async {
      final clean = _normalizeShareToken(token);
      if (clean.isEmpty) {
        throw const NetworkFailure('This share link is invalid.');
      }

      final shareResult = await ref
          .read(productShareRepositoryProvider)
          .getByToken(token: clean);
      late final SharedProductPayload payload;
      switch (shareResult) {
        case Success(value: final value):
          payload = value;
        case ResultFailure(failure: final failure):
          throw failure;
      }

      final fetched = await CatalogProductDetailLoader.load(
        ref.read,
        productType: payload.productType,
        productId: payload.productId,
      );
      if (fetched != null) {
        return SharedProductDetailMapper.applyShareVisibility(
          SharedProductDetailMapper.withProductName(
            fetched,
            payload.productName,
          ),
          includePrice: payload.includePrice,
          includeImages: payload.includeImages,
          includeVideos: payload.includeVideos,
        );
      }

      final fromPayload = SharedProductDetailMapper.toProductDetail(payload);
      if (fromPayload != null) return fromPayload;

      throw const NetworkFailure('This shared product could not be opened.');
    });

String _normalizeShareToken(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return '';

  // Path or absolute URL pasted into the route.
  if (value.contains('/') || value.contains('#')) {
    final fromUrl = _tokenFromPossibleUrl(value);
    if (fromUrl.isNotEmpty) return fromUrl;
  }

  try {
    value = Uri.decodeComponent(value);
  } catch (_) {
    // Keep raw token when it is not percent-encoded.
  }
  return value.trim();
}

String _tokenFromPossibleUrl(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null) return '';

  final fragment = uri.fragment.trim();
  if (fragment.isNotEmpty) {
    final fragPath = fragment.startsWith('/') ? fragment : '/$fragment';
    final fragUri = Uri.tryParse(fragPath);
    final fromFrag = _tokenFromPathSegments(fragUri?.pathSegments ?? const []);
    if (fromFrag.isNotEmpty) return fromFrag;
  }

  return _tokenFromPathSegments(uri.pathSegments);
}

String _tokenFromPathSegments(List<String> segments) {
  if (segments.isEmpty) return '';
  final idx = segments.lastIndexOf('share');
  if (idx >= 0 && idx + 1 < segments.length) {
    return Uri.decodeComponent(segments[idx + 1]);
  }
  return Uri.decodeComponent(segments.last);
}
