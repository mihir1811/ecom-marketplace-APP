class RecentlyViewedEntry {
  const RecentlyViewedEntry({
    required this.id,
    required this.productId,
    required this.productType,
    required this.viewedAtLabel,
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
  });

  final String id;
  final String productId;
  final String productType;
  final String viewedAtLabel;
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

  String get displayTitle {
    if (productTitle != null && productTitle!.isNotEmpty) {
      return productTitle!;
    }
    if (carat != null) {
      final parts = <String>['${carat!.toStringAsFixed(2)}ct'];
      if (shape != null && shape!.isNotEmpty) parts.add(shape!);
      return parts.join(' ');
    }
    return productId;
  }

  String? get detailLine {
    final parts = <String>[];
    if (color != null && color!.isNotEmpty) parts.add(color!);
    if (clarity != null && clarity!.isNotEmpty) parts.add(clarity!);
    if (cut != null && cut!.isNotEmpty) parts.add(cut!);
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  String? get metaLine {
    final parts = <String>[];
    if (stockNumber != null && stockNumber!.isNotEmpty) {
      parts.add('Stock $stockNumber');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}

class RecentlyViewedId {
  const RecentlyViewedId({
    required this.productId,
    required this.productType,
  });

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
