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
