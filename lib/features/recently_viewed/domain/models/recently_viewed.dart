class RecentlyViewedEntry {
  const RecentlyViewedEntry({
    required this.id,
    required this.productId,
    required this.productType,
    required this.viewedAtLabel,
    this.stockNumber,
    this.productTitle,
  });

  final String id;
  final String productId;
  final String productType;
  final String viewedAtLabel;
  final String? stockNumber;
  final String? productTitle;
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
