class JewelleryCategoryAdmin {
  const JewelleryCategoryAdmin({
    required this.id,
    required this.name,
    required this.isActive,
    this.imageUrl,
    this.subcategories = const [],
  });

  final String id;
  final String name;
  final bool isActive;
  final String? imageUrl;
  final List<JewellerySubcategoryAdmin> subcategories;
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
      'Necklaces' || 'Necklace' || 'Chains' => 'Necklace',
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
