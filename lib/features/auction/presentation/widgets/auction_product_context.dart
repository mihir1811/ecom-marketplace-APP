import '../../../cart/domain/models/cart_product_type.dart';
import '../../domain/models/auction_models.dart';

/// Compact product facts for auction cards (origin, grades, cert).
///
/// Keeps labels short and skips facts already present in [AuctionListing.title]
/// so list cards stay readable at a glance.
List<String> auctionProductContextTags(AuctionListing auction) {
  final product = auction.product;
  final title = auction.title.toLowerCase();
  final tags = <String>[];

  void add(String? value, {bool skipIfInTitle = false}) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return;
    if (tags.any((t) => t.toLowerCase() == text.toLowerCase())) return;
    if (skipIfInTitle && title.contains(text.toLowerCase())) return;
    tags.add(text);
  }

  add(_originOrType(auction.productType, product));

  switch (auction.productType) {
    case CartProductType.diamond:
    case CartProductType.meleeDiamond:
      add(_titleCase(_str(product['shape'])), skipIfInTitle: true);
      add(_caratLabel(product), skipIfInTitle: true);
      add(_gradePair(product));
      add(_certShort(product));
    case CartProductType.gemstone:
      add(
        _titleCase(_str(product['gemsType'])) ??
            _titleCase(_str(product['type'])),
        skipIfInTitle: true,
      );
      add(_titleCase(_str(product['shape'])), skipIfInTitle: true);
      add(_caratLabel(product), skipIfInTitle: true);
      add(_titleCase(_str(product['color'])));
    case CartProductType.jewellery:
      add(_titleCase(_str(product['category'])));
      add(_titleCase(_str(product['metalType']) ?? _str(product['metal'])));
    case CartProductType.watch:
      add(_titleCase(_str(product['brand'])));
      add(_titleCase(_str(product['model'])), skipIfInTitle: true);
    case CartProductType.bullion:
      add(_titleCase(_str(product['metal'])));
      add(_str(product['purity']));
    default:
      add(_titleCase(_str(product['shape'])), skipIfInTitle: true);
      add(_caratLabel(product), skipIfInTitle: true);
  }

  return tags.take(3).toList(growable: false);
}

/// One-line summary for tight cards: `"Natural · E VVS2 · GIA"`.
String auctionProductContextLine(AuctionListing auction) {
  return auctionProductContextTags(auction).join(' · ');
}

String _originOrType(String productType, Map<String, dynamic> product) {
  return switch (productType) {
    CartProductType.diamond =>
      _isLabGrown(product) ? 'Lab Grown' : 'Natural',
    CartProductType.meleeDiamond =>
      _isLabGrown(product) ? 'Lab Melee' : 'Natural Melee',
    CartProductType.gemstone =>
      _isLabGrown(product) ? 'Lab Gemstone' : 'Gemstone',
    CartProductType.jewellery => 'Jewelry',
    CartProductType.watch => 'Watch',
    CartProductType.bullion => 'Bullion',
    _ => CartProductType.label(productType),
  };
}

String? _gradePair(Map<String, dynamic> product) {
  final color = _grade(_str(product['color']) ?? _str(product['fancyColor']));
  final clarity = _grade(_str(product['clarity']));
  final parts = [color, clarity].whereType<String>().toList();
  if (parts.isEmpty) return null;
  return parts.join(' ');
}

String? _grade(String? value) {
  if (value == null || value.isEmpty) return null;
  return value.toUpperCase();
}

bool _isLabGrown(Map<String, dynamic> product) {
  final growth = (_str(product['growthType']) ?? '').toLowerCase();
  if (growth == 'cvd' || growth == 'hpht' || growth.contains('lab')) {
    return true;
  }
  final flag = product['isLabGrown'];
  if (flag == true || flag == 'true') return true;
  final stoneType = (_str(product['stoneType']) ?? '').toLowerCase();
  return stoneType.contains('lab');
}

String? _caratLabel(Map<String, dynamic> product) {
  final carat =
      _num(product['caratWeight']) ??
      _num(product['totalCaratWeight']) ??
      _num(product['totalCarat']) ??
      _num(product['carat']);
  if (carat == null || carat <= 0) return null;
  final text = carat == carat.roundToDouble()
      ? carat.toStringAsFixed(0)
      : carat
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
  return '$text ct';
}

String? _certShort(Map<String, dynamic> product) {
  final cert =
      _str(product['certificateCompanyName']) ?? _str(product['certification']);
  if (cert == null) return null;
  if (cert.length <= 8) return cert.toUpperCase();
  return cert.split(RegExp(r'[\s/_-]+')).first.toUpperCase();
}

String? _str(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text == 'null') return null;
  return text;
}

double? _num(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String? _titleCase(String? value) {
  if (value == null || value.isEmpty) return null;
  return value
      .split(RegExp(r'[\s_]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}
