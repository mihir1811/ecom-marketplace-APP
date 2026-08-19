/// Immutable state holding all search and filter values for the gemstone search screen.
class GemstoneFilterState {
  static const List<String> stoneTypes = ['Natural', 'Lab Grown'];

  static const List<String> lotTypes = ['Single', 'Melee'];

  /// Primary gemstone types shown before expanding the grid.
  static const List<String> primaryGemstoneTypes = [
    'Ruby',
    'Sapphire',
    'Emerald',
    'Tanzanite',
    'Red Coral',
    'Amethyst',
    'Aquamarine',
    'Topaz',
    'Garnet',
    'Opal',
    'Tourmaline',
    'Peridot',
  ];

  /// Additional gemstone types revealed by the "Show More" button.
  static const List<String> extendedGemstoneTypes = [
    'Lapis Lazuli',
    'Moonstone',
    'Alexandrite',
    'Agate',
    'Amber',
    'Ametrine',
    'Andalusite',
    'Apatite',
    'Aventurine',
    'Azurite',
    'Beryl',
    'Bloodstone',
    'Carnelian',
    'Chalcedony',
    'Chrome Diopside',
    'Chrysoberyl',
    'Chrysoprase',
    'Citrine',
    'Danburite',
    'Diaspore',
    'Fluorite',
    'Goshenite',
    'Heliodor',
    'Hematite',
    'Hiddenite',
    'Iolite',
    'Jade',
    'Jadeite',
    'Jasper',
    'Kunzite',
    'Kyanite',
    'Labradorite',
    'Larimar',
    'Malachite',
    'Morganite',
    'Obsidian',
    'Onyx',
    'Pearl',
    'Prehnite',
    'Quartz',
    'Rhodolite',
    'Rose Quartz',
    'Rubellite',
    'Rutilated Quartz',
    'Scapolite',
    'Serpentine',
    'Smoky Quartz',
    'Sodalite',
    'Spessartite',
    'Sphene',
    'Spinel',
    'Sugilite',
    'Sunstone',
    "Tiger's Eye",
    'Tsavorite',
    'Turquoise',
    'Unakite',
    'Variscite',
    'Zircon',
    'Zoisite',
  ];

  static List<String> get allGemstoneTypes =>
      [...primaryGemstoneTypes, ...extendedGemstoneTypes];

  /// Month -> birthstone mapping displayed in the Birthstones grid.
  static const Map<String, String> birthstones = {
    'January': 'Garnet',
    'February': 'Amethyst',
    'March': 'Aquamarine',
    'April': 'Diamond',
    'May': 'Emerald',
    'June': 'Pearl',
    'July': 'Ruby',
    'August': 'Peridot',
    'September': 'Sapphire',
    'October': 'Opal',
    'November': 'Topaz',
    'December': 'Tanzanite',
  };

  /// Gemstone shapes with the closest matching diamond SVG asset name.
  static const Map<String, String> shapeSvgNames = {
    'Round': 'Round',
    'Oval': 'Oval',
    'Pear': 'Pear',
    'Cushion': 'Cushion',
    'Heart': 'Heart',
    'Emerald': 'Emerald',
    'Princess': 'Princess',
    'Marquise': 'Marquise',
    'Radiant': 'Radiant',
    'Asscher': 'Asscher',
    'Baguette': 'Baguette',
    'Trillion': 'Trilliant',
    'Hexagon': 'Flanders',
    'Octagon': 'Asscher',
    'Cabochon': 'Polki',
  };

  static List<String> get shapes => shapeSvgNames.keys.toList();

  static const List<String> colors = [
    'Red',
    'Blue',
    'Green',
    'Purple',
    'Pink',
    'Yellow',
    'Orange',
    'White',
    'Black',
    'Brown',
    'Teal',
    'Bi',
    'Multi',
    'Other',
  ];

  /// Color swatches for the UI. Melee hides `Multi` (use `Other` instead).
  static List<String> colorsForDisplay({required bool isMelee}) {
    if (!isMelee) return colors;
    return [for (final color in colors) if (color != 'Multi') color];
  }

  static const List<String> colorIntensities = [
    'Faint',
    'Very Light',
    'Light',
    'Fancy Light',
  ];

