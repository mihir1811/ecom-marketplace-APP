class AiChatProduct {
  const AiChatProduct({
    required this.id,
    required this.productType,
    required this.title,
    this.stockNumber = '',
    this.shape,
    this.caratWeight,
    this.color,
    this.clarity,
    this.cut,
    this.certificateCompanyName,
    this.totalPrice,
    this.pricePerCarat,
    this.imageUrl,
    this.href = '',
  });

  final String id;
  final String productType;
  final String title;
  final String stockNumber;
  final String? shape;
  final double? caratWeight;
  final String? color;
  final String? clarity;
  final String? cut;
  final String? certificateCompanyName;
  final double? totalPrice;
  final double? pricePerCarat;
  final String? imageUrl;
  final String href;
}

class AiChatProductGroup {
  const AiChatProductGroup({
    required this.label,
    this.products = const [],
    this.totalFound = 0,
    this.productType = '',
  });

  final String label;
  final List<AiChatProduct> products;
  final int totalFound;
  final String productType;
}
