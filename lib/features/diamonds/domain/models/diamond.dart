import '../../../product_detail/domain/models/listing_seller_info.dart';

/// Catalog diamond shown on listing cards and adapted into product detail.
class Diamond {
  final String id;
  final String shape;
  final double carat;
  final double price;
  final String cut;
  final String color;
  final String clarity;
  final String certificate;
  final String? imageUrl;
  final List<String> imageUrls;
  final double? pricePerCarat;
  final String? polish;
  final String? symmetry;
  final String? fluorescence;
  final String? fluorescenceColor;
  final String? lab;
  final bool hasVideo;
  final bool hasImage;
  final double? discount;
  final bool isLabGrown;
  final bool isMelee;
  final String? stockNumber;
  final String? growthType;
  final String? sellerCompanyName;
  final String? sellerCity;
  final String? sellerCountry;
  final ListingSellerInfo? listingSeller;
  final String? measurement;
  final String? measurementMin;
  final String? measurementMax;
  final String? ratio;
  final String? tablePercent;
  final String? depthPercent;
  final String? certificateNumber;
  final String? certificateUrl;
  final String? shade;
  final String? fancyColor;
  final String? fancyIntensity;
  final String? fancyOvertone;
  final String? origin;
  final String? roughSource;
  final String? enhancement;
  final String? girdleCondition;
  final String? culetCondition;
  final String? milky;
  final String? comment;
  final bool? eyeClean;
  final bool? bgm;
  final bool? heartAndArrow;
  final bool isOnAuction;
  final bool isSold;
  final bool isMakeAnOfferAllowed;
  final double? minimumOfferPrice;
  final int? totalPcs;
  final double? caratPerPcs;
  final double? totalCaratWeight;
  final double? pricePerPcs;
  final String? sieveLabel;
  final bool isSeparable;
  final String? available;
  final String? videoUrl;

  const Diamond({
    required this.id,
    required this.shape,
    required this.carat,
    required this.price,
    required this.cut,
    required this.color,
    required this.clarity,
    required this.certificate,
    this.imageUrl,
    this.imageUrls = const [],
    this.pricePerCarat,
    this.polish,
    this.symmetry,
    this.fluorescence,
    this.fluorescenceColor,
    this.lab,
    this.hasVideo = false,
    this.hasImage = false,
    this.discount,
    this.isLabGrown = false,
    this.isMelee = false,
    this.stockNumber,
    this.growthType,
    this.sellerCompanyName,
    this.sellerCity,
    this.sellerCountry,
    this.listingSeller,
    this.measurement,
    this.measurementMin,
    this.measurementMax,
    this.ratio,
    this.tablePercent,
    this.depthPercent,
    this.certificateNumber,
    this.certificateUrl,
    this.shade,
    this.fancyColor,
    this.fancyIntensity,
    this.fancyOvertone,
    this.origin,
    this.roughSource,
    this.enhancement,
    this.girdleCondition,
    this.culetCondition,
    this.milky,
    this.comment,
    this.eyeClean,
    this.bgm,
    this.heartAndArrow,
    this.isOnAuction = false,
    this.isSold = false,
    this.isMakeAnOfferAllowed = false,
    this.minimumOfferPrice,
    this.totalPcs,
    this.caratPerPcs,
    this.totalCaratWeight,
    this.pricePerPcs,
    this.sieveLabel,
    this.isSeparable = false,
    this.available,
    this.videoUrl,
  });
}

class DiamondListResponse {
  final List<Diamond> diamonds;
  final int totalCount;
  final bool hasMore;
  final int page;

  const DiamondListResponse({
    required this.diamonds,
    required this.totalCount,
    required this.hasMore,
    required this.page,
  });
}
