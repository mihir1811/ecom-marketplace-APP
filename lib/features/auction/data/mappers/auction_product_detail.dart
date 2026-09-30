import 'package:flutter/material.dart';

import '../../../cart/domain/models/cart_product_type.dart';
import '../../../diamonds/data/mappers/diamond_mapper.dart';
import '../../../diamonds/data/models/diamond_dto.dart';
import '../../../product_detail/domain/adapters/diamond_product_detail.dart';
import '../../../product_detail/domain/models/listing_seller_info.dart';
import '../../../product_detail/domain/models/product_detail.dart';
import '../../domain/models/auction_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_currency.dart';

/// Builds the shared product-detail view model for an auction listing.
ProductDetail auctionProductDetail(AuctionListing auction) {
  final type = auction.productType;
  if (type == CartProductType.diamond || type == CartProductType.meleeDiamond) {
    final json = Map<String, dynamic>.from(auction.product);
    if (auction.seller.isNotEmpty) json['seller'] = auction.seller;
    final dto = DiamondDto.fromJson(
      json,
      isMelee: type == CartProductType.meleeDiamond,
    );
    final diamond = DiamondMapper.toDomain(dto, isLabGrown: false);
    return diamondProductDetail(diamond);
  }
  return _compact(auction);
}

ProductDetail _compact(AuctionListing auction) {
  final product = auction.product;
  final price = auction.catalogPrice ?? auction.minimumBid;
  final images = <ProductImage>[
    for (final key in ['image', 'image1', 'image2', 'image3', 'image4'])
      if (product[key] is String && (product[key] as String).startsWith('http'))
        ProductImage.network(product[key] as String),
  ];
  final seller = auction.seller;
  final location = [
    seller['city'],
    seller['state'],
    seller['country'],
  ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
  final phoneRaw = seller['phone1'] ?? seller['phone'] ?? seller['phone2'];
  final phone = phoneRaw is String && phoneRaw.trim().isNotEmpty
      ? phoneRaw.trim()
      : null;
  return ProductDetail(
    id: auction.productId.isEmpty ? auction.id : auction.productId,
    segment: _segment(auction.productType),
    apiProductType: auction.productType.isEmpty
        ? CartProductType.diamond
        : auction.productType,
    title: auction.title,
    subtitle: auction.sellerName ?? '',
    referenceLabel: 'Stock ID',
    referenceValue: auction.stockNumber ?? auction.productId,
    badges: [
      ProductBadge(auction.phaseLabel, tone: ProductBadgeTone.caution),
    ],
    media: ProductMedia(
      images: images,
      imageSlots: images.length.clamp(0, 6),
      fallbackIcon: Icons.gavel_outlined,
      fallbackTint: AppColors.bronze,
    ),
    price: ProductPrice(
      currencySymbol: AppCurrency.usdSymbol,
      amountLabel: price.toStringAsFixed(2),
      priceUsd: price,
      priceInr: 0,
      displayAmount: price,
    ),
    highlights: [
      if (product['shape'] != null)
        ProductHighlight('Shape', '${product['shape']}'),
      if (product['caratWeight'] != null)
        ProductHighlight('Carat', '${product['caratWeight']}'),
      ProductHighlight('Min bid', AppCurrency.usd(auction.minimumBid)),
      ProductHighlight('Current', AppCurrency.usd(auction.currentBid)),
    ],
    specSections: [
      specSection(ProductSpecGroup.essentials, {
        'Type': auction.productType,
        'Stock': auction.stockNumber,
        if (product['description'] != null)
          'Description': '${product['description']}',
      }),
    ],
    listingSeller: auction.sellerName == null
        ? null
        : ListingSellerInfo(
            id: auction.sellerId,
            displayName: auction.sellerName!,
            phone: phone,
            location: location.isEmpty ? null : location,
          ),
    availabilityStatus: product['available']?.toString(),
  );
}

ProductSegment _segment(String type) {
  return switch (type) {
    CartProductType.gemstone => ProductSegment.gemstone,
    CartProductType.jewellery => ProductSegment.jewelry,
    CartProductType.watch => ProductSegment.watch,
    CartProductType.bullion => ProductSegment.bullion,
    _ => ProductSegment.naturalDiamond,
  };
}
