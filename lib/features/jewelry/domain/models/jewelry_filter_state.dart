import '../../../../core/utils/app_currency.dart';
/// Immutable filter state for the jewelry category listing.
class JewelryFilterState {
  const JewelryFilterState({
    this.searchQuery = '',
    this.category,
    this.subCategories = const {},
    this.selectedAvailability = 'All',
    this.makeAnOffer = false,
    this.withMediaOnly = false,
    this.genders = const {},
    this.priceMin = 0,
    this.priceMax = 500000,
    this.occasions = const {},
    this.metalTypes = const {},
    this.metalColors = const {},
    this.metalPurities = const {},
    this.metalWeightMin = 0,
    this.metalWeightMax = 100,
    this.metalFinishes = const {},
    this.platings = const {},
    this.stoneType,
    this.stoneCategories = const {},
    this.stoneShapes = const {},
    this.stoneWeightMin = 0,
    this.stoneWeightMax = 50,
    this.stoneColors = const {},
    this.stoneClarities = const {},
    this.stoneSettings = const {},
    this.braceletSizes = const {},
    this.braceletLengths = const {},
    this.chainLengths = const {},
    this.necklaceLengths = const {},
    this.ringSizes = const {},
    this.certifications = const {},
    this.conditions = const {},
    this.deliveryTime,
  });

  final String searchQuery;
  final String? category;
  final Set<String> subCategories;
  final String selectedAvailability;
  final bool makeAnOffer;
  final bool withMediaOnly;
  final Set<String> genders;
  final double priceMin;
  final double priceMax;
  final Set<String> occasions;
  final Set<String> metalTypes;
  final Set<String> metalColors;
  final Set<String> metalPurities;
  final double metalWeightMin;
  final double metalWeightMax;
  final Set<String> metalFinishes;
  final Set<String> platings;
  final String? stoneType;
  final Set<String> stoneCategories;
  final Set<String> stoneShapes;
  final double stoneWeightMin;
  final double stoneWeightMax;
  final Set<String> stoneColors;
  final Set<String> stoneClarities;
  final Set<String> stoneSettings;
  final Set<String> braceletSizes;
  final Set<String> braceletLengths;
  final Set<String> chainLengths;
  final Set<String> necklaceLengths;
  final Set<String> ringSizes;
  final Set<String> certifications;
  final Set<String> conditions;
  final String? deliveryTime;

  static const parentCategories = [
    'All Accessories',
    'Bracelets',
    'Chains',
    'Necklaces',
    'Earrings',
    'Rings',
  ];

  static const subCategoriesByParent = {
    'All Accessories': [
      'Maang Tikka',
      'Matha Patti',
      'Passa/Jummar',
      'Borla',
      'Nose Pin',
      'Nath',
      'Septum Ring',
      'Anklet',
    ],
    'Bracelets': [
      'Tennis',
      'Tennis Bracelet',
      'Bangle',
      'Chain Bracelet',
      'Cuff',
    ],
    'Chains': ['General'],
    'Earrings': [
      'Stud',
      'Hoop',
      'Drop Earrings',
      'Chandelier',
    ],
    'Necklaces': [
      'Pendant',
      'Chain',
      'Choker',
      'Statement Necklace',
    ],
    'Rings': [
      'Engagement',
      'Wedding Band',
      'Cocktail Ring',
      'Eternity Ring',
      'Signet Ring',
    ],
  };

  static String parentCategoryOrDefault(String? category) {
    if (category == null || category.isEmpty) return 'All Accessories';
    final mapped = switch (category.trim()) {
      'Ring' => 'Rings',
      'Earring' => 'Earrings',
      'Bracelet' => 'Bracelets',
      'Necklace' => 'Necklaces',
      _ => category.trim(),
    };
    if (parentCategories.contains(mapped)) return mapped;
    return 'All Accessories';
  }

  static String allSubCategoryLabel(String? parent) {
    return switch (parentCategoryOrDefault(parent)) {
      'Bracelets' => 'All Bracelets',
      'Chains' => 'All Chains',
      'Necklaces' => 'All Necklaces',
      'Earrings' => 'All Earrings',
      'Rings' => 'All Rings',
      _ => 'All Accessories',
    };
  }

  static List<String> subCategoriesFor(String? parent) {
    return subCategoriesByParent[parentCategoryOrDefault(parent)] ??
        const [];
  }

