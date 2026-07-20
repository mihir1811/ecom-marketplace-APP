/// Immutable filter state for the watches catalog (drawer filter order).
class WatchFilterState {
  const WatchFilterState({
    this.searchQuery = '',
    this.brands = const {},
    this.categories = const {},
    this.priceRanges = const {},
    this.movements = const {},
    this.genders = const {},
    this.conditions = const {},
    this.caseMaterials = const {},
    this.dialColors = const {},
    this.caseSizeRanges = const {},
    this.caseShapes = const {},
    this.caseBacks = const {},
    this.strapMaterials = const {},
    this.crownTypes = const {},
    this.strapColors = const {},
    this.claspTypes = const {},
    this.glassMaterials = const {},
    this.powerReserves = const {},
    this.waterResistances = const {},
    this.authentications = const {},
    this.modelYears = const {},
    this.certifications = const {},
    this.bezelTypes = const {},
    this.bezelMaterials = const {},
    this.stonesOnDial = const {},
    this.configurations = const {},
    this.materials = const {},
    this.preciousStoneTypes = const {},
    this.claspMaterials = const {},
    this.indexes = const {},
  });

  final String searchQuery;
  final Set<String> brands;
  final Set<String> categories;
  final Set<String> priceRanges;
  final Set<String> movements;
  final Set<String> genders;
  final Set<String> conditions;
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
  final Set<String> powerReserves;
  final Set<String> waterResistances;
  final Set<String> authentications;
  final Set<String> modelYears;
  final Set<String> certifications;
  final Set<String> bezelTypes;
  final Set<String> bezelMaterials;
  final Set<String> stonesOnDial;
  final Set<String> configurations;
  final Set<String> materials;
  final Set<String> preciousStoneTypes;
  final Set<String> indexes;

  static const categoryOptions = [
    'Dress',
    'Sport',
    'Luxury',
    'Diver',
    'Pilot',
    'Racing',
    'Casual',
    'Vintage',
    'Minimalist',
    'Fashion',
    'Chronograph',
    'GMT',
    'Field',
    'Smart',
  ];

  static const priceRangeOptions = [
    'Under \$500',
    '\$500 – \$1,000',
    '\$1,000 – \$5,000',
    '\$5,000 – \$15,000',
    '\$15,000 – \$50,000',
    '\$50,000+',
  ];

  static const movementOptions = ['Automatic', 'Quartz', 'Manual'];

  static const genderOptions = ['Men', 'Women', 'Unisex'];

