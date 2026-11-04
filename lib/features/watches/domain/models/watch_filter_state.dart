/// Immutable filter state for the watches catalog (schema-aligned drawer).
class WatchFilterState {
  const WatchFilterState({
    this.searchQuery = '',
    this.brands = const {},
    this.models = const {},
    this.categories = const {},
    this.priceMin = 0,
    this.priceMax = 0,
    this.movements = const {},
    this.genders = const {},
    this.conditions = const {},
    this.selectedAvailability = 'All',
    this.makeAnOffer = false,
    this.withMedia = const {},
    this.caseMaterials = const {},
    this.dialColors = const {},
    this.caseSizeRanges = const {},
    this.caseShapes = const {},
    this.caseBacks = const {},
    this.strapMaterials = const {},
    this.crownTypes = const {},
    this.strapColors = const {},
    this.claspTypes = const {},
    this.claspMaterials = const {},
    this.glassMaterials = const {},
    this.lugWidths = const {},
    this.powerReserves = const {},
    this.waterResistances = const {},
    this.modelYears = const {},
    this.certifications = const {},
    this.bezelTypes = const {},
    this.bezelMaterials = const {},
    this.configurations = const {},
    this.materials = const {},
    this.preciousStoneTypes = const {},
    this.indexes = const {},
    this.boxIncluded = false,
    this.papersIncluded = false,
    this.warrantyCardIncluded = false,
    this.fullSetIncluded = false,
  });

  final String searchQuery;
  final Set<String> brands;
  final Set<String> models;
  final Set<String> categories;
  final double priceMin;
  final double priceMax;
  final Set<String> movements;
  final Set<String> genders;
  final Set<String> conditions;
  final String selectedAvailability;
  final bool makeAnOffer;
  final Set<String> withMedia;
  final Set<String> caseMaterials;
  final Set<String> dialColors;
  final Set<String> caseSizeRanges;
  final Set<String> caseShapes;
  final Set<String> caseBacks;
  final Set<String> strapMaterials;
  final Set<String> crownTypes;
  final Set<String> strapColors;
  final Set<String> claspTypes;
  final Set<String> claspMaterials;
  final Set<String> glassMaterials;
  final Set<String> lugWidths;
  final Set<String> powerReserves;
  final Set<String> waterResistances;
  final Set<String> modelYears;
  final Set<String> certifications;
  final Set<String> bezelTypes;
  final Set<String> bezelMaterials;
  final Set<String> configurations;
  final Set<String> materials;
  final Set<String> preciousStoneTypes;
  final Set<String> indexes;
  final bool boxIncluded;
  final bool papersIncluded;
  final bool warrantyCardIncluded;
  final bool fullSetIncluded;

  /// Popular brands shown first in Brand & Model.
  static const popularBrandOptions = [
    'Rolex',
    'Patek Philippe',
    'Audemars Piguet',
    'Richard Mille',
    'Vacheron Constantin',
    'Omega',
    'Cartier',
    'TAG Heuer',
    'Breitling',
    'Hublot',
    'Grand Seiko',
    'IWC',
    'Panerai',
    'Tissot',
  ];

  /// Style options (also used by category chips on the listing screen).
  static const categoryOptions = [
    'Luxury',
    'Vintage',
    'Dress',
    'Diver',
    'Sport',
    'GMT',
    'Chronograph',
  ];

  static const styleOptions = categoryOptions;

  static const movementOptions = [
    'Automatic (Self-winding)',
    'Manual (Hand-winding)',
    'Quartz (Battery)',
    'Solar Powered',
    'Kinetic',
    'Spring Drive',
  ];

  static const genderOptions = ['Men', 'Women', 'Unisex', 'Kids'];

  static const conditionOptions = [
    'New / Unworn',
    'Mint',
    'Like New',
    'Pre-Owned',
    'Fair',
    'Vintage',
  ];

  static const availabilityOptions = [
    'All',
    'Available',
    'On Memo',
    'On Hold',
    'Sold',
  ];