  static const availabilityOptions = [
    'All',
    'Available',
    'On Memo',
    'On Hold',
    'Sold',
  ];
  static const genderOptions = ['Women', 'Men', 'Unisex', 'Kids'];
  static const occasionOptions = [
    'Wedding',
    'Engagement',
    'Anniversary',
    'Birthday',
    'Graduation',
    'Holiday',
    "Valentine's Day",
    "Mother's Day",
    'Christmas',
    'New Year',
    'Everyday',
    'Party',
    'Formal Event',
    'Bridal Shower',
  ];
  static const metalTypeOptions = [
    'Platinum',
    'Rose Gold',
    'White Gold',
  ];
  static const metalColorOptions = [
    'Yellow Gold',
    'White Gold',
    'Rose Gold',
    'Green Gold',
    'Black Gold',
    'Two-Tone',
    'Tri-Color',
  ];
  static const metalPurityOptions = [
    '10K',
    '14K',
    '18K',
    '22K',
    '24K',
    '950 Platinum',
    '900 Platinum',
    '925 Silver',
  ];
  static const metalFinishOptions = [
    'Polished',
    'Matte',
    'Brushed',
    'Hammered',
    'Textured',
    'Mirror Finish',
    'High Polish',
    'Satin',
    'Antique',
    'Sandblasted',
  ];
  static const platingOptions = [
    'Gold Plated',
    'Rose Gold Plated',
    'White Gold Plated',
    'Silver Plated',
    'Rhodium',
    'Platinum Plated',
    'Palladium Plated',
    'Unplated',
  ];
  static const stoneTypeOptions = ['Natural', 'Lab-Grown'];
  static const stoneCategoryOptions = [
    'Diamond',
    'Ruby',
    'Emerald',
    'Sapphire',
    'Pearl',
    'Crystal',
    'Cubic Zirconia',
    'Moissanite',
    'None',
  ];
  static const stoneShapeOptions = [
    'Round',
    'Oval',
    'Princess',
    'Pear',
    'Heart',
    'Emerald',
    'Asscher',
    'Radiant',
    'Marquise',
    'Cushion',
  ];
  static const stoneColorOptions = [
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'Fancy Yellow',
    'Fancy Pink',
    'Fancy Blue',
  ];
  static const stoneClarityOptions = [
    'FL',
    'IF',
    'VVS1',
    'VVS2',
    'VS1',
    'VS2',
    'SI1',
    'SI2',
  ];
  static const stoneSettingOptions = [
    'Prong',
    'Bezel',
    'Channel',
    'Pave',
    'Halo',
    'Tension',
  ];
  static const braceletSizeOptions = [
    'Extra Small',
    'Small',
    'Medium',
    'Large',
    'Extra Large',
  ];
  static const braceletLengthOptions = [
    '6"',
    '6.5"',
    '7"',
    '7.5"',
    '8"',
    '8.5"',
  ];
  static const chainLengthOptions = [
    '16"',
    '18"',
    '20"',
    '22"',
    '24"',
    '30"',
  ];
  static const necklaceLengthOptions = [
    '14"',
    '16"',
    '18"',
    '20"',
    '22"',
    '24"',
    '30"',
  ];
  static const ringSizeOptions = [
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
  ];
  static const certificationOptions = [
    'GIA',
    'IGI',
    'HRD',
    'AGS',
    'GCAL',
    'SSEF',
    'Gubelin',
    'GRS',
    'AIG',
  ];
  static const conditionOptions = [
    'New',
    'Pre-owned',
    'Vintage',
    'Refurbished',
    'Antique',
  ];
  static const deliveryTimeOptions = [
    'Same Day',
    'Next Day',
    '2–3 Days',
    'Within Week',
    'Within Month',
  ];

  static const priceMinLimit = 0.0;
  static const priceMaxLimit = 500000.0;
  static const metalWeightMinLimit = 0.0;
  static const metalWeightMaxLimit = 100.0;
  static const stoneWeightMinLimit = 0.0;
  static const stoneWeightMaxLimit = 50.0;

  int get activeCount {
    var count = 0;
    void bump(Set s) {
      if (s.isNotEmpty) count++;
    }

    if (selectedAvailability != 'All') count++;
    if (makeAnOffer) count++;
    if (withMediaOnly) count++;
    bump(genders);
    if (priceMin > priceMinLimit || priceMax < priceMaxLimit) count++;
    bump(occasions);
    bump(metalTypes);
    bump(metalColors);
    bump(metalPurities);
    if (metalWeightMin > metalWeightMinLimit ||
        metalWeightMax < metalWeightMaxLimit) {
      count++;
    }
    bump(metalFinishes);
    bump(platings);
    if (stoneType != null) count++;
    bump(stoneCategories);
    bump(stoneShapes);
    if (stoneWeightMin > stoneWeightMinLimit ||
        stoneWeightMax < stoneWeightMaxLimit) {
      count++;
    }
    bump(stoneColors);
    bump(stoneClarities);
    bump(stoneSettings);
    bump(braceletSizes);
    bump(braceletLengths);
    bump(chainLengths);
    bump(necklaceLengths);
    bump(ringSizes);
    bump(certifications);
    bump(conditions);
    if (deliveryTime != null) count++;
    return count;
  }

