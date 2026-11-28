import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/l10n/app_localizations.dart';
import 'package:gemworld/core/theme/luxe_scope.dart';
import 'package:gemworld/features/cart/data/mappers/cart_mapper.dart';
import 'package:gemworld/features/comparison/domain/models/compare_item.dart';
import 'package:gemworld/features/product_detail/domain/adapters/rough_product_detail.dart';
import 'package:gemworld/features/product_detail/domain/models/product_price_labels.dart';
import 'package:gemworld/features/product_detail/presentation/widgets/luxe/luxe_rough_detail.dart';
import 'package:gemworld/features/rough_diamonds/data/mappers/rough_parcel_mapper.dart';
import 'package:gemworld/features/rough_diamonds/data/mappers/rough_search_request_mapper.dart';
import 'package:gemworld/features/rough_diamonds/domain/models/rough_filter_state.dart';
import 'package:gemworld/features/rough_diamonds/domain/models/rough_parcel.dart';
import 'package:gemworld/features/rough_diamonds/domain/models/rough_sort_option.dart';

/// A live-shaped parcel (KI179 tender, two lots), decimals as strings.
Map<String, dynamic> _json({
  bool separable = true,
  bool lotSold = false,
  bool offers = true,
  String? auctionId,
}) => {
  'id': 'p-1',
  'sellerId': 's-1',
  'stockNumber': 'KI179-508',
  'diamondType': 'NATURAL',
  'title': null,
  'displayName': '631.17 ct natural rough · Octahedron',
  'available': 'yes',
  'crystalShape': 'Octahedron',
  'roughQuality': 'Gem quality',
  'parcelType': 'Sorted parcel',
  'isSeparable': separable ? 'Yes' : 'No',
  'totalCaratWeight': '631.17',
  'totalPcs': 185,
  'pricePerCarat': '815',
  'totalPrice': '514403.55',
  'estimatedYield': '42.5',
  'image1': null,
  'image2': 'https://cdn.example/rough.jpg',
  'kpCertificateNumber': 'KP-001',
  'description': 'Tender KI179, lot 508.',
  'isMakeAnOfferAllowed': offers,
  'maxOfferAttemptsPerUser': 5,
  'seller': {
    'id': 's-1',
    'userId': 'u-1',
    'companyName': 'GemWorld Rough',
    'isVerified': true,
    'averageRating': null,
    'reviewCount': 0,
  },
  'lots': [
    {
      'id': 'lot-b',
      'position': 1,
      'sieveSize': '2.5 - 4 Cts',
      'pieces': 49,
      'caratWeight': '167.49',
      'pricePerCarat': '815',
      'totalPrice': '136504.35',
      'notes': 'Sub-lot 508B',
      'isSold': lotSold,
      'isReserved': false,
    },
    {
      'id': 'lot-a',
      'position': 0,
      'sieveSize': '2.5 - 4 Cts',
      'pieces': 136,
      'caratWeight': '463.68',
      'averageCaratPerPiece': '3.41',
      'pricePerCarat': '815',
      'totalPrice': '377899.2',
      'notes': 'Sub-lot 508A',
      'isSold': false,
      'isReserved': false,
    },
  ],
  'auctionId': auctionId,
  'buy': {
    'onSale': true,
    'separable': separable,
    'canBuyWhole': !lotSold,
    'canBuyLots': separable,
    'freeLotIds': [if (!lotSold) 'lot-b', 'lot-a'],
    'remainingCarat': lotSold ? 463.68 : 631.17,
    'remainingPrice': lotSold ? 377899.2 : 514403.55,
  },
};

RoughParcel _parcel({
  bool separable = true,
  bool lotSold = false,
  bool offers = true,
  String? auctionId,
}) => RoughParcelMapper.fromJson(
  _json(
    separable: separable,
    lotSold: lotSold,
    offers: offers,
    auctionId: auctionId,
  ),
);