  static const List<String> modifiers = [
    'Bluish',
    'Greenish',
    'Yellowish',
    'Orangy',
  ];

  static const List<String> fluorescenceGrades = [
    'None',
    'Faint',
    'Medium',
    'Strong',
    'Very Strong',
  ];

  static const List<String> fluorescenceColors = [
    'None',
    'Blue',
    'Yellow',
    'White',
    'Green',
    'Orange',
    'Red',
  ];

  static const Map<String, String> fluorescenceColorsHex = {
    'None': '#E5E7EB',
    'Blue': '#2563EB',
    'Yellow': '#FACC15',
    'White': '#FFFFFF',
    'Green': '#22C55E',
    'Orange': '#F97316',
    'Red': '#EF4444',
  };

  static const List<String> clarities = [
    'Eye Clean',
    'Slightly Included',
    'Moderately Included',
    'Visibly Included',
  ];

  static const List<String> qualityGrades = [
    'AAA+',
    'AAA',
    'AA',
    'A',
    'B',
    'C',
  ];

  static const List<String> treatments = [
    'Heated',
    'Coated',
    'Dyed',
    'Enhancement',
    'Filled',
    'Irradiated',
    'Heating & Pressure',
    'Impregnated',
    'Infused',
    'Oiled',
    'Lasering',
    'None',
    'Cilling',
    'Other',
    'Waxing',
  ];

  static const List<String> certifications = [
    'GIA',
    'AGL',
    'GRS',
    'Gübelin',
    'SSEF',
    'AGS',
    'IGI',
    'Others',
  ];

  /// Origin countries, kept in alphabetical order.
  static const List<String> origins = [
    'Afghanistan',
    'Australia',
    'Brazil',
    'Burma',
    'Cambodia',
    'Colombia',
    'Ethiopia',
    'India',
    'Kenya',
    'Madagascar',
    'Mozambique',
    'Nigeria',
    'Pakistan',
    'Russia',
    'Sri Lanka',
    'Tanzania',
    'Thailand',
    'Vietnam',
    'Zambia',
  ];

  /// Flag emoji for each gemstone origin.
  static const Map<String, String> originFlags = {
    'Burma': '\uD83C\uDDF2\uD83C\uDDF2',
    'Sri Lanka': '\uD83C\uDDF1\uD83C\uDDF0',
    'Madagascar': '\uD83C\uDDF2\uD83C\uDDEC',
    'Thailand': '\uD83C\uDDF9\uD83C\uDDED',
    'Mozambique': '\uD83C\uDDF2\uD83C\uDDFF',
    'Colombia': '\uD83C\uDDE8\uD83C\uDDF4',
    'Brazil': '\uD83C\uDDE7\uD83C\uDDF7',
    'Tanzania': '\uD83C\uDDF9\uD83C\uDDFF',
    'Afghanistan': '\uD83C\uDDE6\uD83C\uDDEB',
    'Australia': '\uD83C\uDDE6\uD83C\uDDFA',
    'Cambodia': '\uD83C\uDDF0\uD83C\uDDED',
    'Ethiopia': '\uD83C\uDDEA\uD83C\uDDF9',
    'India': '\uD83C\uDDEE\uD83C\uDDF3',
    'Kenya': '\uD83C\uDDF0\uD83C\uDDEA',
    'Nigeria': '\uD83C\uDDF3\uD83C\uDDEC',
    'Pakistan': '\uD83C\uDDF5\uD83C\uDDF0',
    'Russia': '\uD83C\uDDF7\uD83C\uDDFA',
    'Vietnam': '\uD83C\uDDFB\uD83C\uDDF3',
    'Zambia': '\uD83C\uDDFF\uD83C\uDDF2',
  };

  static const List<String> cutGrades = [
    'Excellent',
    'Very Good',
    'Good',
    'Fair',
    'Poor',
  ];

  // Range limits
  static const double caratMin = 0.16;
  static const double caratMax = 100.0;
  static const double priceMin = 0.0;
  static const double pricePerPieceMax = 200000.0;
  static const double totalPriceMax = 1000000.0;
  static const double pcsMin = 1.0;
  static const double pcsMax = 1000000.0;
  static const double dimensionMin = 0.0;
  static const double dimensionMax = 100.0;
  static const double ratioMin = 0.5;
  static const double ratioMax = 5.0;

