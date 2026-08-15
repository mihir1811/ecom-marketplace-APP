import 'diamond_project_item.dart';

/// Saved business diamond project (selection + filter snapshot).
class DiamondProject {
  const DiamondProject({
    required this.id,
    required this.name,
    this.userId,
    this.sellerId,
    this.diamondType,
    this.filters = const {},
    this.analytics = const {},
    this.itemCount = 0,
    this.totalCarat = 0,
    this.totalPrice = 0,
    this.avgPrice = 0,
    this.avgPpc = 0,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
    this.ownerName,
    this.companyName,
  });

  final String id;
  final String name;
  final String? userId;
  final String? sellerId;
  final String? diamondType;
  final Map<String, dynamic> filters;
  final Map<String, dynamic> analytics;
  final int itemCount;
  final double totalCarat;
  final double totalPrice;
  final double avgPrice;
  final double avgPpc;
  final List<DiamondProjectItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? ownerName;
  final String? companyName;

  DiamondProject copyWith({
    String? name,
    List<DiamondProjectItem>? items,
    Map<String, dynamic>? analytics,
    int? itemCount,
  }) {
    return DiamondProject(
      id: id,
      name: name ?? this.name,
      userId: userId,
      sellerId: sellerId,
      diamondType: diamondType,
      filters: filters,
      analytics: analytics ?? this.analytics,
      itemCount: itemCount ?? this.itemCount,
      totalCarat: totalCarat,
      totalPrice: totalPrice,
      avgPrice: avgPrice,
      avgPpc: avgPpc,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: updatedAt,
      ownerName: ownerName,
      companyName: companyName,
    );
  }
}

/// Paginated seller project list.
class DiamondProjectPage {
  const DiamondProjectPage({
    required this.projects,
    required this.page,
    required this.hasMore,
    required this.totalCount,
  });

  final List<DiamondProject> projects;
  final int page;
  final bool hasMore;
  final int totalCount;
}