  static const withMediaOptions = ['With Images', 'With Video'];

  static const caseMaterialOptions = [
    'Stainless Steel',
    'Titanium',
    'Yellow Gold',
    'Rose Gold',
    'White Gold',
    'Platinum',
    'Ceramic',
    'Carbon Fiber',
    'Bronze',
    'Two-Tone Steel & Gold',
  ];

  static const dialColorOptions = [
    'Black',
    'Blue',
    'White',
    'Silver',
    'Grey',
    'Green',
    'Champagne',
    'Brown',
    'Gold',
    'Rose Gold',
    'Mother of Pearl',
    'Skeleton',
  ];

  static const caseSizeRangeOptions = [
    '10-25 mm',
    '26-30 mm',
    '31-35 mm',
    '36-40 mm',
    '41-45 mm',
    '>46 mm',
  ];

  static const caseShapeOptions = [
    'Round',
    'Square',
    'Rectangular',
    'Tonneau',
    'Cushion',
    'Oval',
    'Octagon',
    'Asymmetrical',
    'Drop',
    'Dodecagon',
    'Barrel',
  ];

  static const caseBackOptions = [
    'Solid',
    'Exhibition / Transparent Sapphire',
    'Screw-Down',
  ];

  static const strapMaterialOptions = [
    'Stainless Steel',
    'Leather',
    'Rubber',
    'Ceramic',
    'Nylon',
    'Nato Fabric',
    'Silicone',
    'Satin',
    'Fabric',
    'Denim',
  ];

  static const crownTypeOptions = [
    'Screw-Down Crown',
    'Push-Pull Crown',
    'Cabochon Crown',
    'Onion Crown',
    'Fluted Crown',
  ];

  static const strapColorOptions = [
    'Black',
    'Brown',
    'Blue',
    'Anthracite',
    'Silver',
    'Gold',
    'Rose Gold',
    'Green',
    'Red',
    'White',
    'Bicolour',
  ];

  static const claspTypeOptions = [
    'Folding Clasp',
    'Deployant / Deployment Clasp',
    'Pin / Tang Buckle',
    'Butterfly Clasp',
    'Hidden Clasp',
    'Jewelry Clasp',
  ];

  static const claspMaterialOptions = [
    'Stainless Steel',
    'Titanium',
    'Yellow Gold',
    'Rose Gold',
    'White Gold',
    'Platinum',
    'Ceramic',
    'Carbon Fiber',
  ];

  static const glassMaterialOptions = [
    'Sapphire Crystal',
    'Mineral Crystal',
    'Hesalite / Acrylic Glass',
    'Plexiglass',
  ];

  static const lugWidthOptions = [
    'Under 18 mm',
    '18–20 mm',
    '21–22 mm',
    '23–24 mm',
    'Over 24 mm',
  ];

  static const powerReserveOptions = [
    'No Power Reserve / Quartz',
    'Up to 40 Hours',
    '41–50 Hours',
    '51–60 Hours',
    '61–72 Hours',
    '73–100 Hours',
    '101–150 Hours',
    '151–200 Hours',
    '200+ Hours',
  ];

  static const waterResistanceOptions = [
    '30m',
    '50m',
    '60m',
    '100m',
    '120m',
    '150m',
    '200m',
    '300m',
    '500m',
    '600m',
    '1000m',
  ];

  static const modelYearOptions = [
    '2026',
    '2025',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
    '2018',
    '2017',
    '2016',
    '2015',
    'Pre-2015',
  ];

  static const certificationOptions = [
    'COSC Chronometer',
    'Master Chronometer (METAS)',
    'Geneva Seal (Poinçon de Genève)',
    'Superlative Chronometer',
  ];

  static const bezelTypeOptions = [
    'Fixed',
    'Unidirectional Rotating',
    'Bidirectional Rotating',
    'Countdown',
    'Dive',
    'GMT',
    'Tachymeter',
    'Fluted',
    'Smooth',
    'Gem-Set',
  ];

