import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/error/failure.dart';
import 'package:gemstone/features/buyer/domain/models/buyer_order.dart';
import 'package:gemstone/features/buyer/domain/models/wishlist_item.dart';
import 'package:gemstone/features/buyer/presentation/maison/maison_kit.dart';
import 'package:gemstone/features/buyer/presentation/widgets/order_detail/order_detail_hero.dart';
import 'package:gemstone/features/buyer/presentation/widgets/order_detail/order_journey.dart';
import 'package:gemstone/features/buyer/presentation/widgets/order_detail/order_refund_panels.dart';
import 'package:gemstone/features/buyer/presentation/widgets/order_detail/order_review_panel.dart';
import 'package:gemstone/features/feedback/application/feedback_providers.dart';
import 'package:gemstone/features/seller/application/seller_reviews_provider.dart';
import 'package:gemstone/features/seller/domain/models/seller_review.dart';
import 'package:gemstone/features/buyer/presentation/widgets/order_detail/order_summary_panels.dart';
import 'package:gemstone/features/buyer/presentation/widgets/order_detail/order_tracking_panel.dart';
import 'package:gemstone/features/buyer/presentation/widgets/orders/buyer_order_card.dart';
import 'package:gemstone/features/buyer/presentation/widgets/refunds/buyer_refund_card.dart';
import 'package:gemstone/features/buyer/presentation/widgets/wishlist/wishlist_piece_card.dart';
import 'package:gemstone/features/payment/domain/models/payment_models.dart';
import 'package:gemstone/features/refunds/application/refund_providers.dart';
import 'package:gemstone/features/refunds/domain/models/refund_request.dart';
import 'package:gemstone/features/tracking/application/order_shipments_provider.dart';
import 'package:gemstone/features/tracking/domain/models/shipment_models.dart';
import 'package:gemstone/features/wallet/domain/models/wallet.dart';
import 'package:gemstone/features/wallet/presentation/widgets/wallet/wallet_vault_card.dart';
import 'package:gemstone/features/wallet/presentation/widgets/wallet/wallet_activity.dart';

const _long =
    'An exceptionally long piece name that keeps going to test wrapping, '
    'ellipsis and overflow on the narrowest phones';

RefundRequest _refund(RefundStatus status) => RefundRequest(
  id: 'r-$status',
  orderId: 'order-1234567890',
  userId: 'u1',
  sellerId: 's1',
  status: status,
  reason: 'Not as described — the stone had a visible inclusion.',
  amountInr: 1250000,
  amountUsd: 15060.24,
  createdAtLabel: '01/10/2026',
  updatedAtLabel: '02/10/2026',
  sellerNote: status == RefundStatus.rejected ? 'Outside policy' : null,
  razorpayRefundId: status == RefundStatus.accepted ? 'rfnd_ABC123XYZ' : null,
  createdAt: DateTime(2026, 10, 1),
  resolvedAt: status.isPending ? null : DateTime(2026, 10, 2),
  seller: const RefundPartySeller(
    id: 's1',
    companyName: 'Maison Lumière Fine Jewels Private Limited',
  ),
);

final _order = PaymentOrder(
  id: 'order-1234567890',
  status: 'PAID',
  amount: 98765432.1,
  amountUsd: 1190000.55,
  currency: 'INR',
  createdAt: DateTime(2026, 10, 1),
  invoiceNumber: 'INV-2026-000123456',
  invoiceUrl: 'https://example.com/invoice.pdf',
  items: const [
    PaymentOrderItem(
      productId: 'p1',
      productType: 'jewellery',
      name: _long,
      quantity: 2,
      unitPrice: 595000,
      lineTotal: 1190000.55,
      sellerId: 's1',
      sellerName: 'Maison Lumière Fine Jewels Private Limited',
    ),
  ],
  pricing: const PaymentOrderPricing(
    subtotal: 1200000,
    discountedSubtotal: 1190000,
    promotionDiscount: 10000,
    gst: 2963000,
    transactionFee: 1975000,
    platformFee: 987000,
    gemworldVerificationCommission: 493000,
    totalUsd: 1190000.55,
    exchangeRate: 83.12,
    subtotalInr: 98765432,
    totalInr: 98765432.1,
  ),
  sellers: const [
    PaymentOrderSeller(
      id: 's1',
      companyName: 'Maison Lumière Fine Jewels Private Limited',
    ),
    PaymentOrderSeller(id: 's2', companyName: 'Atelier Rose'),
  ],
  sellerDecisions: const [
    PaymentOrderSellerDecision(sellerId: 's1', status: 'ACCEPTED'),
    PaymentOrderSellerDecision(
      sellerId: 's2',
      status: 'REJECTED',
      reason: 'Out of stock',
      sellerNote: 'We are truly sorry about this.',
    ),
  ],
);

