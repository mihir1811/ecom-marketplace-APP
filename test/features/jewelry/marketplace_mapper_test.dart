import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/features/jewelry/data/mappers/jewelry_list_query_mapper.dart';
import 'package:gemworld/features/jewelry/data/mappers/jewelry_mapper.dart';
import 'package:gemworld/features/jewelry/data/mappers/marketplace_mapper.dart';
import 'package:gemworld/features/jewelry/domain/models/jewelry_filter_state.dart';
import 'package:gemworld/features/jewelry/domain/models/marketplace_enums.dart';
import 'package:gemworld/features/product_detail/domain/adapters/jewelry_product_detail.dart';

/// A trimmed card from the live `GET /marketplace/listings` response.
Map<String, dynamic> _card({int totalStock = 6, bool madeToOrder = true}) => {
  'id': '05a0f932-9efd-4062-a9e2-4c02f204f601',
  'slug': 'half-eternity-ring-pear-254984d8',
  'title': 'Half Eternity Ring Pear Lab Grown Diamond',
  'status': 'ACTIVE',
  'tags': ['wedding band'],
  'minPrice': '98610',
  'maxPrice': '125584',
  'totalStock': totalStock,
  'coverImageUrl': 'https://gemworld.s3.ap-south-1.amazonaws.com/a.jpg',
  'category': {
    'name': 'Wedding Bands',
    'slug': 'wedding-bands',
    'parent': {'slug': 'rings', 'name': 'Rings'},
  },
  'shop': {
    'id': 'd9e46da4',
    'sellerId': 'seller-1',
    'name': 'Pureyou',
    'slug': 'pureyou',
    'showPriceBreakdown': true,
    'policies': {'location': 'Jaipur'},
  },
  'detail': {
    'isMadeToOrder': madeToOrder,
    'metalType': 'YELLOW_GOLD',
    'metalPurity': '14K',
    'primaryGemstone': 'DIAMOND',
    'gemstoneOrigin': 'LAB_GROWN',
    'primaryShape': 'Pear',
    'totalCaratWeight': '1.43',
    'processingDays': 7,
    'freeShipping': true,
  },
  'attributes': {
    'variations': [
      {
        'name': 'Metal',
        'options': ['10K Yellow Gold', '14K Rose Gold'],
      },
      {
        'name': 'Ring size',
        'options': ['6', '7'],
      },
    ],
    'customOptions': [],
  },
  'skus': [
    {
      'id': 'sku-yg-6',
      'price': '98610',
      'stock': 1,
      'status': 'ACTIVE',
      'attributes': {
        'options': {'Metal': '10K Yellow Gold', 'Ring size': '6'},
        'regionalPrices': {'inr': 98000, 'usd': null},
        'priceBreakdown': {'metal': 90000, 'stone': 8000, 'making': 0},
      },
    },
    {
      'id': 'sku-rg-7',
      'price': '125584',
      'stock': 2,
      'status': 'ACTIVE',
      'attributes': {
        'options': {'Metal': '14K Rose Gold', 'Ring size': '7'},
        'regionalPrices': {'inr': null},
      },
    },
    {
      'id': 'sku-rg-6',
      'price': '120000',
      'stock': 0,
      'status': 'INACTIVE',
      'attributes': {
        'options': {'Metal': '14K Rose Gold', 'Ring size': '6'},
      },
    },
  ],
  'media': [
    {'id': 'm2', 'type': 'IMAGE', 'url': 'https://x/2.webp', 'position': 1},
    {'id': 'm1', 'type': 'IMAGE', 'url': 'https://x/1.webp', 'position': 0},
  ],
};