  static const bezelMaterialOptions = [
    'Stainless Steel',
    'Titanium',
    'Ceramic',
    'Cerachrom',
    'Yellow Gold',
    'Rose Gold',
    'White Gold',
    'Platinum',
    'Sapphire Crystal',
  ];

  static const configurationOptions = [
    'Date',
    'Day-Date',
    'Chronograph',
    'GMT / Dual Time',
    'Moonphase',
    'Tourbillon',
    'Perpetual Calendar',
    'Power Reserve Indicator',
    'Annual Calendar',
    'Alarm',
  ];

  static const materialOptions = [
    'Luminous Hands / Markers',
    'Helium Escape Valve',
    'Anti-Magnetic',
    'Chronometer Certified',
  ];

  static const preciousStoneTypeOptions = [
    'Diamond',
    'Sapphire',
    'Ruby',
    'Emerald',
  ];

  static const indexesOptions = [
    'Arabic numerals',
    'Gemstones / Dots',
    'Lines / Baton',
    'No markers',
    'Roman numerals',
  ];

  bool get hasActiveFilters =>
      brands.isNotEmpty ||
      models.isNotEmpty ||
      categories.isNotEmpty ||
      priceMin > 0 ||
      priceMax > 0 ||
      movements.isNotEmpty ||
      genders.isNotEmpty ||
      conditions.isNotEmpty ||
      selectedAvailability != 'All' ||
      makeAnOffer ||
      withMedia.isNotEmpty ||
      caseMaterials.isNotEmpty ||
      dialColors.isNotEmpty ||
      caseSizeRanges.isNotEmpty ||
      caseShapes.isNotEmpty ||
      caseBacks.isNotEmpty ||
      strapMaterials.isNotEmpty ||
      crownTypes.isNotEmpty ||
      strapColors.isNotEmpty ||
      claspTypes.isNotEmpty ||
      claspMaterials.isNotEmpty ||
      glassMaterials.isNotEmpty ||
      lugWidths.isNotEmpty ||
      powerReserves.isNotEmpty ||
      waterResistances.isNotEmpty ||
      modelYears.isNotEmpty ||
      certifications.isNotEmpty ||
      bezelTypes.isNotEmpty ||
      bezelMaterials.isNotEmpty ||
      configurations.isNotEmpty ||
      materials.isNotEmpty ||
      preciousStoneTypes.isNotEmpty ||
      indexes.isNotEmpty ||
      boxIncluded ||
      papersIncluded ||
      warrantyCardIncluded ||
      fullSetIncluded ||
      searchQuery.trim().isNotEmpty;

  int get activeCount {
    var count = 0;
    void bump(Set s) {
      if (s.isNotEmpty) count++;
    }

    bump(brands);
    bump(models);
    bump(categories);
    if (priceMin > 0 || priceMax > 0) count++;
    bump(movements);
    bump(genders);
    bump(conditions);
    if (selectedAvailability != 'All') count++;
    if (makeAnOffer) count++;
    bump(withMedia);
    bump(caseMaterials);
    bump(dialColors);
    bump(caseSizeRanges);
    bump(caseShapes);
    bump(caseBacks);
    bump(strapMaterials);
    bump(crownTypes);
    bump(strapColors);
    bump(claspTypes);
    bump(claspMaterials);
    bump(glassMaterials);
    bump(lugWidths);
    bump(powerReserves);
    bump(waterResistances);
    bump(modelYears);
    bump(certifications);
    bump(bezelTypes);
    bump(bezelMaterials);
    bump(configurations);
    bump(materials);
    bump(preciousStoneTypes);
    bump(indexes);
    if (boxIncluded) count++;
    if (papersIncluded) count++;
    if (warrantyCardIncluded) count++;
    if (fullSetIncluded) count++;
    return count;
  }

