import 'chat_product_type.dart';

class ProductChatSpec {
  const ProductChatSpec({required this.label, required this.value});

  final String label;
  final String value;
}

class ProductChatContext {
  const ProductChatContext({
    required this.productId,
    required this.productType,
    required this.productName,
    required this.sellerUserId,
    required this.sellerName,
    this.sellerLogo,
    this.productImages = const [],
    this.productPrice,
    this.stockNumber,
    this.productSpecs = const [],
  });

  final String productId;
  final ChatProductType productType;
  final String productName;
  final String sellerUserId;
  final String sellerName;
  final String? sellerLogo;
  final List<String> productImages;
  final double? productPrice;
  final String? stockNumber;
  final List<ProductChatSpec> productSpecs;

  String? get primaryImage =>
      productImages.isEmpty ? null : productImages.first;
}
