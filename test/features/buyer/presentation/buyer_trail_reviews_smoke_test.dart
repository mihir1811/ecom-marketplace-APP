import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/features/buyer/presentation/widgets/reviews/buyer_review_card.dart';
import 'package:gemworld/features/buyer/presentation/widgets/reviews/review_ledger.dart';
import 'package:gemworld/features/recently_viewed/domain/models/recently_viewed.dart';
import 'package:gemworld/features/recently_viewed/presentation/widgets/recent/recent_piece.dart';
import 'package:gemworld/features/recently_viewed/presentation/widgets/recent/recent_piece_card.dart';
import 'package:gemworld/features/recently_viewed/presentation/widgets/recent/recent_resume_card.dart';
import 'package:gemworld/features/seller/domain/models/seller_review.dart';

const _long =
    'An exceptionally long piece name that keeps going to test wrapping, '
    'ellipsis and overflow on the narrowest phones';

RecentlyViewedEntry _entry(String type, {String? availability}) =>
    RecentlyViewedEntry(
      id: 'rv-$type',
      productId: 'p-$type',
      productType: type,
      viewedAtLabel: '08/10/2026',
      viewedAt: DateTime.now().subtract(const Duration(hours: 2)),
      productTitle: _long,
      stockNumber: 'STK-0001234567',
      price: '1250000.50',
      carat: 3.02,
      shape: 'Cushion',
      color: 'D',
      clarity: 'VVS1',
      cut: 'Excellent',
      availability: availability,
    );

SellerReview _review(int rating, {bool visible = true, String? reply}) =>
    SellerReview(
      id: 'r$rating',
      sellerId: 's$rating',
      userId: 'u1',
      orderId: 'order-1234567890',
      rating: rating,
      title: 'Beautifully packed and exactly as pictured, truly',
      comment: '$_long. $_long. $_long.',
      isVisible: visible,
      sellerReply: reply,
      repliedAt: DateTime(2026, 10, 4),
      sellerName: 'Maison Lumière Fine Jewels Private Limited',
      createdAt: DateTime(2026, 10, 3),
      updatedAt: DateTime(2026, 10, 5),
    );

Future<void> _pumpAt(WidgetTester tester, double width, Widget child) async {
  tester.view.physicalSize = Size(width, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1600));
}

void main() {
  test('recent piece helpers fold availability and comparison', () {
    expect(RecentAvailability.of('yes'), RecentAvailability.available);
    expect(RecentAvailability.of('hold'), RecentAvailability.reserved);
    expect(RecentAvailability.of('sold'), RecentAvailability.gone);
    expect(RecentAvailability.of(null), RecentAvailability.unknown);
    expect(_entry('diamond').toCompareItem(), isNotNull);
    expect(_entry('jewellery').toCompareItem(), isNull);
    expect(_entry('diamond').priceValue, 1250000.5);
    expect(reviewRatingWord(5), 'Exceptional');
    expect(reviewRatingWord(0), 'Not rated');
  });

  for (final width in [320.0, 1200.0]) {
    testWidgets('trail and review cards lay out at ${width.toInt()}px', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        width,
        Column(
          children: [
            RecentResumeCard(entry: _entry('diamond', availability: 'yes')),
            SizedBox(
              width: 160,
              height: 264,
              child: RecentPieceCard(
                entry: _entry('diamond', availability: 'sold'),
              ),
            ),
            RecentPieceCard(
              compact: true,
              entry: _entry('watch', availability: 'hold'),
            ),
            RecentPieceCard(compact: true, entry: _entry('jewellery')),
            ReviewLedgerCard(
              reviews: [_review(5), _review(4), _review(4), _review(1)],
              selectedRating: 4,
              onRating: (_) {},
            ),
            BuyerReviewCard(
              review: _review(4, visible: false, reply: 'Thank you. $_long'),
              onOpenOrder: () {},
            ),
            BuyerReviewCard(review: _review(2), onOpenOrder: () {}),
            const BuyerReviewSkeleton(),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('distribution bars filter by rating and toggle off', (
    tester,
  ) async {
    int? selected = -1;
    await _pumpAt(
      tester,
      400,
      ReviewLedgerCard(
        reviews: [_review(5), _review(3)],
        selectedRating: 5,
        onRating: (r) => selected = r,
      ),
    );
    await tester.tap(find.bySemanticsLabel(RegExp(r'^3 star')));
    expect(selected, 3);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^5 star')));
    expect(selected, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });
}
