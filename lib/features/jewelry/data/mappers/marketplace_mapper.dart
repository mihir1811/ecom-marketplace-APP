import '../../domain/models/marketplace_listing.dart';
import 'marketplace_json.dart';

typedef _J = MarketplaceJson;

/// Maps `/marketplace` catalogue JSON into domain records.
abstract final class MarketplaceMapper {
  static MarketplaceCategory category(Map<String, dynamic> j) {
    final children = _J.listOf(j['children'], category)
      ..sort((a, b) => a.position.compareTo(b.position));
    return MarketplaceCategory(
      id: _J.text(j['id']) ?? '',
      name: _J.text(j['name']) ?? '',
      slug: _J.text(j['slug']) ?? '',
      parentId: _J.text(j['parentId']),
      imageUrl: _absoluteUrl(j['imageUrl']),
      position: _J.asInt(j['position']),
      children: [
        for (final c in children)
          if (c.slug.isNotEmpty && c.name.isNotEmpty) c,
      ],
    );
  }

  static List<MarketplaceCategory> categories(Object? data) {
    final list = _J.listOf(data, category)
      ..sort((a, b) => a.position.compareTo(b.position));
    return [
      for (final c in list)
        if (c.slug.isNotEmpty && c.name.isNotEmpty) c,
    ];
  }

  static MarketplaceShop shop(Map<String, dynamic> j) => MarketplaceShop(
    id: _J.text(j['id']) ?? '',
    name: _J.text(j['name']) ?? '',
    slug: _J.text(j['slug']) ?? '',
    sellerId: _J.text(j['sellerId']),
    headline: _J.text(j['headline']),
    description: _J.text(j['description']),
    logoUrl: _absoluteUrl(j['logoUrl']),
    bannerUrl: _absoluteUrl(j['bannerUrl']),
    policies: {
      for (final e in _J.strings(j['policies']).entries)
        if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
    },
    showPriceBreakdown: j['showPriceBreakdown'] == true,
    listingCount: _J.intOrNull(_J.obj(j['_count'])['listings']),
    listings: _J.listOf(j['listings'], listing),
  );

  static MarketplaceListing listing(Map<String, dynamic> j) {
    final attributes = _J.obj(j['attributes']);
    final category = _J.obj(j['category']);
    final parent = _J.obj(category['parent']);
    final shopJson = j['shop'];
    final media = _J.listOf(j['media'], _media)
      ..sort((a, b) => a.position.compareTo(b.position));
    final gemstonesJson = j['gemstones'];
    final gemstoneRows = gemstonesJson is List
        ? ([...gemstonesJson.whereType<Map>().map(_J.obj)]..sort(
            (a, b) =>
                _J.asInt(a['position']).compareTo(_J.asInt(b['position'])),
          ))
        : const <Map<String, dynamic>>[];
    return MarketplaceListing(
      id: _J.text(j['id']) ?? '',
      slug: _J.text(j['slug']) ?? '',
      // Older jewellery records name the title `productTitle`.
      title: _J.text(j['title']) ?? _J.text(j['productTitle']) ?? 'Untitled',
      description: _J.text(j['description']),
      stockNumber: _J.text(j['stockNumber']),
      coverImageUrl: _absoluteUrl(j['coverImageUrl']),
      minPrice: _J.money(j['minPrice']),
      maxPrice: _J.money(j['maxPrice']),
      totalStock: _J.asInt(j['totalStock']),
      tags: _J.stringList(j['tags']),
      categoryName: _J.text(category['name']),
      categorySlug: _J.text(category['slug']),
      parentCategoryName: _J.text(parent['name']),
      parentCategorySlug: _J.text(parent['slug']),
      shop: shopJson is Map ? shop(_J.obj(shopJson)) : null,
      detail: _detail(_J.obj(j['detail'])),
      variations: [
        for (final v in _J.listOf(attributes['variations'], _variation))
          if (v.name.isNotEmpty && v.options.isNotEmpty) v,
      ],
      customOptions: [
        for (final o in _J.listOf(attributes['customOptions'], _customOption))
          if (o.name.isNotEmpty) o,
      ],
      skus: _J.listOf(j['skus'], _sku),
      media: media,
      gemstones: [for (final g in gemstoneRows) _gemstone(g)],
      favoriteCount: _J.asInt(j['favoriteCount']),
      publishedAt: _J.date(j['publishedAt']),
      isFullRecord: j.containsKey('description') || gemstonesJson is List,
      taxLabels: [
        for (final t in _J.listOf(j['taxes'], (t) => t))
          ?(_J.text(t['label']) ?? _J.text(t['name'])),
      ],
    );
  }

  static MarketplaceListingPage page(Object? data, {required int page}) {
    final j = _J.obj(data);
    return MarketplaceListingPage(
      items: [
        for (final l in _J.listOf(j['items'], listing))
          if (l.slug.isNotEmpty) l,
      ],
      total: _J.asInt(j['total']),
      page: _J.asInt(j['page'], page),
      limit: _J.asInt(j['limit'], 48),
    );
  }

