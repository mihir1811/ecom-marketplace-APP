/// Defines a single sorting criterion with field, direction, and priority.
class SortingCriteria {
  final String fieldKey;
  final String displayName;
  final SortDirection direction;
  final int priority;

  const SortingCriteria({
    required this.fieldKey,
    required this.displayName,
    this.direction = SortDirection.ascending,
    required this.priority,
  });

  SortingCriteria copyWith({
    String? fieldKey,
    String? displayName,
    SortDirection? direction,
    int? priority,
  }) {
    return SortingCriteria(
      fieldKey: fieldKey ?? this.fieldKey,
      displayName: displayName ?? this.displayName,
      direction: direction ?? this.direction,
      priority: priority ?? this.priority,
    );
  }

  /// Converts to the JSON-like structure expected by the repository.
  Map<String, dynamic> toMap() {
    return {
      'field': fieldKey,
      'direction': direction == SortDirection.ascending ? 'asc' : 'desc',
      'priority': priority,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortingCriteria &&
          runtimeType == other.runtimeType &&
          fieldKey == other.fieldKey;

  @override
  int get hashCode => fieldKey.hashCode;
}

enum SortDirection { ascending, descending }

/// All available sorting fields for diamonds.
class DiamondSortingFields {
  const DiamondSortingFields._();

  static const all = <SortingFieldDef>[
    SortingFieldDef('price', 'Total Price'),
    SortingFieldDef('pricePerCarat', 'Price Per Carat'),
    SortingFieldDef('carat', 'Carat Weight'),
  ];

  static SortingFieldDef? findByKey(String key) {
    try {
      return all.firstWhere((f) => f.key == key);
    } catch (_) {
      return null;
    }
  }
}

class SortingFieldDef {
  final String key;
  final String displayName;
  const SortingFieldDef(this.key, this.displayName);
}
