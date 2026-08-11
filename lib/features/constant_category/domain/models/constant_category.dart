class ConstantCategoryEntry {
  const ConstantCategoryEntry({
    required this.id,
    required this.category,
    required this.values,
    this.createdAtLabel,
    this.updatedAtLabel,
  });

  final String id;
  final String category;
  final List<Map<String, dynamic>> values;
  final String? createdAtLabel;
  final String? updatedAtLabel;
}

class ConstantCategoryListPage {
  const ConstantCategoryListPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.hasMore,
  });

  final List<ConstantCategoryEntry> items;
  final int total;
  final int currentPage;
  final bool hasMore;
}

class ConstantCategoryUpdateInput {
  const ConstantCategoryUpdateInput({
    required this.category,
    required this.values,
  });

  final String category;
  final List<Map<String, dynamic>> values;

  Map<String, dynamic> toJson() => {
        'category': category.trim(),
        'value': values,
      };
}