final _shipment = Shipment(
  id: 'sh1',
  orderId: 'order-1234567890',
  sellerId: 's1',
  status: 'IN_TRANSIT',
  carrier: 'Brink’s Global Services International',
  trackingNumber: 'BRK-998877665544332211',
  currentLocation: 'Mumbai International Airport Cargo Terminal',
  updates: [
    TrackingUpdate(
      id: 'u1',
      shipmentId: 'sh1',
      status: 'SHIPPED',
      location: 'Surat',
      note: 'Handed to insured courier',
      createdAt: DateTime(2026, 10, 2, 9, 30),
    ),
  ],
);

Future<void> _pumpAt(WidgetTester tester, double width, Widget child) async {
  tester.view.physicalSize = Size(width, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        orderShipmentsProvider.overrideWith((ref, _) async => [_shipment]),
        shipmentDetailProvider.overrideWith((ref, _) async => _shipment),
        orderRefundsProvider.overrideWith(
          (ref, _) async => [_refund(RefundStatus.pending)],
        ),
        orderFeedbackProvider.overrideWith((ref, _) async => const []),
        orderSellerReviewsProvider.overrideWith(
          (ref, _) async => [
            SellerReview(
              id: 'rv1',
              sellerId: 's1',
              userId: 'u2',
              orderId: 'order-1234567890',
              rating: 4,
              title: 'Beautifully packed',
              comment: _long,
              sellerReply: 'Thank you for choosing us.',
              userName: 'A very long buyer display name indeed',
              sellerName: 'Maison Lumière Fine Jewels Private Limited',
              createdAt: DateTime(2026, 10, 3),
            ),
          ],
        ),
      ],
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
  for (final width in [320.0, 1200.0]) {
    testWidgets('buyer cards lay out without overflow at ${width.toInt()}px', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        width,
        Column(
          children: [
            BuyerOrderCard(
              order: BuyerOrder(
                id: 'order-1234567890',
                productLabel: _long,
                sellerName: 'Maison Lumière Fine Jewels Private Limited',
                status: 'PAID',
                amountInr: 98765432.1,
                amountUsd: 1190000.55,
                currency: 'INR',
                createdAt: DateTime(2026, 10, 1),
                itemCount: 3,
                sellerDecision: 'PENDING',
              ),
              onTap: () {},
            ),
            for (final s in RefundStatus.values)
              BuyerRefundCard(refund: _refund(s)),
            const WalletFlow(
              transactions: [
                WalletTransaction(
                  id: 't1',
                  type: 'TOP_UP',
                  amount: 5000,
                  balanceAfter: 5000,
                  currency: 'INR',
                ),
                WalletTransaction(
                  id: 't2',
                  type: 'ORDER_PAYMENT',
                  amount: -3200,
                  balanceAfter: 1800,
                  currency: 'INR',
                ),
              ],
            ),
            SizedBox(
              width: 170,
              height: 274,
              child: WishlistPieceCard(
                item: WishlistItem(
                  id: 'w1',
                  category: WishlistCategory.jewelry,
                  title: _long,
                  subtitle: 'Ring · 18k Rose Gold',
                  priceLabel: '\$12,480',
                ),
                onRemove: () {},
              ),
            ),
            WishlistPieceCard(
              compact: true,
              item: WishlistItem(
                id: 'w2',
                category: WishlistCategory.watch,
                title: _long,
                subtitle: '2021 · Platinum',
                priceLabel: '\$88,000',
              ),
              onRemove: () {},
            ),
            OrderDetailHero(order: _order, onShortcut: (_) {}),
            OrderJourneyPanel(order: _order),
            OrderItemsPanel(order: _order),
            OrderPaymentPanel(order: _order),
            const OrderTrackingPanel(orderId: 'order-1234567890'),
            OrderRefundPanel(order: _order),
            OrderRejectionPanel(order: _order),
            OrderReviewPanel(order: _order),
            const WalletVaultCard(
              wallet: Wallet(
                id: 'w-1234',
                balance: 98765432.1,
                currency: 'INR',
              ),
            ),
            MaisonListFooter(
              loadingMore: false,
              hasMore: false,
              onLoadMore: () {},
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      // Let staggered reveals and sheens finish before teardown.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('MaisonActionDialog shows a failure inline and stays open', (
    tester,
  ) async {
    final results = <bool?>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await showDialog<bool>(
                  context: context,
                  builder: (_) => MaisonActionDialog(
                    title: 'Withdraw this request?',
                    message: 'It will be closed.',
                    confirmLabel: 'Withdraw',
                    onConfirm: (_) async => const NetworkFailure('offline'),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();
    expect(find.text('offline'), findsOneWidget);
    expect(results, isEmpty);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(results, [false]);
  });
}
