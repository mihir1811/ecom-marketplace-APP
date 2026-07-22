/// Seller inventory product row (natural / melee diamonds).
class SellerProduct {
  const SellerProduct({
    required this.id,
    required this.sellerId,
    required this.stockNumber,
    required this.isNatural,
    required this.isExpired,
    required this.isDeleted,
    required this.isOnAuction,
    required this.isSold,
    required this.fields,
  });

  final String id;
  final String sellerId;
  final String stockNumber;
  final bool isNatural;
  final bool isExpired;
  final bool isDeleted;
  final bool isOnAuction;
  final bool isSold;

  /// Display values keyed by [SellerProductColumnDef.id] (excludes `selection`).
  final Map<String, String?> fields;

  String? field(String columnId) => fields[columnId];

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (stockNumber.toLowerCase().contains(q)) return true;
    for (final value in fields.values) {
      if (value != null && value.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  SellerProduct copyWith({
    String? id,
    String? sellerId,
    String? stockNumber,
    bool? isNatural,
    bool? isExpired,
    bool? isDeleted,
    bool? isOnAuction,
    bool? isSold,
    Map<String, String?>? fields,
  }) {
    return SellerProduct(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      stockNumber: stockNumber ?? this.stockNumber,
      isNatural: isNatural ?? this.isNatural,
      isExpired: isExpired ?? this.isExpired,
      isDeleted: isDeleted ?? this.isDeleted,
      isOnAuction: isOnAuction ?? this.isOnAuction,
      isSold: isSold ?? this.isSold,
      fields: fields ?? this.fields,
    );
  }
}

enum SellerProductStatusFilter { active, expired, all }

enum SellerProductDiamondTab { natural, melee }

enum SellerProductsViewMode { grid, cards }