  WatchFilterState copyWith({
    String? searchQuery,
    Set<String>? brands,
    Set<String>? models,
    Set<String>? categories,
    double? priceMin,
    double? priceMax,
    Set<String>? movements,
    Set<String>? genders,
    Set<String>? conditions,
    String? selectedAvailability,
    bool? makeAnOffer,
    Set<String>? withMedia,
    Set<String>? caseMaterials,
    Set<String>? dialColors,
    Set<String>? caseSizeRanges,
    Set<String>? caseShapes,
    Set<String>? caseBacks,
    Set<String>? strapMaterials,
    Set<String>? crownTypes,
    Set<String>? strapColors,
    Set<String>? claspTypes,
    Set<String>? claspMaterials,
    Set<String>? glassMaterials,
    Set<String>? lugWidths,
    Set<String>? powerReserves,
    Set<String>? waterResistances,
    Set<String>? modelYears,
    Set<String>? certifications,
    Set<String>? bezelTypes,
    Set<String>? bezelMaterials,
    Set<String>? configurations,
    Set<String>? materials,
    Set<String>? preciousStoneTypes,
    Set<String>? indexes,
    bool? boxIncluded,
    bool? papersIncluded,
    bool? warrantyCardIncluded,
    bool? fullSetIncluded,
  }) {
    return WatchFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      brands: brands ?? this.brands,
      models: models ?? this.models,
      categories: categories ?? this.categories,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      movements: movements ?? this.movements,
      genders: genders ?? this.genders,
      conditions: conditions ?? this.conditions,
      selectedAvailability: selectedAvailability ?? this.selectedAvailability,
      makeAnOffer: makeAnOffer ?? this.makeAnOffer,
      withMedia: withMedia ?? this.withMedia,
      caseMaterials: caseMaterials ?? this.caseMaterials,
      dialColors: dialColors ?? this.dialColors,
      caseSizeRanges: caseSizeRanges ?? this.caseSizeRanges,
      caseShapes: caseShapes ?? this.caseShapes,
      caseBacks: caseBacks ?? this.caseBacks,
      strapMaterials: strapMaterials ?? this.strapMaterials,
      crownTypes: crownTypes ?? this.crownTypes,
      strapColors: strapColors ?? this.strapColors,
      claspTypes: claspTypes ?? this.claspTypes,
      claspMaterials: claspMaterials ?? this.claspMaterials,
      glassMaterials: glassMaterials ?? this.glassMaterials,
      lugWidths: lugWidths ?? this.lugWidths,
      powerReserves: powerReserves ?? this.powerReserves,
      waterResistances: waterResistances ?? this.waterResistances,
      modelYears: modelYears ?? this.modelYears,
      certifications: certifications ?? this.certifications,
      bezelTypes: bezelTypes ?? this.bezelTypes,
      bezelMaterials: bezelMaterials ?? this.bezelMaterials,
      configurations: configurations ?? this.configurations,
      materials: materials ?? this.materials,
      preciousStoneTypes: preciousStoneTypes ?? this.preciousStoneTypes,
      indexes: indexes ?? this.indexes,
      boxIncluded: boxIncluded ?? this.boxIncluded,
      papersIncluded: papersIncluded ?? this.papersIncluded,
      warrantyCardIncluded: warrantyCardIncluded ?? this.warrantyCardIncluded,
      fullSetIncluded: fullSetIncluded ?? this.fullSetIncluded,
    );
  }
}

enum WatchSortOption {
  featured,
  priceLowToHigh,
  priceHighToLow,
  newest,
  oldest,
  brandAz,
  brandZa,
}

extension WatchSortOptionLabel on WatchSortOption {
  String get label => switch (this) {
    WatchSortOption.featured => 'Default Sorting',
    WatchSortOption.priceLowToHigh => 'Price: Low to High',
    WatchSortOption.priceHighToLow => 'Price: High to Low',
    WatchSortOption.newest => 'Newest Arrivals',
    WatchSortOption.oldest => 'Oldest Arrivals',
    WatchSortOption.brandAz => 'Brand Name (A-Z)',
    WatchSortOption.brandZa => 'Brand Name (Z-A)',
  };
}

enum WatchViewMode { grid, list }