  /// Quick-select total carat ranges, identical to the diamond filter screen.
  static const List<Map<String, double>> caratQuickRanges = [
    {'min': 0.2, 'max': 0.25},
    {'min': 0.3, 'max': 0.39},
    {'min': 0.4, 'max': 0.49},
    {'min': 0.5, 'max': 0.59},
    {'min': 0.7, 'max': 0.89},
    {'min': 0.9, 'max': 0.99},
    {'min': 1.0, 'max': 1.49},
    {'min': 1.5, 'max': 1.99},
  ];

  const GemstoneFilterState({
    this.stoneType = 'Natural',
    this.lotType = 'Single',
    this.selectedGemstoneTypes = const [],
    this.selectedBirthstoneMonths = const [],
    this.selectedShapes = const [],
    this.minTotalCarat = caratMin,
    this.maxTotalCarat = caratMax,
    this.selectedCaratQuickRanges = const [],
    this.minCaratPerPiece = caratMin,
    this.maxCaratPerPiece = caratMax,
    this.minPricePerPiece = priceMin,
    this.maxPricePerPiece = pricePerPieceMax,
    this.minPricePerCarat = priceMin,
    this.maxPricePerCarat = pricePerPieceMax,
    this.minTotalPcs = pcsMin,
    this.maxTotalPcs = pcsMax,
    this.minTotalPrice = priceMin,
    this.maxTotalPrice = totalPriceMax,
    this.selectedColors = const [],
    this.selectedIntensities = const [],
    this.selectedModifiers = const [],
    this.selectedFluorescence = const [],
    this.selectedFluorescenceColor,
    this.selectedClarities = const [],
    this.selectedQualityGrade,
    this.separable = false,
    this.searchByMedia = false,
    this.selectedTreatments = const [],
    this.selectedCertifications = const [],
    this.selectedOrigin,
    this.selectedCutGrades = const [],
    this.vendorLocations = const [],
    this.companyNames = const [],
    this.selectedOriginCountry,
    this.minLength = dimensionMin,
    this.maxLength = dimensionMax,
    this.minWidth = dimensionMin,
    this.maxWidth = dimensionMax,
    this.minHeight = dimensionMin,
    this.maxHeight = dimensionMax,
    this.minRatio = ratioMin,
    this.maxRatio = ratioMax,
  });

  final String? stoneType;
  final String? lotType;
  final List<String> selectedGemstoneTypes;
  final List<String> selectedBirthstoneMonths;
  final List<String> selectedShapes;
  final double minTotalCarat;
  final double maxTotalCarat;
  final List<int> selectedCaratQuickRanges;
  final double minCaratPerPiece;
  final double maxCaratPerPiece;
  final double minPricePerPiece;
  final double maxPricePerPiece;
  final double minPricePerCarat;
  final double maxPricePerCarat;
  final double minTotalPcs;
  final double maxTotalPcs;
  final double minTotalPrice;
  final double maxTotalPrice;
  final List<String> selectedColors;
  final List<String> selectedIntensities;
  final List<String> selectedModifiers;
  final List<String> selectedFluorescence;
  final String? selectedFluorescenceColor;
  final List<String> selectedClarities;
  final String? selectedQualityGrade;
  final bool separable;
  final bool searchByMedia;
  final List<String> selectedTreatments;
  final List<String> selectedCertifications;
  final String? selectedOrigin;
  final List<String> selectedCutGrades;
  final List<String> vendorLocations;
  final List<String> companyNames;
  final String? selectedOriginCountry;
  final double minLength;
  final double maxLength;
  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;
  final double minRatio;
  final double maxRatio;

  static const Object _unset = Object();

