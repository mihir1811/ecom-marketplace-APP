import '../../domain/models/rough_facets.dart';
import '../../domain/models/rough_parcel.dart';

/// Parses rough API JSON. Decimals arrive as strings (`"47338.8"`) and are
/// parsed, never cast; unknown words stay as plain text.
abstract final class RoughParcelMapper {
  static RoughParcel fromJson(Map<String, dynamic> json) {
    final lotsRaw = json['lots'];
    final lots = <RoughLot>[
      if (lotsRaw is List)
        for (final l in lotsRaw)
          if (l is Map<String, dynamic>) ?_lot(l),
    ]..sort((a, b) => a.position.compareTo(b.position));
    final sellerRaw = json['seller'];
    final totalCarat = dec(json['totalCaratWeight']) ?? 0;
    final totalPrice = dec(json['totalPrice']) ?? 0;
    final title = str(json['title']);
    final display =
        str(json['displayName']) ??
        title ??
        '${totalCarat.toStringAsFixed(2)} ct rough';

    return RoughParcel(
      id: str(json['id']) ?? '',
      sellerId: str(json['sellerId']),
      stockNumber: str(json['stockNumber']) ?? '',
      diamondType: RoughDiamondType.fromApi(str(json['diamondType'])),
      growthType: str(json['growthType']),
      title: title,
      displayName: display,
      available: str(json['available']) ?? 'yes',
      countryOfOrigin: str(json['countryOfOrigin']),
      mineSource: str(json['mineSource']),
      compositionType: str(json['compositionType']),
      roughQuality: str(json['roughQuality']),
      crystalShape: str(json['crystalShape']),
      crystalCondition: str(json['crystalCondition']),
      transparency: str(json['transparency']),
      surfaceCondition: str(json['surfaceCondition']),
      crystalStructure: str(json['crystalStructure']),
      twinning: str(json['twinning']),
      fluorescence: str(json['fluorescence']),
      colorRange: str(json['colorRange']),
      colorDistribution: str(json['colorDistribution']),
      clarityRange: str(json['clarityRange']),
      manufacturingPotential: str(json['manufacturingPotential']),
      estimatedYield: dec(json['estimatedYield']),
      length: dec(json['length']),
      width: dec(json['width']),
      height: dec(json['height']),
      averageCaratPerPiece: dec(json['averageCaratPerPiece']),
      parcelType: str(json['parcelType']),
      parcelConsistency: str(json['parcelConsistency']),
      isSeparable: str(json['isSeparable']),
      totalCaratWeight: totalCarat,
      totalPcs: integer(json['totalPcs']) ?? 0,
      pricePerCarat: dec(json['pricePerCarat']) ?? 0,
      totalPrice: totalPrice,
      pricePerPiece: dec(json['pricePerPiece']),
      paymentTerms: str(json['paymentTerms']),
      deliveryTerms: str(json['deliveryTerms']),
      deliveryDays: integer(json['deliveryDays']),
      inspectionAllowed: _bool(json['inspectionAllowed']),
      returnTerms: str(json['returnTerms']),
      images: [for (var i = 1; i <= 6; i++) ?str(json['image$i'])],
      videoUrl: str(json['videoURL']) ?? str(json['videoUrl']),
      kpStatus: str(json['kpStatus']),
      kpCertificateNumber: str(json['kpCertificateNumber']),
      kpCertificateUrl: str(json['kpCertificateUrl']),
      labReportAvailable: _bool(json['labReportAvailable']) ?? false,
      labName: str(json['labName']),
      labReportNumber: str(json['labReportNumber']),
      labReportUrl: str(json['labReportUrl']),
      description: str(json['description']),
      isSold: json['isSold'] == true,
      isExpired: json['isExpired'] == true,
      isOnAuction: json['isOnAuction'] == true,
      isReserved: json['isReserved'] == true,
      isMakeAnOfferAllowed: json['isMakeAnOfferAllowed'] == true,
      maxOfferAttemptsPerUser: integer(json['maxOfferAttemptsPerUser']) ?? 5,
      createdAt: _date(json['createdAt']),
      seller: sellerRaw is Map<String, dynamic> ? _seller(sellerRaw) : null,
      lots: lots,
      buy: _buy(json['buy'], lots: lots, available: str(json['available'])),
      auctionId: str(json['auctionId']),
      auctionStartTime: _date(json['auctionStartTime']),
      auctionEndTime: _date(json['auctionEndTime']),
    );
  }

