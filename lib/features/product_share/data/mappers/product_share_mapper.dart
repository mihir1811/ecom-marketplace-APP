import '../../domain/models/product_share.dart';
import '../../domain/product_share_urls.dart';

abstract final class ProductShareMapper {
  static ProductShareLink linkFromJson(Map<String, dynamic> json) {
    final token = json['token']?.toString() ?? '';
    final apiShareUrl = json['shareUrl']?.toString() ?? '';
    return ProductShareLink(
      id: json['id']?.toString() ?? '',
      token: token,
      shareUrl: ProductShareUrls.rewriteApiShareUrl(
        token: token,
        apiShareUrl: apiShareUrl,
      ),
      channel: ProductShareChannel.fromApi(json['channel']?.toString()),
      productType: json['productType']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      includePrice: json['includePrice'] == true,
      includeImages: json['includeImages'] != false,
      includeVideos: json['includeVideos'] != false,
      accessCount: _asInt(json['accessCount']) ?? 0,
    );
  }

  static ProductShareEmailResult emailFromJson(Map<String, dynamic> json) {
    final shareUrl = json['shareUrl']?.toString() ?? '';
    final token = ProductShareUrls.tokenFromShareUrl(shareUrl);
    return ProductShareEmailResult(
      id: json['id']?.toString() ?? '',
      shareUrl: token.isEmpty
          ? shareUrl
          : ProductShareUrls.rewriteApiShareUrl(
              token: token,
              apiShareUrl: shareUrl,
            ),
      recipientEmail: json['recipientEmail']?.toString() ?? '',
    );
  }

  static SharedProductPayload sharedFromJson(Map<String, dynamic> json) {
    final product = json['product'];
    return SharedProductPayload(
      id: json['id']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      productType: json['productType']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      includePrice: json['includePrice'] == true,
      includeImages: json['includeImages'] != false,
      includeVideos: json['includeVideos'] != false,
      accessCount: _asInt(json['accessCount']) ?? 0,
      productName: json['productName']?.toString(),
      product: product is Map<String, dynamic>
          ? Map<String, dynamic>.from(product)
          : const {},
    );
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
