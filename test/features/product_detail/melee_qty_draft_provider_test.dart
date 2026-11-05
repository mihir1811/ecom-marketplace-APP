import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gemworld/features/product_detail/application/melee_qty_draft_provider.dart';
import 'package:gemworld/features/product_detail/domain/models/product_detail.dart';

void main() {
  const qty = ProductMeleeQty(
    totalPcs: 10,
    totalCarat: 2.0,
    caratPerPcs: 0.2,
  );

  test('pieces input updates related carat', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(meleeQtyDraftProvider('p1').notifier);
    notifier.setFromPieces(5, qty);
    final draft = container.read(meleeQtyDraftProvider('p1'));
    expect(draft?.pieces, 5);
    expect(draft?.carat, closeTo(1.0, 0.0001));
  });

  test('carat input updates related pieces', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(meleeQtyDraftProvider('p1').notifier);
    notifier.setFromCarat(1.0, qty);
    final draft = container.read(meleeQtyDraftProvider('p1'));
    expect(draft?.pieces, 5);
    expect(draft?.carat, closeTo(1.0, 0.0001));
  });

  test('proportional price scales with pieces', () {
    const draft = MeleeQtyDraft(inCarat: false, pieces: 5, carat: 1.0);
    expect(draft.proportionalPrice(100, qty), closeTo(50, 0.0001));
  });

  test('proportional price scales with carat in carat mode', () {
    const draft = MeleeQtyDraft(inCarat: true, pieces: 5, carat: 1.0);
    expect(draft.proportionalPrice(100, qty), closeTo(50, 0.0001));
  });

  test('proportional price scales with carat when pcs missing', () {
    const caratOnly = ProductMeleeQty(totalCarat: 2.0);
    const draft = MeleeQtyDraft(inCarat: true, pieces: 0, carat: 1.0);
    expect(draft.proportionalPrice(100, caratOnly), closeTo(50, 0.0001));
  });

  test('toSpecifications matches CART_API melee shape', () {
    const draft = MeleeQtyDraft(inCarat: true, pieces: 21, carat: 215);
    expect(
      draft.toSpecifications(calculatedPrice: 91.75),
      {
        'purchaseUnit': 'carat',
        'selectedPcs': 21,
        'selectedCarat': 215.0,
        'calculatedPrice': 91.75,
      },
    );
  });

  test('pieces input clamps to total available', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(meleeQtyDraftProvider('p1').notifier);
    notifier.setFromPieces(999, qty);
    final draft = container.read(meleeQtyDraftProvider('p1'));
    expect(draft?.pieces, 10);
    expect(draft?.carat, closeTo(2.0, 0.0001));
  });

  test('carat input clamps to total available', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(meleeQtyDraftProvider('p1').notifier);
    notifier.setFromCarat(99, qty);
    final draft = container.read(meleeQtyDraftProvider('p1'));
    expect(draft?.carat, closeTo(2.0, 0.0001));
    expect(draft?.pieces, 10);
  });

  test('resolvedCaratPerPcs prefers lot totals over stale per-pcs', () {
    const qty = ProductMeleeQty(
      totalPcs: 23,
      totalCarat: 234.34,
      caratPerPcs: 34.3,
    );
    expect(qty.resolvedCaratPerPcs, closeTo(234.34 / 23, 0.0001));
  });
}
