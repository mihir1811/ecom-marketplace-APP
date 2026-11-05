import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/features/diamonds/domain/models/diamond.dart';
import 'package:gemworld/features/seller/application/seller_diamond_project_provider.dart';

Diamond _d({
  String shape = 'ROUND',
  String color = 'G',
  String clarity = 'VS1',
  String cut = 'EX',
  String? lab = 'GIA',
  double carat = 1,
  String? ratio,
  String? fancy,
}) => Diamond(
  id: '$shape$color$clarity$carat',
  shape: shape,
  carat: carat,
  price: 1000,
  cut: cut,
  color: color,
  clarity: clarity,
  certificate: lab ?? '',
  lab: lab,
  ratio: ratio,
  fancyColor: fancy,
);

void main() {
  test('facets list only what the inventory holds', () {
    final f = SellerDiamondProjectFacets.fromDiamonds([
      _d(carat: 0.5, ratio: '1.01'),
      _d(shape: 'Oval', color: 'Y-Z', cut: 'VG', lab: 'XYZ', carat: 3.2),
      _d(fancy: 'Yellow', lab: null, ratio: '1.45'),
    ]);

    bool has(Set<String> s, String o) => SellerDiamondProjectFacets.has(s, o);
    expect(has(f.shapes, 'Round'), isTrue);
    expect(has(f.shapes, 'Oval'), isTrue);
    expect(has(f.shapes, 'Pear'), isFalse);
    expect(has(f.colors, 'G'), isTrue);
    expect(has(f.colors, 'Y'), isTrue);
    expect(has(f.colors, 'Z'), isTrue);
    expect(has(f.colors, 'D'), isFalse);
    expect(has(f.cuts, 'Excellent'), isTrue);
    expect(has(f.cuts, 'Very Good'), isTrue);
    expect(has(f.cuts, 'Fair'), isFalse);
    expect(has(f.labs, 'GIA'), isTrue);
    expect(has(f.labs, 'Others'), isTrue);
    expect(has(f.labs, 'IGI'), isFalse);
    expect(has(f.fancyColors, 'Yellow'), isTrue);
    expect(has(f.fancyColors, 'Pink'), isFalse);
    expect(f.minCarat, 0.5);
    expect(f.maxCarat, 3.2);
    expect(f.minRatio, 1.01);
    expect(f.maxRatio, 1.45);
  });
}
