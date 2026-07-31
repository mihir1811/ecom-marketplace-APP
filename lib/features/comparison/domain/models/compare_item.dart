import '../../../diamonds/domain/models/diamond.dart';
import '../../../diamonds/domain/models/diamond_display.dart';
import '../../../gemstones/domain/models/gemstone.dart';
import '../../../watches/domain/models/watch.dart';
import 'compare_category.dart';
import '../../../../core/utils/app_currency.dart';

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
    final shape = DiamondDisplay.shape(d.shape);
    final title = '${d.carat}ct $shape';
    final uploadedImages = [
      for (final u in d.imageUrls)
        if (u.trim().isNotEmpty) u.trim(),
    ];
    return CompareItem(
      id: d.id,
      category: CompareCategory.diamond,
      title: title,
      price: d.price,
      imageUrl: uploadedImages.isNotEmpty ? uploadedImages.first : d.imageUrl,
      shape: d.shape,
      subtitle: d.isLabGrown ? 'Lab Grown' : 'Natural',
      displayValues: {
        'price': AppCurrency.format(_fmtPrice(d.price)),
        'carat': '${d.carat}ct',
        'shape': shape,
        'measurements': DiamondDisplay.text(d.measurement),
        'certificate': DiamondDisplay.text(d.certificate, uppercase: true),
        'cut': DiamondDisplay.text(d.cut, uppercase: true),
        'color': DiamondDisplay.text(d.color, uppercase: true),
        'clarity': DiamondDisplay.text(d.clarity, uppercase: true),
        'table': DiamondDisplay.text(d.tablePercent),
        'depth': DiamondDisplay.text(d.depthPercent),
        'ratio': DiamondDisplay.text(d.ratio),
        'polish': DiamondDisplay.text(d.polish, uppercase: true),
        'symmetry': DiamondDisplay.text(d.symmetry, uppercase: true),
        'fluorescence': DiamondDisplay.text(d.fluorescence, uppercase: true),
        'lab': DiamondDisplay.text(d.lab ?? d.certificate, uppercase: true),
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
      imageUrl: g.hasNetworkImage ? g.imageUrl : null,
      shape: g.shape,
      subtitle: g.origin,
      displayValues: {
        'price': AppCurrency.format(_fmtPrice(g.price)),
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
      imageUrl: w.renderableImageUrl,
      subtitle: w.brand,
      displayValues: {
        'price': AppCurrency.format(_fmtPrice(w.price)),
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