  List<String> get summaryLabels {
    final labels = <String>[];
    labels.addAll(metalPurities);
    labels.addAll(metalColors);
    labels.addAll(stoneCategories);
    labels.addAll(occasions.take(2));
    if (priceMin > priceMinLimit || priceMax < priceMaxLimit) {
      labels.add('${AppCurrency.format(_fmt(priceMin))}–${AppCurrency.format(_fmt(priceMax))}');
    }
    if (stoneType != null) labels.add(stoneType!);
    if (selectedAvailability != 'All') labels.add(selectedAvailability);
    labels.addAll(genders);
    return labels;
  }

  static String _fmt(double v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k';
    }
    return v.toStringAsFixed(0);
  }

  JewelryFilterState copyWith({
    String? searchQuery,
    String? category,
    bool clearCategory = false,
    Set<String>? subCategories,
    bool clearSubCategories = false,
    String? selectedAvailability,
    bool? makeAnOffer,
    bool? withMediaOnly,
    Set<String>? genders,
    double? priceMin,
    double? priceMax,
    Set<String>? occasions,
    Set<String>? metalTypes,
    Set<String>? metalColors,
    Set<String>? metalPurities,
    double? metalWeightMin,
    double? metalWeightMax,
    Set<String>? metalFinishes,
    Set<String>? platings,
    String? stoneType,
    bool clearStoneType = false,
    Set<String>? stoneCategories,
    Set<String>? stoneShapes,
    double? stoneWeightMin,
    double? stoneWeightMax,
    Set<String>? stoneColors,
    Set<String>? stoneClarities,
    Set<String>? stoneSettings,
    Set<String>? braceletSizes,
    Set<String>? braceletLengths,
    Set<String>? chainLengths,
    Set<String>? necklaceLengths,
    Set<String>? ringSizes,
    Set<String>? certifications,
    Set<String>? conditions,
    String? deliveryTime,
    bool clearDeliveryTime = false,
  }) {
    return JewelryFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      category: clearCategory ? null : (category ?? this.category),
      subCategories: clearSubCategories
          ? const {}
          : (subCategories ?? this.subCategories),
      selectedAvailability: selectedAvailability ?? this.selectedAvailability,
      makeAnOffer: makeAnOffer ?? this.makeAnOffer,
      withMediaOnly: withMediaOnly ?? this.withMediaOnly,
      genders: genders ?? this.genders,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      occasions: occasions ?? this.occasions,
      metalTypes: metalTypes ?? this.metalTypes,
      metalColors: metalColors ?? this.metalColors,
      metalPurities: metalPurities ?? this.metalPurities,
      metalWeightMin: metalWeightMin ?? this.metalWeightMin,
      metalWeightMax: metalWeightMax ?? this.metalWeightMax,
      metalFinishes: metalFinishes ?? this.metalFinishes,
      platings: platings ?? this.platings,
      stoneType: clearStoneType ? null : (stoneType ?? this.stoneType),
      stoneCategories: stoneCategories ?? this.stoneCategories,
      stoneShapes: stoneShapes ?? this.stoneShapes,
      stoneWeightMin: stoneWeightMin ?? this.stoneWeightMin,
      stoneWeightMax: stoneWeightMax ?? this.stoneWeightMax,
      stoneColors: stoneColors ?? this.stoneColors,
      stoneClarities: stoneClarities ?? this.stoneClarities,
      stoneSettings: stoneSettings ?? this.stoneSettings,
      braceletSizes: braceletSizes ?? this.braceletSizes,
      braceletLengths: braceletLengths ?? this.braceletLengths,
      chainLengths: chainLengths ?? this.chainLengths,
      necklaceLengths: necklaceLengths ?? this.necklaceLengths,
      ringSizes: ringSizes ?? this.ringSizes,
      certifications: certifications ?? this.certifications,
      conditions: conditions ?? this.conditions,
      deliveryTime:
          clearDeliveryTime ? null : (deliveryTime ?? this.deliveryTime),
    );
  }
}

enum JewelrySortOption {
  featured,
  newest,
}

extension JewelrySortOptionLabel on JewelrySortOption {
  String get label => switch (this) {
        JewelrySortOption.featured => 'Featured',
        JewelrySortOption.newest => 'Newest',
      };
}

enum JewelryViewMode { list, grid }
