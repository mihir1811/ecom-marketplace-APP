import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/features/diamonds/domain/melee_lot_figures.dart';
import 'package:gemworld/features/diamonds/domain/models/diamond.dart';

Diamond _melee({
  double carat = 0,
  double price = 1000,
  int? totalPcs,
  double? totalCarat,
  double? caratPerPcs,
  double? pricePerPcs,
  double? pricePerCarat,
  String? sieve,
}) => Diamond(
  id: 'm',
  shape: 'Round',
  carat: carat,
  price: price,
  cut: '',
  color: '',
  clarity: '',
  certificate: '',
  isMelee: true,
  totalPcs: totalPcs,
  totalCaratWeight: totalCarat,
  caratPerPcs: caratPerPcs,
  pricePerPcs: pricePerPcs,
  pricePerCarat: pricePerCarat,
  sieveLabel: sieve,
);

void main() {
  test('seller values pass through, nothing approximate', () {
    final f = MeleeLotFigures.of(
      _melee(
        totalPcs: 100,
        totalCarat: 2,
        pricePerPcs: 10,
        pricePerCarat: 500,
      ),
    );
    expect(f.totalPcs, 100);
    expect(f.totalCarat, 2);
    expect(f.pricePerPcs, 10);
    expect(f.pricePerCarat, 500);
    expect(f.pcsApprox, isFalse);
    expect(f.caratApprox, isFalse);
  });

  test('missing pieces estimated from sieve, flagged approximate', () {
    // +2.5 -3 → 0.010 ct per stone.
    final f = MeleeLotFigures.of(_melee(totalCarat: 2, sieve: '+2.5 -3'));
    expect(f.totalPcs, 200);
    expect(f.pricePerPcs, 5);
    expect(f.pcsApprox, isTrue);
    expect(f.caratApprox, isFalse);
    expect(f.pricePerCarat, 500);
  });

  test('missing carat estimated from pieces and sieve range', () {
    // +2 (0.009) – +3 (0.011) → 0.010 average.
    final f = MeleeLotFigures.of(_melee(totalPcs: 100, sieve: '+2–+3'));
    expect(f.totalCarat, closeTo(1.0, 1e-9));
    expect(f.caratApprox, isTrue);
    expect(f.pcsApprox, isFalse);
  });

  test('pieces and carat both given: per-piece carat is exact', () {
    final f = MeleeLotFigures.of(_melee(totalPcs: 50, totalCarat: 1));
    expect(f.caratPerPcs, 0.02);
    expect(f.caratPerPcsApprox, isFalse);
  });

  test('worked out once per diamond, fresh for a new diamond', () {
    final d = _melee(totalPcs: 50, totalCarat: 1, sieve: '+2 -2.5');
    expect(identical(MeleeLotFigures.of(d), MeleeLotFigures.of(d)), isTrue);
    final other = _melee(totalPcs: 25, totalCarat: 1);
    expect(MeleeLotFigures.of(other).caratPerPcs, 0.04);
  });

  test('sieve chart lookup: full name, bare number and mm', () {
    expect(
      MeleeLotFigures.sieveCaratPerPcs(_melee(sieve: '+2 -2.5')),
      isNotNull,
    );
    expect(MeleeLotFigures.sieveCaratPerPcs(_melee(sieve: '2')), isNotNull);
    expect(MeleeLotFigures.sieveCaratPerPcs(_melee(sieve: 'abc')), isNull);
  });
}
