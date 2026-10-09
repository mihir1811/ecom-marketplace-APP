import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/l10n/app_localizations.dart';
import 'package:gemstone/features/buyer/presentation/widgets/settings/settings_parts.dart';
import 'package:gemstone/features/reference/domain/models/reference_models.dart';
import 'package:gemstone/features/reference/presentation/widgets/buyer/circle_earnings.dart';
import 'package:gemstone/features/reference/presentation/widgets/buyer/circle_invite_card.dart';
import 'package:gemstone/features/reference/presentation/widgets/buyer/circle_people.dart';

const _long =
    'An exceptionally long collector name that keeps going to test wrapping '
    'and ellipsis on the narrowest phones';

const _party = ReferenceParty(
  id: 'u2',
  name: _long,
  email: 'a.very.long.email.address.for.testing@example-domain.com',
  userName: 'collector',
  referralCode: 'GW7Q2K9X',
);

ReferenceRequest _request(String id, ReferenceStatus status) =>
    ReferenceRequest(
      id: id,
      status: status,
      createdAtLabel: '10/08/2026',
      acceptedAtLabel: status == ReferenceStatus.accepted ? '10/09/2026' : null,
      party: _party,
    );

ReferenceProfile _profile({ReferenceRequest? active}) => ReferenceProfile(
  email: 'buyer.with.a.long.address@example-domain.com',
  name: 'Buyer',
  userName: 'buyer',
  referralCode: 'GWBUYER2026XL',
  shareRegisterUrl:
      'https://gemworld.in/register?ref=GWBUYER2026XL&utm=a-long-tail',
  inboundPendingCount: 2,
  inboundAcceptedCount: 14,
  totalCommissionEarned: 1250000.5,
  activeOutbound: active,
  outboundHistory: [_request('h1', ReferenceStatus.rejected)],
);

ReferencePurchase _purchase(String id, double commission) => ReferencePurchase(
  id: id,
  label: 'Order $id',
  amountLabel: '₹12,00,000',
  createdAtLabel: '10/08/2026',
  commissionInr: commission,
  commissionAt: DateTime.now().subtract(const Duration(days: 2)),
  orderStatus: commission < 0 ? 'REJECTED' : 'DELIVERED',
  orderType: 'diamond',
  buyerLabel: _long,
  items: const [
    ReferencePurchaseItem(name: 'Round 1.02ct', productType: 'DIAMOND', quantity: 1),
    ReferencePurchaseItem(name: 'Melee parcel', productType: 'MELEE', quantity: 3),
  ],
);

Future<void> _pumpAt(WidgetTester tester, double width, Widget child) async {
  tester.view.physicalSize = Size(width, 5200);
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
  for (final width in [320.0, 1200.0]) {
    testWidgets('circle and settings parts lay out at ${width.toInt()}px', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        width,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleInviteCard(profile: _profile(), onShare: (_) {}),
            CircleSponsorTile(profile: _profile(), onOpen: () {}),
            CircleSponsorTile(
              profile: _profile(
                active: _request('a1', ReferenceStatus.pending),
              ),
              onOpen: () {},
            ),
            CircleRequestCard(
              request: _request('p1', ReferenceStatus.pending),
              busy: true,
              onDecide: ({required accept}) {},
            ),
            CirclePersonRow(request: _request('c1', ReferenceStatus.accepted)),
            CircleEarningsPanel(
              purchases: [_purchase('1', 1250.5), _purchase('2', -400)],
              loading: false,
              loadingMore: false,
              hasMore: true,
              onRetry: () {},
              onLoadMore: () {},
            ),
            SettingsIdentityCard(
              displayName: _long,
              email: _party.email,
              imageUrl: null,
              isSeller: false,
              verified: false,
              onTap: () {},
            ),
            SettingsThemeChooser(dark: true, onChanged: (_) {}),
            SettingsLanguageChooser(
              selected: AppLocale.hindi,
              onChanged: (_) {},
            ),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: Icons.person_outline_rounded,
                  title: _long,
                  caption: _long,
                  onTap: () {},
                ),
                SettingsRow(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete account',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('earnings range filter narrows the ledger', (tester) async {
    final old = ReferencePurchase(
      id: 'old',
      label: 'Old order',
      amountLabel: '₹1',
      createdAtLabel: '01/01/2024',
      commissionInr: 99,
      commissionAt: DateTime(2024),
    );
    await _pumpAt(
      tester,
      400,
      CircleEarningsPanel(
        purchases: [_purchase('new', 10), old],
        loading: false,
        loadingMore: false,
        hasMore: false,
        onRetry: () {},
        onLoadMore: () {},
      ),
    );
    expect(find.text('Old order'), findsOneWidget);
    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    expect(find.text('Old order'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });
}