  static MarketplaceFacets facets(Object? data) {
    final j = _J.obj(data);
    final price = _J.obj(j['price']);
    final availability = _J.obj(j['availability']);
    List<MarketplaceFacetBucket> buckets(Object? v) => [
      for (final b in _J.listOf(
        v,
        (b) => MarketplaceFacetBucket(
          _J.text(b['value']) ?? '',
          _J.asInt(b['count']),
        ),
      ))
        if (b.value.isNotEmpty) b,
    ];
    return MarketplaceFacets(
      total: _J.asInt(j['total']),
      priceMin: _J.money(price['min']),
      priceMax: _J.money(price['max']),
      metals: buckets(j['metals']),
      gemstones: buckets(j['gemstones']),
      origins: buckets(j['origins']),
      styles: buckets(j['styles']),
      occasions: buckets(j['occasions']),
      shapes: buckets(j['shapes']),
      readyToShip: _J.asInt(availability['readyToShip']),
      madeToOrder: _J.asInt(availability['madeToOrder']),
    );
  }

  static MarketplaceListingDetail _detail(Map<String, dynamic> j) =>
      MarketplaceListingDetail(
        isMadeToOrder: j['isMadeToOrder'] == true,
        metalType: _J.text(j['metalType']),
        metalPurity: _J.text(j['metalPurity']),
        metalWeightGrams: _J.decimal(j['metalWeightGrams']),
        grossWeightGrams: _J.decimal(j['grossWeightGrams']),
        primaryGemstone: _J.text(j['primaryGemstone']),
        gemstoneOrigin: _J.text(j['gemstoneOrigin']),
        primaryShape: _J.text(j['primaryShape']),
        totalCaratWeight: _J.decimal(j['totalCaratWeight']),
        style: _J.text(j['style']),
        occasion: _J.text(j['occasion']),
        processingDays: _J.asInt(j['processingDays'], 3),
        personalizationEnabled: j['personalizationEnabled'] == true,
        personalizationInstructions: _J.text(j['personalizationInstructions']),
        freeShipping: j['freeShipping'] == true,
        shipsFromCountry: _J.text(j['shipsFromCountry']),
        returnsAccepted: j['returnsAccepted'] != false,
        returnWindowDays: _J.intOrNull(j['returnWindowDays']),
        cancellationWindowHours: _J.asInt(j['cancellationWindowHours'], 24),
      );

  static MarketplaceMedia _media(Map<String, dynamic> j) => MarketplaceMedia(
    id: _J.text(j['id']) ?? '',
    url: _absoluteUrl(j['url']) ?? '',
    isVideo: j['type'] == 'VIDEO',
    position: _J.asInt(j['position']),
    altText: _J.text(j['altText']),
  );

  static MarketplaceVariation _variation(Map<String, dynamic> j) =>
      MarketplaceVariation(
        name: _J.text(j['name']) ?? '',
        options: _J.stringList(j['options']),
        linkPhotos: j['linkPhotos'] == true,
        optionMedia: {
          for (final e in _J.obj(j['optionMedia']).entries)
            e.key: _J.stringList(e.value),
        },
      );

  static MarketplaceCustomOption _customOption(Map<String, dynamic> j) =>
      MarketplaceCustomOption(
        name: _J.text(j['name']) ?? '',
        isText: j['type'] != 'image',
      );

  static MarketplaceSku _sku(Map<String, dynamic> j) {
    final attributes = _J.obj(j['attributes']);
    final regional = _J.obj(attributes['regionalPrices']);
    final split = attributes['priceBreakdown'];
    return MarketplaceSku(
      id: _J.text(j['id']) ?? '',
      label: _J.text(j['name']),
      price: _J.money(regional['inr'] ?? j['price']),
      stock: _J.asInt(j['stock']),
      isActive: j['status'] == 'ACTIVE',
      options: _J.strings(attributes['options']),
      breakdown: split is Map
          ? {for (final e in split.entries) '${e.key}': _J.money(e.value)}
          : null,
    );
  }

  static MarketplaceGemstone _gemstone(Map<String, dynamic> j) =>
      MarketplaceGemstone(
        type: _J.text(j['type']),
        origin: _J.text(j['origin']),
        shape: _J.text(j['shape']),
        caratWeight: _J.decimal(j['caratWeight']),
        quantity: _J.intOrNull(j['quantity']),
        color: _J.text(j['color']),
        clarity: _J.text(j['clarity']),
        cut: _J.text(j['cut']),
        certificationLab: _J.text(j['certificationLab']),
        reportNumber: _J.text(j['reportNumber']),
      );

  /// Media are absolute S3 links; anything else is unusable.
  static String? _absoluteUrl(Object? raw) {
    final s = _J.text(raw);
    if (s == null) return null;
    final lower = s.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://')
        ? s
        : null;
  }
}
