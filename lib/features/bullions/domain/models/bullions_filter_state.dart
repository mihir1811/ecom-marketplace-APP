import 'billion.dart';

/// Top-level bullion category filter used by the screen and providers.
enum BullionsMetalFilter {
  all,
  gold,
  silver,
  platinum,
  palladium,
  copper;

  String get label => switch (this) {
        all => 'All',
        gold => 'Gold',
        silver => 'Silver',
        platinum => 'Platinum',
        palladium => 'Palladium',
        copper => 'Copper',
      };

  BullionMetal? get metal => switch (this) {
        all => null,
        gold => BullionMetal.gold,
        silver => BullionMetal.silver,
        platinum => BullionMetal.platinum,
        palladium => BullionMetal.palladium,
        copper => BullionMetal.copper,
      };
}

enum BullionsViewMode { grid, list }

/// Immutable filter state for Bullions listings.
class BullionsFilterState {
  const BullionsFilterState({
    this.metalFilter = BullionsMetalFilter.all,
    this.selectedVariant,
    this.searchQuery = '',
    this.shapes = const {},
    this.weightChips = const {},
    this.conditions = const {},
    this.certifications = const {},
    this.mintMarks = const {},
    this.priceMin = 0,
    this.priceMax = 0,
    this.weightMin = 0,
    this.weightMax = 0,
    this.quantityMin = 0,
    this.quantityMax = 0,
    this.lengthMin = 0,
    this.lengthMax = 0,
    this.widthMin = 0,
    this.widthMax = 0,
    this.heightMin = 0,
    this.heightMax = 0,
  });

  final BullionsMetalFilter metalFilter;
  final String? selectedVariant;
  final String searchQuery;
  final Set<String> shapes;
  final Set<String> weightChips;
  final Set<String> conditions;
  final Set<String> certifications;
  final Set<String> mintMarks;
  final double priceMin;
  final double priceMax;
  final double weightMin;
  final double weightMax;
  final double quantityMin;
  final double quantityMax;
  final double lengthMin;
  final double lengthMax;
  final double widthMin;
  final double widthMax;
  final double heightMin;
  final double heightMax;

  static const shapeOptions = ['Bar', 'Biscuit', 'Coin', 'Round'];
  static const weightChipOptions = ['1g', '5g', '10g', '1oz'];
  static const conditionOptions = [
    'New',
    'BU',
    'Circulated',
  ];
  static const certificationOptions = [
    'LBMA Good Delivery',
    'Assay card',
    'Royal Canadian Mint',
    'PAMP Certificate',
  ];
  static const mintMarkOptions = [
    'LBMA',
    'PAMP',
    'RCM',
    'US Mint',
  ];

  /// Hint text for empty range inputs in the filter drawer.
  static const rangePlaceholders = <String, String>{
    'priceMin': '0',
    'priceMax': '500000',
    'weightMin': '0',
    'weightMax': '1000',
    'quantityMin': '1',
    'quantityMax': '999',
    'lengthMin': '0',
    'lengthMax': '500',
    'widthMin': '0',
    'widthMax': '500',
    'heightMin': '0',
    'heightMax': '500',
  };

  static const metalVariants = {
    BullionsMetalFilter.gold: ['24K', '22K', '18K'],
    BullionsMetalFilter.silver: ['999', '925', 'Sterling'],
    BullionsMetalFilter.platinum: ['999.5', '950'],
    BullionsMetalFilter.palladium: ['999.5', '950'],
    BullionsMetalFilter.copper: ['999', 'ETP', 'OFHC'],
  };

  List<String> get availableVariants => metalVariants[metalFilter] ?? const [];

  int get activeCount {
    var count = 0;
    void bumpSet(Set<String> value) {
      if (value.isNotEmpty) count++;
    }

    bumpSet(shapes);
    bumpSet(weightChips);
    bumpSet(conditions);
    bumpSet(certifications);
    bumpSet(mintMarks);
    if (priceMin > 0 || priceMax > 0) count++;
    if (weightMin > 0 || weightMax > 0) count++;
    if (quantityMin > 0 || quantityMax > 0) count++;
    if (lengthMin > 0 || lengthMax > 0) count++;
    if (widthMin > 0 || widthMax > 0) count++;
    if (heightMin > 0 || heightMax > 0) count++;
    return count;
  }

  BullionsFilterState copyWith({
    BullionsMetalFilter? metalFilter,
    String? selectedVariant,
    bool clearVariant = false,
    String? searchQuery,
    Set<String>? shapes,
    Set<String>? weightChips,
    Set<String>? conditions,
    Set<String>? certifications,
    Set<String>? mintMarks,
    double? priceMin,
    double? priceMax,
    double? weightMin,
    double? weightMax,
    double? quantityMin,
    double? quantityMax,
    double? lengthMin,
    double? lengthMax,
    double? widthMin,
    double? widthMax,
    double? heightMin,
    double? heightMax,
  }) {
    return BullionsFilterState(
      metalFilter: metalFilter ?? this.metalFilter,
      selectedVariant: clearVariant
          ? null
          : (selectedVariant ?? this.selectedVariant),
      searchQuery: searchQuery ?? this.searchQuery,
      shapes: shapes ?? this.shapes,
      weightChips: weightChips ?? this.weightChips,
      conditions: conditions ?? this.conditions,
      certifications: certifications ?? this.certifications,
      mintMarks: mintMarks ?? this.mintMarks,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      weightMin: weightMin ?? this.weightMin,
      weightMax: weightMax ?? this.weightMax,
      quantityMin: quantityMin ?? this.quantityMin,
      quantityMax: quantityMax ?? this.quantityMax,
      lengthMin: lengthMin ?? this.lengthMin,
      lengthMax: lengthMax ?? this.lengthMax,
      widthMin: widthMin ?? this.widthMin,
      widthMax: widthMax ?? this.widthMax,
      heightMin: heightMin ?? this.heightMin,
      heightMax: heightMax ?? this.heightMax,
    );
  }
}