  static RoughFacets facetsFromJson(Map<String, dynamic> json) {
    final values = <String, List<RoughFacetValue>>{};
    final facets = json['facets'];
    if (facets is Map) {
      facets.forEach((key, raw) {
        if (raw is! List) return;
        values[key.toString()] = [
          for (final v in raw)
            if (v is Map && str(v['value']) != null)
              RoughFacetValue(str(v['value'])!, integer(v['count']) ?? 0),
        ];
      });
    }
    final ranges = <String, RoughFacetRange>{};
    final rangesRaw = json['ranges'];
    if (rangesRaw is Map) {
      rangesRaw.forEach((key, raw) {
        if (raw is! Map) return;
        final min = dec(raw['min']);
        final max = dec(raw['max']);
        if (min == null || max == null) return;
        ranges[key.toString()] = RoughFacetRange(min, max);
      });
    }
    return RoughFacets(
      total: integer(json['total']) ?? 0,
      values: values,
      ranges: ranges,
    );
  }

  static RoughLot? _lot(Map<String, dynamic> json) {
    final id = str(json['id']);
    if (id == null) return null;
    return RoughLot(
      id: id,
      position: integer(json['position']) ?? 0,
      sieveStandard: str(json['sieveStandard']),
      sieveSize: str(json['sieveSize']) ?? '—',
      pieces: integer(json['pieces']) ?? 0,
      caratWeight: dec(json['caratWeight']) ?? 0,
      averageCaratPerPiece: dec(json['averageCaratPerPiece']),
      pricePerCarat: dec(json['pricePerCarat']) ?? 0,
      totalPrice: dec(json['totalPrice']) ?? 0,
      notes: str(json['notes']),
      isSold: json['isSold'] == true,
      isReserved: json['isReserved'] == true,
    );
  }

  static RoughSeller _seller(Map<String, dynamic> json) => RoughSeller(
    id: str(json['id']) ?? '',
    userId: str(json['userId']),
    sellerType: str(json['sellerType']),
    companyName: str(json['companyName']),
    companyLogo: str(json['companyLogo']),
    city: str(json['city']),
    state: str(json['state']),
    country: str(json['country']),
    isVerified: json['isVerified'] == true,
    averageRating: dec(json['averageRating']),
    reviewCount: integer(json['reviewCount']) ?? 0,
  );

  /// Missing `buy` (older payloads): derive a conservative verdict.
  static RoughBuy _buy(
    Object? raw, {
    required List<RoughLot> lots,
    required String? available,
  }) {
    if (raw is Map) {
      final free = raw['freeLotIds'];
      return RoughBuy(
        onSale: raw['onSale'] == true,
        separable: raw['separable'] == true,
        canBuyWhole: raw['canBuyWhole'] == true,
        canBuyLots: raw['canBuyLots'] == true,
        freeLotIds: {
          if (free is List)
            for (final id in free) ?str(id),
        },
        remainingCarat: dec(raw['remainingCarat']) ?? 0,
        remainingPrice: dec(raw['remainingPrice']) ?? 0,
      );
    }
    final onSale = (available ?? '').trim().toLowerCase() == 'yes';
    return RoughBuy(
      onSale: onSale,
      canBuyWhole: onSale && lots.every((l) => !l.isTaken),
    );
  }

  /// Decimal sent as a string or a number.
  static double? dec(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim());
  }

  static int? integer(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ??
        double.tryParse(v.toString().trim())?.toInt();
  }

  static String? str(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty || s == 'null' ? null : s;
  }

  static bool? _bool(Object? v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == 'yes') return true;
    if (s == 'false' || s == 'no') return false;
    return null;
  }

  static DateTime? _date(Object? v) {
    final s = str(v);
    return s == null ? null : DateTime.tryParse(s)?.toLocal();
  }
}