void main() {
  group('RoughParcelMapper', () {
    test('parses decimal strings, images, lots by position and buy', () {
      final p = _parcel();
      expect(p.totalCaratWeight, 631.17);
      expect(p.totalPrice, 514403.55);
      expect(p.estimatedYield, 42.5);
      expect(p.images, ['https://cdn.example/rough.jpg']);
      expect(p.lots.map((l) => l.id), ['lot-a', 'lot-b']);
      expect(p.lots.first.caratPerPiece, 3.41);
      expect(p.lots.last.caratPerPiece, closeTo(167.49 / 49, 1e-9));
      expect(p.buy.canBuyLots, isTrue);
      expect(p.buy.freeLotIds, {'lot-a', 'lot-b'});
      expect(p.isLab, isFalse);
      expect(p.seller?.companyName, 'GemWorld Rough');
    });

    test('a sold lot is never free to pick', () {
      final p = _parcel(lotSold: true);
      final sold = p.lotById('lot-b')!;
      expect(sold.isTaken, isTrue);
      expect(p.isLotFree(sold), isFalse);
      expect(p.isLotFree(p.lotById('lot-a')!), isTrue);
    });

    test('facets keep counts and plain-number ranges', () {
      final f = RoughParcelMapper.facetsFromJson({
        'total': 91,
        'facets': {
          'crystalShape': [
            {'value': 'Octahedron', 'count': 12},
          ],
          'sieveSize': [],
        },
        'ranges': {
          'carat': {'min': 4.84, 'max': 631.17},
        },
      });
      expect(f.total, 91);
      expect(f.of('crystalShape').single.count, 12);
      expect(f.of('sieveSize'), isEmpty);
      expect(f.ranges['carat']!.max, 631.17);
    });
  });

  group('RoughSearchRequestMapper', () {
    test('drops empty lists, false flags and unset bounds', () {
      final filters = const RoughFilterState()
          .toggle('crystalShape', 'Octahedron')
          .toggle('crystalShape', 'Macle')
          .toggle('parcelType', 'Single stone')
          .toggle('parcelType', 'Single stone')
          .setFlag('separableOnly', true)
          .setFlag('withVideo', false)
          .setRange(RoughRange.carat, 5, 50)
          .setRange(RoughRange.price, 0, 0)
          .copyWith(search: '  KI179 ');
      final body = RoughSearchRequestMapper.toBody(
        filters: filters,
        page: 1,
        pageSize: 24,
        sort: RoughSortOption.priceAsc,
      );
      expect(body, {
        'diamondType': 'natural',
        'sort': 'price-asc',
        'page': 1,
        'limit': 24,
        'crystalShape': ['Octahedron', 'Macle'],
        'separableOnly': true,
        'caratMin': 5.0,
        'caratMax': 50.0,
        'search': 'KI179',
      });
    });

    test('allTypes leaves diamondType out; limit is capped at 200', () {
      final body = RoughSearchRequestMapper.toBody(
        filters: const RoughFilterState(diamondType: RoughDiamondType.lab),
        page: 0,
        pageSize: 500,
        sort: RoughSortOption.newest,
        sellerId: 's-1',
        allTypes: true,
      );
      expect(body.containsKey('diamondType'), isFalse);
      expect(body['limit'], 200);
      expect(body['page'], 1);
      expect(body['sellerId'], 's-1');
    });
  });

  group('RoughFilterState', () {
    test('switching tab drops filters the other tab does not have', () {
      final natural = const RoughFilterState()
          .toggle('countryOfOrigin', 'Botswana')
          .toggle('kpStatus', 'Available')
          .toggle('crystalShape', 'Octahedron');
      final lab = natural.withType(RoughDiamondType.lab);
      expect(lab.listOf('countryOfOrigin'), isEmpty);
      expect(lab.listOf('kpStatus'), isEmpty);
      expect(lab.listOf('crystalShape'), {'Octahedron'});
      final back = lab
          .toggle('growthType', 'CVD')
          .withType(RoughDiamondType.natural);
      expect(back.listOf('growthType'), isEmpty);
    });

    test('summary counts per section and cleared() keeps tab + search', () {
      final s = const RoughFilterState(diamondType: RoughDiamondType.lab)
          .toggle('crystalShape', 'Cube')
          .toggle('colorWords', 'White')
          .setFlag('withImages', true)
          .setRange(RoughRange.pieces, 2, 0)
          .copyWith(yieldMin: 40, search: 'cvd');
      final summary = RoughFilterSummary.of(s);
      expect(summary.count(RoughFilterSection.crystal), 1);
      expect(summary.count(RoughFilterSection.colorClarity), 1);
      expect(summary.count(RoughFilterSection.listing), 1);
      expect(summary.count(RoughFilterSection.sizePrice), 2);
      expect(summary.total, 5);
      final cleared = s.cleared();
      expect(RoughFilterSummary.of(cleared).total, 0);
      expect(cleared.diamondType, RoughDiamondType.lab);
      expect(cleared.search, 'cvd');
    });
  });

  group('roughProductDetail', () {
    test('whole-parcel offers only while every lot is free', () {
      expect(roughProductDetail(_parcel()).canMakeAnOffer, isTrue);
      expect(
        roughProductDetail(_parcel(lotSold: true)).canMakeAnOffer,
        isFalse,
      );
      expect(
        roughProductDetail(_parcel(auctionId: 'a-1')).canMakeAnOffer,
        isFalse,
      );
    });

    test('a deleted parcel is not purchasable', () {
      final detail = roughProductDetail(_parcel(), gone: true);
      expect(detail.isPurchasable, isFalse);
      expect(detail.roughDetail!.onSale, isFalse);
    });

    test('spec tabs carry the parcel, terms-less and the description', () {
      final tabs = roughProductDetail(_parcel()).naturalSpecTabs!.tabs;
      expect(tabs.map((t) => t.title), ['Details', 'Description']);
      final sections = tabs.first.sections.map((s) => s.title);
      expect(sections, containsAll(['Parcel', 'Crystal', 'Manufacturing']));
    });

    test('selection keeps free lots only, in tick order, and adds up', () {
      final p = _parcel(lotSold: true);
      final lots = selectedRoughLots(['lot-b', 'lot-a', 'nope'], p);
      expect(lots.map((l) => l.id), ['lot-a']);
      final totals = roughLotTotals(_parcel().lots);
      expect(totals.carat, closeTo(631.17, 1e-6));
      expect(totals.pieces, 185);
      expect(totals.price, closeTo(514403.55, 1e-6));
    });

    test('compare item uses the rough category and glyph', () {
      final item = CompareItem.fromRough(_parcel());
      expect(item.shape, 'Rough');
      expect(item.displayValues['ppc'], r'$815/ct');
      expect(item.numericValues['yield'], 42.5);
    });
  });

  test('cart line names the chosen lots and is priced from them', () {
    final item = CartMapper.cartItemFromJson({
      'id': 'c-1',
      'productId': 'p-1',
      'productType': 'roughDiamond',
      'quantity': 1,
      'specifications': {
        'isRoughLotPurchase': true,
        'lotIds': ['lot-a'],
        'lots': [
          {'id': 'lot-a', 'sieveSize': '+3', 'totalPrice': 12000},
        ],
        'selectedCarat': 12.5,
        'selectedPcs': 30,
        'calculatedPrice': 12000,
      },
      'product': {
        'id': 'p-1',
        'displayName': 'Collection Gem MB, 11.49 ct',
        'totalPrice': '47338.8',
        'available': 'yes',
      },
    });
    expect(item.title, 'Collection Gem MB, 11.49 ct — 1 lot (+3), 12.50 ct');
    expect(item.priceUsd, 12000);
    expect(item.shape, 'Rough');
  });

  group('rough detail widgets', () {
    Future<void> pump(WidgetTester tester, Widget child, double width) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      return tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LuxeScope(child: Scaffold(body: child)),
          ),
        ),
      );
    }

    testWidgets('ticking lots switches the bar to "Add 2 lots"', (
      tester,
    ) async {
      final detail = roughProductDetail(_parcel(offers: false));
      await pump(
        tester,
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: LuxeRoughLots(detail: detail),
              ),
            ),
            LuxeRoughPurchaseBar(
              detail: detail,
              priceLabels: ProductPriceLabels.resolve(
                detail.price,
                grouped: true,
              ),
            ),
          ],
        ),
        360,
      );
      await tester.pump();
      expect(find.text('Add whole parcel'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(2));

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      expect(find.text('Add 1 lot'), findsOneWidget);
      await tester.tap(find.byType(Checkbox).last);
      await tester.pump();
      expect(find.text('Add 2 lots'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('taken lots show their tag and no checkbox', (tester) async {
      final detail = roughProductDetail(_parcel(lotSold: true));
      await pump(
        tester,
        SingleChildScrollView(child: LuxeRoughLots(detail: detail)),
        320,
      );
      await tester.pump();
      expect(find.text('Sold'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an auction replaces the buy buttons', (tester) async {
      final detail = roughProductDetail(_parcel(auctionId: 'a-1'));
      await pump(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: LuxeRoughPurchaseBar(
            detail: detail,
            priceLabels: ProductPriceLabels.resolve(detail.price),
          ),
        ),
        320,
      );
      await tester.pump();
      expect(find.text('Go to auction'), findsOneWidget);
      expect(find.text('Make an Offer'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
