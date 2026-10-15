/// How a shape is faceted: brilliant cuts break light into sparkle with
/// triangular and kite facets, step cuts reflect it in broad parallel
/// steps like a hall of mirrors.
enum SimCutFamily { brilliant, step }

/// The ten classic diamond shapes the simulator offers.
///
/// [catalogValue] is the canonical English name, which doubles as the
/// catalog translation key and the outline art name in `assets/shapes/`.
/// [ratio] is the typical length-to-width ratio of a well cut stone.
enum SimShape {
  round('Round', SimCutFamily.brilliant, 1.0),
  princess('Princess', SimCutFamily.brilliant, 1.0),
  cushion('Cushion', SimCutFamily.brilliant, 1.05),
  oval('Oval', SimCutFamily.brilliant, 1.4),
  emerald('Emerald', SimCutFamily.step, 1.45),
  pear('Pear', SimCutFamily.brilliant, 1.6),
  marquise('Marquise', SimCutFamily.brilliant, 2.0),
  radiant('Radiant', SimCutFamily.brilliant, 1.25),
  asscher('Asscher', SimCutFamily.step, 1.0),
  heart('Heart', SimCutFamily.brilliant, 0.92);

  const SimShape(this.catalogValue, this.family, this.ratio);

  final String catalogValue;
  final SimCutFamily family;
  final double ratio;

  String get svgAsset => 'assets/shapes/$catalogValue.svg';
}