  GemstoneFilterState copyWith({
    Object? stoneType = _unset,
    Object? lotType = _unset,
    List<String>? selectedGemstoneTypes,
    List<String>? selectedBirthstoneMonths,
    List<String>? selectedShapes,
    double? minTotalCarat,
    double? maxTotalCarat,
    List<int>? selectedCaratQuickRanges,
    double? minCaratPerPiece,
    double? maxCaratPerPiece,
    double? minPricePerPiece,
    double? maxPricePerPiece,
    double? minPricePerCarat,
    double? maxPricePerCarat,
    double? minTotalPcs,
    double? maxTotalPcs,
    double? minTotalPrice,
    double? maxTotalPrice,
    List<String>? selectedColors,
    List<String>? selectedIntensities,
    List<String>? selectedModifiers,
    List<String>? selectedFluorescence,
    Object? selectedFluorescenceColor = _unset,
    List<String>? selectedClarities,
    Object? selectedQualityGrade = _unset,
    bool? separable,
    bool? searchByMedia,
    List<String>? selectedTreatments,
    List<String>? selectedCertifications,
    Object? selectedOrigin = _unset,
    List<String>? selectedCutGrades,
    List<String>? vendorLocations,
    List<String>? companyNames,
    Object? selectedOriginCountry = _unset,
    double? minLength,
    double? maxLength,
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
    double? minRatio,
    double? maxRatio,
  }) {
    return GemstoneFilterState(
      stoneType:
          identical(stoneType, _unset) ? this.stoneType : stoneType as String?,
      lotType: identical(lotType, _unset) ? this.lotType : lotType as String?,
      selectedGemstoneTypes:
          selectedGemstoneTypes ?? this.selectedGemstoneTypes,
      selectedBirthstoneMonths:
          selectedBirthstoneMonths ?? this.selectedBirthstoneMonths,
      selectedShapes: selectedShapes ?? this.selectedShapes,
      minTotalCarat: minTotalCarat ?? this.minTotalCarat,
      maxTotalCarat: maxTotalCarat ?? this.maxTotalCarat,
      selectedCaratQuickRanges:
          selectedCaratQuickRanges ?? this.selectedCaratQuickRanges,
      minCaratPerPiece: minCaratPerPiece ?? this.minCaratPerPiece,
      maxCaratPerPiece: maxCaratPerPiece ?? this.maxCaratPerPiece,
      minPricePerPiece: minPricePerPiece ?? this.minPricePerPiece,
      maxPricePerPiece: maxPricePerPiece ?? this.maxPricePerPiece,
      minPricePerCarat: minPricePerCarat ?? this.minPricePerCarat,
      maxPricePerCarat: maxPricePerCarat ?? this.maxPricePerCarat,
      minTotalPcs: minTotalPcs ?? this.minTotalPcs,
      maxTotalPcs: maxTotalPcs ?? this.maxTotalPcs,
      minTotalPrice: minTotalPrice ?? this.minTotalPrice,
      maxTotalPrice: maxTotalPrice ?? this.maxTotalPrice,
      selectedColors: selectedColors ?? this.selectedColors,
      selectedIntensities: selectedIntensities ?? this.selectedIntensities,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      selectedFluorescence: selectedFluorescence ?? this.selectedFluorescence,
      selectedFluorescenceColor: identical(selectedFluorescenceColor, _unset)
          ? this.selectedFluorescenceColor
          : selectedFluorescenceColor as String?,
      selectedClarities: selectedClarities ?? this.selectedClarities,
      selectedQualityGrade: identical(selectedQualityGrade, _unset)
          ? this.selectedQualityGrade
          : selectedQualityGrade as String?,
      separable: separable ?? this.separable,
      searchByMedia: searchByMedia ?? this.searchByMedia,
      selectedTreatments: selectedTreatments ?? this.selectedTreatments,
      selectedCertifications:
          selectedCertifications ?? this.selectedCertifications,
      selectedOrigin: identical(selectedOrigin, _unset)
          ? this.selectedOrigin
          : selectedOrigin as String?,
      selectedCutGrades: selectedCutGrades ?? this.selectedCutGrades,
      vendorLocations: vendorLocations ?? this.vendorLocations,
      companyNames: companyNames ?? this.companyNames,
      selectedOriginCountry: identical(selectedOriginCountry, _unset)
          ? this.selectedOriginCountry
          : selectedOriginCountry as String?,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      minRatio: minRatio ?? this.minRatio,
      maxRatio: maxRatio ?? this.maxRatio,
    );
  }
}
