import '../../../diamonds/domain/models/diamond.dart';
import '../../../gemstones/domain/models/gemstone.dart';
import '../../../watches/domain/models/watch.dart';
import 'compare_category.dart';

/// Snapshot of a product placed in the comparison tray.
class CompareItem {
  const CompareItem({
    required this.id,
    required this.category,
    required this.title,
    required this.price,
    required this.displayValues,
    required this.numericValues,
    this.imageUrl,
    this.shape,
    this.subtitle,
  });

  final String id;
  final CompareCategory category;
  final String title;
  final double price;
  final String? imageUrl;
  final String? shape;
  final String? subtitle;

  /// Spec key → display string shown in the comparison table.
  final Map<String, String> displayValues;

  /// Spec key → numeric value used for leading-option logic (nullable).
  final Map<String, double?> numericValues;

  factory CompareItem.fromDiamond(Diamond d) {
    final title = '${d.carat}ct ${d.shape.toLowerCase()}';
    return CompareItem(
      id: d.id,
      category: CompareCategory.diamond,
      title: title,
      price: d.price,
      imageUrl: d.imageUrl,
      shape: d.shape,
      subtitle: d.isLabGrown ? 'Lab Grown' : 'Natural',
      displayValues: {
        'price': '\$${_fmtPrice(d.price)}',
        'carat': '${d.carat}ct',
        'shape': d.shape,
        'measurements': 'N/A',
        'certificate': d.certificate,
        'cut': d.cut,
        'color': d.color,
        'clarity': d.clarity,
        'table': 'N/A',
        'depth': 'N/A',
        'ratio': 'N/A',
        'polish': d.polish ?? 'N/A',
        'symmetry': d.symmetry ?? 'N/A',
        'fluorescence': d.fluorescence ?? 'N/A',
        'lab': d.lab ?? d.certificate,
      },
      numericValues: {
        'price': d.price,
        'carat': d.carat,
      },
    );
  }

  factory CompareItem.fromGemstone(Gemstone g) {
    return CompareItem(
      id: g.id,
      category: CompareCategory.gemstone,
      title: '${g.carat}ct ${g.type}',
      price: g.price,
      imageUrl: g.imageUrl,
      shape: g.shape,
      subtitle: g.origin,
      displayValues: {
        'price': '\$${_fmtPrice(g.price)}',
        'carat': '${g.carat}ct',
        'type': g.type,
        'origin': g.origin,
        'cut': g.cut ?? 'N/A',
        'color': g.color,
        'clarity': g.clarity,
        'treatment': g.treatment,
        'dimensions': g.dimensions,
        'shape': g.shape,
        'hardness': g.hardness.toString(),
        'lab': g.lab,
        'certificate': g.certificate ?? 'N/A',
      },
      numericValues: {
        'price': g.price,
        'carat': g.carat,
        'hardness': g.hardness,
      },
    );
  }

  factory CompareItem.fromWatch(Watch w) {
    return CompareItem(
      id: w.id,
      category: CompareCategory.watch,
      title: '${w.brand} ${w.model}',
      price: w.price,
      imageUrl: w.imageUrl,
      subtitle: w.brand,
      displayValues: {
        'price': '\$${_fmtPrice(w.price)}',
        'brand': w.brand,
        'model': w.model,
        'movement': w.movement,
        'caseMaterial': w.caseMaterial,
        'dialColor': w.dialColor,
        'gender': w.gender,
        'year': '${w.year}',
      },
      numericValues: {
        'price': w.price,
        'year': w.year.toDouble(),
      },
    );
  }

  static String _fmtPrice(double price) {
    if (price >= 1000) {
      final s = price.toStringAsFixed(0);
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        final fromEnd = s.length - i;
        buf.write(s[i]);
        if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
      }
      return buf.toString();
    }
    return price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2);
  }
}