void main() {
  test('categories keep only usable entries, sorted by position', () {
    final cats = MarketplaceMapper.categories([
      {
        'id': 'e',
        'name': 'Earrings',
        'slug': 'earrings',
        'position': 1,
        'children': [],
      },
      {
        'id': 'r',
        'name': 'Rings',
        'slug': 'rings',
        'position': 0,
        'imageUrl': '/relative.png',
        'children': [
          {'id': 'b', 'name': 'Bands', 'slug': 'bands', 'position': 1},
          {
            'id': 'a',
            'name': 'Engagement',
            'slug': 'engagement',
            'position': 0,
          },
        ],
      },
      {'id': 'x', 'name': '', 'slug': ''},
    ]);
    expect(cats.map((c) => c.slug), ['rings', 'earrings']);
    expect(cats.first.children.map((c) => c.slug), ['engagement', 'bands']);
    // Relative paths are unusable on the app.
    expect(cats.first.imageUrl, isNull);
  });

  test('listing card parses string decimals and prefers the rupee price', () {
    final l = MarketplaceMapper.listing(_card());
    expect(l.minPrice, 98610);
    expect(l.maxPrice, 125584);
    expect(l.hasPriceRange, isTrue);
    expect(l.detail.totalCaratWeight, 1.43);
    expect(l.skus.first.price, 98000, reason: 'regionalPrices.inr wins');
    expect(l.skus[1].price, 125584, reason: 'falls back to sku.price');
    expect(l.skus.first.breakdown, {
      'metal': 90000,
      'stone': 8000,
      'making': 0,
    });
    expect(l.media.map((m) => m.id), ['m1', 'm2']);
    expect(l.isFullRecord, isFalse);
    expect(l.parentCategorySlug, 'rings');
  });

  test('sold out only when out of stock and not made to order', () {
    expect(
      MarketplaceMapper.listing(
        _card(totalStock: 0, madeToOrder: true),
      ).soldOut,
      isFalse,
    );
    expect(
      MarketplaceMapper.listing(
        _card(totalStock: 0, madeToOrder: false),
      ).soldOut,
      isTrue,
    );
  });

  test('jewelry uses the slug as id and keeps the listing uuid', () {
    final j = JewelryMapper.fromJson(_card());
    expect(j.id, 'half-eternity-ring-pear-254984d8');
    expect(j.listingId, '05a0f932-9efd-4062-a9e2-4c02f204f601');
    expect(j.category, 'Rings');
    expect(j.subCategory, 'Wedding Bands');
    expect(j.metalColor, 'Yellow Gold');
    expect(j.stoneType, 'Lab-Grown');
    expect(j.imageUrls, ['https://x/1.webp', 'https://x/2.webp']);
    expect(j.colorVariants, containsAll(['Yellow Gold', 'Rose Gold']));
    expect(j.isMarketplace, isTrue);
  });

  test('product detail matches SKUs and greys out dead combinations', () {
    final detail = jewelryProductDetail(JewelryMapper.fromJson(_card()));
    final j = detail.jewelryDetail!;
    expect(detail.id, j.slug);
    expect(j.currencySymbol, '₹');
    expect(
      j.skuFor({'Metal': '14K Rose Gold', 'Ring size': '7'})?.id,
      'sku-rg-7',
    );
    // The rose-gold size 6 SKU is inactive, so that combination is dead.
    expect(j.skuFor({'Metal': '14K Rose Gold', 'Ring size': '6'}), isNull);
    expect(
      j.optionAvailable('Ring size', '6', {'Metal': '14K Rose Gold'}),
      isFalse,
    );
    expect(
      j.optionAvailable('Ring size', '6', {'Metal': '10K Yellow Gold'}),
      isTrue,
    );
    // Made to order: up to 20 regardless of stock.
    expect(j.maxQuantityFor(j.skus.first), 20);
  });

  test('query uses comma lists, slug category and drops empty params', () {
    final q = JewelryListQueryMapper.toQuery(
      filters: const JewelryFilterState(
        searchQuery: '  emerald ring ',
        category: 'rings',
        subCategory: 'engagement-rings',
        metals: {'YELLOW_GOLD', 'ROSE_GOLD'},
        priceMax: 50000,
        availability: JewelryAvailability.ready,
      ),
      page: 2,
      pageSize: 24,
      sort: JewelrySortOption.priceAsc,
    );
    expect(q['page'], 2);
    expect(q['limit'], 24);
    expect(q['category'], 'engagement-rings');
    expect(q['search'], 'emerald ring');
    expect((q['metal'] as String).split(',').toSet(), {
      'YELLOW_GOLD',
      'ROSE_GOLD',
    });
    expect(q['maxPrice'], 50000);
    expect(q['availability'], 'ready');
    expect(q['sort'], 'price_asc');
    expect(q.containsKey('gemstone'), isFalse);
    expect(q.containsKey('minPrice'), isFalse);
  });

  test('facet query only narrows by category, search, shop and tag', () {
    final q = JewelryListQueryMapper.toFacetQuery(
      const JewelryFilterState(
        searchQuery: 'halo',
        category: 'rings',
        shop: 'pureyou',
        metals: {'YELLOW_GOLD'},
        priceMin: 1000,
      ),
    );
    expect(q, {'category': 'rings', 'search': 'halo', 'shop': 'pureyou'});
  });

  test('facets parse buckets and the rupee price range', () {
    final f = MarketplaceMapper.facets({
      'total': 23,
      'price': {'min': 900, 'max': 655200},
      'metals': [
        {'value': 'YELLOW_GOLD', 'count': 11},
      ],
      'origins': [
        {'value': 'LAB_GROWN', 'count': 8},
      ],
      'availability': {'readyToShip': 10, 'madeToOrder': 13},
    });
    expect(f.priceMax, 655200);
    expect(f.metals.single.count, 11);
    expect(f.madeToOrder, 13);
    expect(MarketplaceEnums.label(f.origins.single.value), 'Lab-Grown');
  });
}
