enum ProductShareChannel {
  email('email'),
  whatsapp('whatsapp');

  const ProductShareChannel(this.apiValue);
  final String apiValue;

  static ProductShareChannel fromApi(String? raw) {
    for (final channel in ProductShareChannel.values) {
      if (channel.apiValue == raw) return channel;
    }
    return ProductShareChannel.email;
  }
}

class ProductShareLink {
  const ProductShareLink({
    required this.id,
    required this.token,
    required this.shareUrl,
    required this.channel,
    required this.productType,
    required this.productId,
    required this.includePrice,
    required this.includeImages,
    required this.includeVideos,
    this.accessCount = 0,
  });

  final String id;
  final String token;
  final String shareUrl;
  final ProductShareChannel channel;
  final String productType;
  final String productId;
  final bool includePrice;
  final bool includeImages;
  final bool includeVideos;
  final int accessCount;
}

class ProductShareEmailResult {
  const ProductShareEmailResult({
    required this.id,
    required this.shareUrl,
    required this.recipientEmail,
  });

  final String id;
  final String shareUrl;
  final String recipientEmail;
}

class SharedProductPayload {
  const SharedProductPayload({
    required this.id,
    required this.token,
    required this.productType,
    required this.productId,
    required this.includePrice,
    required this.includeImages,
    required this.includeVideos,
    required this.accessCount,
    this.productName,
    this.product = const {},
  });

  final String id;
  final String token;
  final String productType;
  final String productId;
  final bool includePrice;
  final bool includeImages;
  final bool includeVideos;
  final int accessCount;
  final String? productName;
  final Map<String, dynamic> product;
}
