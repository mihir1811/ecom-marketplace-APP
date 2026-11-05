import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/features/diamonds/presentation/widgets/stone_tint.dart';

void main() {
  double hue(Color c) => HSLColor.fromColor(c).hue;
  double lightness(Color c) => HSLColor.fromColor(c).lightness;
  double saturation(Color c) => HSLColor.fromColor(c).saturation;

  test('a fancy colour sets the hue', () {
    final pink = StoneTint.resolve(grade: 'Fancy', fancyColor: 'Pink');
    expect(hue(pink.body), closeTo(hue(StoneTint.hueOf('pink')!), 1));
  });

  test('intensity moves lightness and saturation', () {
    final faint = StoneTint.resolve(fancyColor: 'Pink', intensity: 'Faint');
    final vivid = StoneTint.resolve(
      fancyColor: 'Pink',
      intensity: 'Fancy Vivid',
    );
    final deep = StoneTint.resolve(fancyColor: 'Pink', intensity: 'Fancy Deep');
    expect(lightness(faint.body), greaterThan(lightness(vivid.body)));
    expect(saturation(faint.body), lessThan(saturation(vivid.body)));
    expect(lightness(deep.body), lessThan(lightness(vivid.body)));
  });

  test('intensity written into the colour itself is read too', () {
    expect(
      StoneTint.resolve(fancyColor: 'Fancy Light Pink'),
      StoneTint.resolve(fancyColor: 'Pink', intensity: 'Fancy Light'),
    );
  });

  test('an overtone pulls the shaded side towards its hue', () {
    final plain = StoneTint.resolve(fancyColor: 'Pink');
    final purplish = StoneTint.resolve(
      fancyColor: 'Pink',
      overtone: 'Purplish',
    );
    expect(purplish.deep, isNot(plain.deep));
    expect(StoneTint.resolve(fancyColor: 'Purplish Pink'), purplish);
  });

  test('a D–Z grade runs from icy white towards yellow', () {
    final d = StoneTint.resolve(grade: 'D');
    final m = StoneTint.resolve(grade: 'M');
    expect(lightness(d.body), greaterThan(0.9));
    expect(saturation(m.body), greaterThan(saturation(d.body)));
  });

  test('gemstones fall back on colour name, then species', () {
    expect(
      hue(StoneTint.resolve(grade: 'Blue').body),
      closeTo(hue(StoneTint.hueOf('blue')!), 1),
    );
    final ruby = StoneTint.resolve(species: 'Burmese Ruby');
    expect(hue(ruby.body), anyOf(lessThan(15), greaterThan(340)));
  });

  test('multi-colour stones sweep a spectrum; nothing reads colourless', () {
    expect(StoneTint.resolve(fancyColor: 'Multi').spectrum, isNotNull);
    expect(StoneTint.resolve(), StoneTint.resolve(grade: 'D'));
  });
}
