import '../../../bullions/domain/models/billion.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../../../gemstones/domain/models/gemstone.dart';
import '../../../jewelry/domain/models/jewelry.dart';
import '../../../watches/domain/models/watch.dart';

class RecentlyViewedEntry {
  const RecentlyViewedEntry({
    required this.id,
    required this.productId,
    required this.productType,
    required this.viewedAtLabel,
    this.viewedAt,
    this.stockNumber,
    this.productTitle,
    this.imageUrl,
    this.price,
    this.carat,
    this.shape,
    this.color,
    this.clarity,
    this.cut,
    this.availability,
    this.diamond,
    this.gemstone,
    this.watch,
    this.jewelry,
    this.bullion,
  });

  final String id;
  final String productId;
  final String productType;
  final String viewedAtLabel;

  /// When the piece was last opened, if the API sent a parsable date.
  final DateTime? viewedAt;
  final String? stockNumber;
  final String? productTitle;
  final String? imageUrl;
  final String? price;
  final double? carat;
  final String? shape;
  final String? color;
  final String? clarity;
  final String? cut;
  final String? availability;
  final Diamond? diamond;
  final Gemstone? gemstone;
  final Watch? watch;
  final Jewelry? jewelry;
  final Bullion? bullion;

  String get displayTitle {
    final title = productTitle?.trim();
    final stock = _optional(stockNumber);
    final titleIsStock =
        title != null &&
        stock != null &&
        title.toLowerCase() == stock.toLowerCase();
    if (title != null && title.isNotEmpty && !titleIsStock) {
      return title;
    }
    if (carat != null) {
      final parts = <String>['${carat!.toStringAsFixed(2)}ct'];
      if (_optional(shape) != null) parts.add(shape!);
      return parts.join(' ');
    }
    if (title != null && title.isNotEmpty) return title;
    if (_optional(stockNumber) != null) return stockNumber!;
    final typeLabel = productType.isNotEmpty
        ? _capitalizeType(productType)
        : null;
    if (typeLabel != null) return typeLabel;
    return 'Untitled product';
  }

  /// List-style title: prefer carat + shape (+ cut) like listing cards.
  String get listTitle {
    if (carat != null) {
      final caratLabel = '${carat!.toStringAsFixed(2)}ct';
      final shapeLabel = _optional(shape);
      final cutLabel = _optional(cut);
      if (shapeLabel != null &&
          cutLabel != null &&
          shapeLabel.toLowerCase() != cutLabel.toLowerCase()) {
        return '$caratLabel $shapeLabel $cutLabel';
      }
      if (shapeLabel != null) return '$caratLabel $shapeLabel';
      if (cutLabel != null) return '$caratLabel $cutLabel';
    }
    return displayTitle;
  }

  static String _capitalizeType(String type) {
    return type
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .trim()
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  static String? _optional(String? value) {
    if (value == null) return null;
    final t = value.trim();
    if (t.isEmpty ||
        t == '-' ||
        t == '—' ||
        t == '–' ||
        t.toLowerCase() == 'n/a') {
      return null;
    }
    return t;
  }

  /// Color · Clarity · Cut — listing-style grades line.
  String? get detailLine {
    final parts = <String>[];
    final colorLabel = _optional(color);
    final clarityLabel = _optional(clarity);
    final cutLabel = _optional(cut);
    if (colorLabel != null) parts.add(colorLabel);
    if (clarityLabel != null) parts.add(clarityLabel);
    if (cutLabel != null) parts.add(cutLabel);
    if (parts.isEmpty) {
      final shapeLabel = _optional(shape);
      if (shapeLabel != null) parts.add(shapeLabel);
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  /// Stock · viewed date — listing-style meta line.
  String? get metaLine {
    final parts = <String>[];
    if (_optional(stockNumber) != null) {
      parts.add('Stock $stockNumber');
    }
    if (viewedAtLabel.isNotEmpty && viewedAtLabel != '—') {
      parts.add('Viewed $viewedAtLabel');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  String get listDetailLine => detailLine ?? 'Specs unavailable';
}

class RecentlyViewedId {
  const RecentlyViewedId({required this.productId, required this.productType});

  final String productId;
  final String productType;
}

class RecentlyViewedListPage {
  const RecentlyViewedListPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.hasMore,
  });

  final List<RecentlyViewedEntry> items;
  final int total;
  final int currentPage;
  final bool hasMore;
}