  static const conditionOptions = [
    'New',
    'Unworn',
    'Like New',
    'Excellent',
    'Very Good',
    'Good',
    'Fair',
    'Used',
    'Vintage',
  ];

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
    'Brass',
    'Two-Tone Steel & Gold',
    'Palladium',
    'Sterling Silver',
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
    'Meteorite',
    'Skeleton',
    'Multicolour',
  ];

  static const caseSizeRangeOptions = [
    '28–30 mm',
    '31–34 mm',
    '35–38 mm',
    '39–42 mm',
    '43–46 mm',
  ];

  static const caseShapeOptions = [
    'Asymmetrical',
    'Cushion',
    'Drop',
    'Oval',
    'Rectangular',
    'Round',
    'Square',
    'Tonneau',
    'Octagon',
    'Dodecagon',
    'Barrel',
    'Pentagon',
    'Hexagon',
    'Tetradecagon',
    'Triangular',
  ];

  static const caseBackOptions = [
    'Solid',
    'Exhibition',
    'Open',
    'Sapphire',
    'Transparent',
    'Display',
    'Screw-Down',
    'Snap-On',
    'Hinged',
  ];

  static const strapMaterialOptions = [
    'Stainless Steel',
    'Ceramic',
    'Cotton',
    'Denim',
    'Fabric',
    'Leather',
    'Nato',
    'Nylon',
    'Rubber',
    'Satin',
    'Silicone',
    'Gold',
    'Titanium',
  ];

  static const crownTypeOptions = [
    'Push-Pull Crown',
    'Screw-Down Crown',
    'Onion Crown',
    'Pumpkin Crown',
    'Diamond Crown',
    'Cabochon Crown',
    'Fluted Crown',
    'Coin-Edge Crown',
    'Oversized Crown',
    'Recessed Crown',
    'Protected Crown',
    'Crown Guard Design',
    'Left-Hand Crown (Destro)',
    'Twin Crowns',
    'Compressor Crowns',
    'Monobloc Crown System',
  ];

  static const strapColorOptions = [
    'Anthracite',
    'Beige',
    'Black',
    'Blue',
    'Brown',
    'Cream',
    'Green',
    'Grey',
    'Multicolour',
    'Orange',
    'Pink',
    'Red',
    'Rose Gold',
    'Silver',
    'White',
    'Yellow',
    'Yellow Gold',
    'Burgundy',
    'Purple',
    'Turquoise',
    'Bronze',
    'Gold',
    'Bicolour',
  ];

  static const claspTypeOptions = [
    'Pin Buckle',
    'Tang Buckle',
    'Deployant Clasp',
    'Deployment Clasp',
    'Folding Clasp',
    'Double Folding Clasp',
    'Butterfly Clasp',
    'Hidden Clasp',
    'Jewelry Clasp',
    'Hook Clasp',
    'Sliding Clasp',
    'Ladder Clasp',
    'Velcro Closure',
    'Hook-and-Loop Closure',
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
    'Bronze',
    'Brass',
    'Silver',
    'Tungsten',
    'PVD-Coated Steel',
    'DLC-Coated Steel',
    'Gold-Plated Steel',
    'Two-Tone Steel & Gold',
    'Titanium & Gold',
  ];

  static const glassMaterialOptions = [
    'Sapphire Crystal',
    'Mineral Glass',
    'Acrylic',
    'Hesalite',
    'Domed Sapphire',
    'Flat Sapphire',
  ];

  static const powerReserveOptions = [
    '0–40 Hours',
    '41–48 Hours',
    '49–72 Hours',
    '73–120 Hours',
    '121–192 Hours',
    '193–336 Hours',
    '337+ Hours',
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
    '1200m',
    '2000m',
    '3000m',
  ];

  static const authenticationOptions = [
    'No Included (Original)',
    'Papers Included (Original)',
    'Warranty Card Included (Original)',
  ];

  static const modelYearOptions = ['2024', '2023', '2022', '2021', '2020'];

  static const certificationOptions = [
    'COSC',
    'Master Chronometer',
    'Superlative Chronometer',
    'Geneva Seal',
    'Poinçon de Genève',
    'METAS',
    'None',
  ];

  static const bezelTypeOptions = [
    'Fixed',
    'Unidirectional Rotating',
    'Bidirectional Rotating',
    'Countdown',
    'Dive',
    'GMT',
    'World Time',
    'Tachymeter',
    'Pulsometer',
    'Telemeter',
    'Compass',
    'Slide Rule',
    'Ring Command',
    'Internal Rotating',
    'Coin Edge',
    'Engine-Turned',
    'Fluted',
    'Smooth',
    'Gem-Set',
  ];

  static const bezelMaterialOptions = [
    'Stainless Steel',
    'Titanium',
    'Aluminum',
    'Ceramic',
    'High-Tech Ceramic',
    'Cerachrom (Ceramic Composite)',
    'Carbon Fiber',
    'Forged Carbon',
    'Bronze',
    'Brass',
    'Yellow Gold',
    'Rose Gold',
    'White Gold',
    'Platinum',
    'Palladium',
    'Sapphire Crystal',
  ];

  static const stonesOnDialOptions = ['1', '2', '3', '4'];

  static const configurationOptions = [
    'Date',
    'Day-Date',
    'Chronograph',
    'GMT',
    'Moonphase',
    'Perpetual Calendar',
    'Annual Calendar',
    'Tourbillon',
    'Minute Repeater',
    'Power Reserve',
    'World Time',
    'Alarm',
  ];

  static const materialOptions = [
    'Luminous hands and markers',
    'Rotating bezel',
    'Helium escape valve',
    'Anti-magnetic',
    'Shock resistant',
    'Screw-down crown',
    'Exhibition caseback',
    'Quick-set date',
  ];

  static const preciousStoneTypeOptions = [
    'Diamond',
    'Ruby',
    'Sapphire',
    'Emerald',
    'Onyx',
    'Mother of Pearl',
  ];

  static const indexesOptions = [
    'Roman',
    'Arabic',
    'Baton',
    'Dot',
    'Stick',
    'Diamond',
    'Mixed',
  ];

  bool get hasActiveFilters =>
      brands.isNotEmpty ||
      categories.isNotEmpty ||
      priceRanges.isNotEmpty ||
      movements.isNotEmpty ||
      genders.isNotEmpty ||
      conditions.isNotEmpty ||
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
      powerReserves.isNotEmpty ||
      waterResistances.isNotEmpty ||
      authentications.isNotEmpty ||
      modelYears.isNotEmpty ||
      certifications.isNotEmpty ||
      bezelTypes.isNotEmpty ||
      bezelMaterials.isNotEmpty ||
      stonesOnDial.isNotEmpty ||
      configurations.isNotEmpty ||
      materials.isNotEmpty ||
      preciousStoneTypes.isNotEmpty ||
      indexes.isNotEmpty ||
      searchQuery.trim().isNotEmpty;

  int get activeCount {
    var count = 0;
    void bump(Set s) {
      if (s.isNotEmpty) count++;
    }

    bump(brands);
    bump(categories);
    bump(priceRanges);
    bump(movements);
    bump(genders);
    bump(conditions);
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
    bump(powerReserves);
    bump(waterResistances);
    bump(authentications);
    bump(modelYears);
    bump(certifications);
    bump(bezelTypes);
    bump(bezelMaterials);
    bump(stonesOnDial);
    bump(configurations);
    bump(materials);
    bump(preciousStoneTypes);
    bump(indexes);
    return count;
  }

  WatchFilterState copyWith({
    String? searchQuery,
    Set<String>? brands,
    Set<String>? categories,
    Set<String>? priceRanges,
    Set<String>? movements,
    Set<String>? genders,
    Set<String>? conditions,
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
    Set<String>? powerReserves,
    Set<String>? waterResistances,
    Set<String>? authentications,
    Set<String>? modelYears,
    Set<String>? certifications,
    Set<String>? bezelTypes,
    Set<String>? bezelMaterials,
    Set<String>? stonesOnDial,
    Set<String>? configurations,
    Set<String>? materials,
    Set<String>? preciousStoneTypes,
    Set<String>? indexes,
  }) {
    return WatchFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      brands: brands ?? this.brands,
      categories: categories ?? this.categories,
      priceRanges: priceRanges ?? this.priceRanges,
      movements: movements ?? this.movements,
      genders: genders ?? this.genders,
      conditions: conditions ?? this.conditions,
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
      powerReserves: powerReserves ?? this.powerReserves,
      waterResistances: waterResistances ?? this.waterResistances,
      authentications: authentications ?? this.authentications,
      modelYears: modelYears ?? this.modelYears,
      certifications: certifications ?? this.certifications,
      bezelTypes: bezelTypes ?? this.bezelTypes,
      bezelMaterials: bezelMaterials ?? this.bezelMaterials,
      stonesOnDial: stonesOnDial ?? this.stonesOnDial,
      configurations: configurations ?? this.configurations,
      materials: materials ?? this.materials,
      preciousStoneTypes: preciousStoneTypes ?? this.preciousStoneTypes,
      indexes: indexes ?? this.indexes,
    );
  }
}

enum WatchSortOption {
  featured,
  priceLowToHigh,
  priceHighToLow,
  newest,
  brandAz,
}

extension WatchSortOptionLabel on WatchSortOption {
  String get label => switch (this) {
        WatchSortOption.featured => 'Featured',
        WatchSortOption.priceLowToHigh => 'Price: Low to High',
        WatchSortOption.priceHighToLow => 'Price: High to Low',
        WatchSortOption.newest => 'Newest',
        WatchSortOption.brandAz => 'Brand A–Z',
      };
}

enum WatchViewMode { grid, list }
