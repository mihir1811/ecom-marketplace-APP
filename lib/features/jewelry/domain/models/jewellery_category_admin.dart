class JewelleryCategoryAdmin {
  const JewelleryCategoryAdmin({
    required this.id,
    required this.name,
    required this.isActive,
    this.imageUrl,
    this.productCount,
    this.subcategories = const [],
  });

  final String id;
  final String name;
  final bool isActive;
  final String? imageUrl;
  /// Backend product/style count when the API provides it (`productCount` / `_count`).
  final int? productCount;
  final List<JewellerySubcategoryAdmin> subcategories;

  /// Styles shown on shopper category tiles — prefers API count, else active subs.
  int get styleCount {
    if (productCount != null) return productCount!;
    return subcategories.where((s) => s.isActive).length;
  }
}

class JewellerySubcategoryAdmin {
  const JewellerySubcategoryAdmin({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.isActive,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String categoryId;
  final bool isActive;
  final String? imageUrl;
}

/// Paginated `GET /jewellery-categories` payload for admin and shopper UIs.
class JewelleryCategoryListPage {
  const JewelleryCategoryListPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.hasMore,
  });

  final List<JewelleryCategoryAdmin> items;
  final int total;
  final int currentPage;
  final bool hasMore;
}

/// Maps shopper UI labels (`Rings`) to live API names (`Ring`).
abstract final class JewelleryCategoryMatch {
  static String? apiNameForUi(String? ui) {
    final value = ui?.trim() ?? '';
    if (value.isEmpty || value == 'All Accessories') return null;
    return switch (value) {
      'Rings' || 'Ring' => 'Ring',
      'Earrings' || 'Earring' => 'Earring',
      'Bracelets' || 'Bracelet' => 'Bracelet',
      'Necklaces' || 'Necklace' || 'Chains' || 'Chain' => 'Necklace',
      'Accessories' => 'Accessories',
      _ => value,
    };
  }

  static JewelleryCategoryAdmin? find(
    List<JewelleryCategoryAdmin> items,
    String? uiName,
  ) {
    final apiName = apiNameForUi(uiName);
    if (apiName == null) return null;
    for (final item in items) {
      if (item.name.toLowerCase() == apiName.toLowerCase()) return item;
    }
    return null;
  }
}

class JewelleryCategoryInput {
  const JewelleryCategoryInput({
    required this.name,
    this.isActive = true,
    this.subcategories = const [],
  });

  final String name;
  final bool isActive;
  final List<Map<String, dynamic>> subcategories;

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'isActive': isActive,
        if (subcategories.isNotEmpty) 'subcategories': subcategories,
      };
}
