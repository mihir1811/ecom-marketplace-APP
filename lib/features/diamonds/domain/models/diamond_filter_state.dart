/// Enum representing the type of diamond origin.
enum LabNaturalType {
  natural('Natural Diamond'),

  /// Melee / sieve lot filters on the natural diamond finder (not the lab-grown catalog).
  labGrown('Natural Melee');

  final String label;
  const LabNaturalType(this.label);

  bool get usesMeleeFilters => this == LabNaturalType.labGrown;
}

/// Immutable state holding all search and filter values for the diamond search screen.
class DiamondFilterState {
  // Constants for slider mappings
  static const List<String> colors = [
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];
  static const List<String> clarities = [
    'FL',
    'IF',
    'VVS1',
    'VVS2',
    'VS1',
    'VS2',
    'SI1',
    'SI2',
    'SI3',
    'I1',
    'I2',
    'I3',
  ];
  static const List<String> cuts = [
    'Ideal',
    'Excellent',
    'Very Good',
    'Good',
    'Fair',
  ];
  static const List<String> polishingGrades = [
    'Ideal',
    'Excellent',
    'Very Good',
    'Good',
    'Fair',
  ];
  static const List<String> symmetryGrades = [
    'Ideal',
    'Excellent',
    'Very Good',
    'Good',
    'Fair',
  ];
  static const List<String> fluorescenceGrades = [
    'None',
    'Faint',
    'Medium',
    'Strong',
    'Very Strong',
  ];
  static const List<String> labs = [
    'GIA',
    'HRD',
    'IGI',
    'EGL',
    'AGS',
    'Others',
  ];

  static const List<String> fancyColors = [
    'Yellow',
    'Orange',
    'Blue',
    'Red',
    'Pink',
    'Green',
    'olive',
    'Brown',
    'Purple',
    'Violet',
    'Grey',
    'Black',
    'Multi',
  ];

  /// Fancy colors on the lab-grown catalog.
  static const List<String> labFancyColors = [
    'Yellow',
    'Orange',
    'Blue',
    'Red',
    'Pink',
    'Green',
    'olive',
    'Brown',
    'Purple',
    'Violet',
    'Grey',
    'Black',
    'Multi',
  ];

  /// Fancy color labels for the UI. Melee replaces `Multi` with `Other`.
  static List<String> fancyColorsForDisplay({
    required bool isLabCatalog,
    required bool useMeleeFilters,
  }) {
    final base = isLabCatalog ? labFancyColors : fancyColors;
    if (!useMeleeFilters) return base;
    return [for (final color in base) color == 'Multi' ? 'Other' : color];
  }

  /// Lab-grown catalog categories (single-select switch).
  static const List<String> labCategories = ['Lab Diamond', 'Lab Melee'];

  /// Lab-grown growth methods (multi-select).
  static const List<String> growthMethods = ['CVD', 'HPHT'];
  static const List<String> overtones = [
    'Yellow',
    'Yellowish',
    'Pink',
    'Pinkish',
    'Blue',
    'Blueish',
    'Green',
    'Greenish',
    'Orange',
    'Orangy',
    'Brown',
    'Brownish',
    'Red',
    'Reddish',
    'Violet',
    'Violetish',
    'Gray',
    'Grayish',
    'Black',
    'Blackish',
    'White',
    'Whiteish',
    'Chameleon',
    'Champagne',
    'Cognac',
    'Other',
  ];
  static const List<String> intensities = [
    'Faint',
    'Very Light',
    'Light',
    'Fancy Light',
    'Fancy',
    'Fancy Intense',
    'Fancy Vivid',
    'Fancy Deep',
    'Fancy Dark',
  ];

  static const List<String> fluorescenceColors = [
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

  static const List<String> milkyGrades = [
    'Slightly',
    'Moderately',
    'Strongly',
    'Severely',
  ];
  static const List<String> enhancements = [
    'HPHT (Treatment)',
    'Irradiation',
    'Fracture Filling',
    'Laser Drilling',
    'Surface Coating',
  ];
  static const List<String> roughSources = [
    'Canadian',
    'Sight Holder',
    'Russian',
    'Rio Tinto',
    'Others',
  ];

  /// Availability options (UI labels); none selected means no filter.
  static const List<String> availabilityOptions = [
    'Available',
    'On Memo',
    'On Hold',
    'Sold',
  ];

  static const List<String> girdles = [
    'Extremely Thin',
    'Very Thin',
    'Thin',
    'Slightly Thin',
    'Medium',
    'Slightly Thick',
    'Thick',
    'Very Thick',
    'Extremely Thick',
  ];
  static const List<String> culets = [
    'None',
    'Very Small',
    'Small',
    'Medium',
    'Slightly Large',
    'Large',
    'Very Large',
    'Extremely Large',
  ];

  static const List<String> countries = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Antigua and Barbuda',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia and Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Cabo Verde',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Central African Republic',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Congo',
    'Costa Rica',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czechia',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Eswatini',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'North Korea',
    'North Macedonia',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Palestine',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Rwanda',
    'Saint Kitts and Nevis',
    'Saint Lucia',
    'Saint Vincent and the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome and Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Korea',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Sweden',
    'Switzerland',
    'Syria',
    'Taiwan',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Timor-Leste',
    'Togo',
    'Tonga',
    'Trinidad and Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Vatican City',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe',
  ];

  static const Map<String, String> countryFlags = {
    'Afghanistan': '\uD83C\uDDE6\uD83C\uDDEB',
    'Albania': '\uD83C\uDDE6\uD83C\uDDF1',
    'Algeria': '\uD83C\uDDE6\uD83C\uDDFF',
    'Andorra': '\uD83C\uDDE6\uD83C\uDDE9',
    'Angola': '\uD83C\uDDE6\uD83C\uDDF4',
    'Antigua and Barbuda': '\uD83C\uDDE6\uD83C\uDDEC',
    'Argentina': '\uD83C\uDDE6\uD83C\uDDF7',
    'Armenia': '\uD83C\uDDE6\uD83C\uDDF2',
    'Australia': '\uD83C\uDDE6\uD83C\uDDFA',
    'Austria': '\uD83C\uDDE6\uD83C\uDDF9',
    'Azerbaijan': '\uD83C\uDDE6\uD83C\uDDFF',
    'Bahamas': '\uD83C\uDDE7\uD83C\uDDF8',
    'Bahrain': '\uD83C\uDDE7\uD83C\uDDED',
    'Bangladesh': '\uD83C\uDDE7\uD83C\uDDE9',
    'Barbados': '\uD83C\uDDE7\uD83C\uDDE7',
    'Belarus': '\uD83C\uDDE7\uD83C\uDDFE',
    'Belgium': '\uD83C\uDDE7\uD83C\uDDEA',
    'Belize': '\uD83C\uDDE7\uD83C\uDDFF',
    'Benin': '\uD83C\uDDE7\uD83C\uDDEF',
    'Bhutan': '\uD83C\uDDE7\uD83C\uDDF9',
    'Bolivia': '\uD83C\uDDE7\uD83C\uDDF4',
    'Bosnia and Herzegovina': '\uD83C\uDDE7\uD83C\uDDE6',
    'Botswana': '\uD83C\uDDE7\uD83C\uDDFC',
    'Brazil': '\uD83C\uDDE7\uD83C\uDDF7',
    'Brunei': '\uD83C\uDDE7\uD83C\uDDF3',
    'Bulgaria': '\uD83C\uDDE7\uD83C\uDDEC',
    'Burkina Faso': '\uD83C\uDDE7\uD83C\uDDEB',
    'Burundi': '\uD83C\uDDE7\uD83C\uDDEE',
    'Cabo Verde': '\uD83C\uDDF8\uD83C\uDDEB',
    'Cambodia': '\uD83C\uDDF0\uD83C\uDDED',
    'Cameroon': '\uD83C\uDDE8\uD83C\uDDF2',
    'Canada': '\uD83C\uDDE8\uD83C\uDDE6',
    'Central African Republic': '\uD83C\uDDE8\uD83C\uDDEB',
    'Chad': '\uD83C\uDDF9\uD83C\uDDE9',
    'Chile': '\uD83C\uDDE8\uD83C\uDDF1',
    'China': '\uD83C\uDDE8\uD83C\uDDF3',
    'Colombia': '\uD83C\uDDE8\uD83C\uDDF4',
    'Comoros': '\uD83C\uDDF0\uD83C\uDDF2',
    'Congo': '\uD83C\uDDE8\uD83C\uDDEC',
    'Costa Rica': '\uD83C\uDDE8\uD83C\uDDF7',
    'Croatia': '\uD83C\uDDED\uD83C\uDDF7',
    'Cuba': '\uD83C\uDDE8\uD83C\uDDFA',
    'Cyprus': '\uD83C\uDDE8\uD83C\uDDFE',
    'Czechia': '\uD83C\uDDE8\uD83C\uDDFF',
    'Denmark': '\uD83C\uDDE9\uD83C\uDDF0',
    'Djibouti': '\uD83C\uDDE9\uD83C\uDDEF',
    'Dominica': '\uD83C\uDDE9\uD83C\uDDF2',
    'Dominican Republic': '\uD83C\uDDE9\uD83C\uDDF4',
    'Ecuador': '\uD83C\uDDEA\uD83C\uDDE8',
    'Egypt': '\uD83C\uDDEA\uD83C\uDDEC',
    'El Salvador': '\uD83C\uDDF8\uD83C\uDDFB',
    'Equatorial Guinea': '\uD83C\uDDEC\uD83C\uDDF6',
    'Eritrea': '\uD83C\uDDEA\uD83C\uDDF7',
    'Estonia': '\uD83C\uDDEA\uD83C\uDDEA',
    'Eswatini': '\uD83C\uDDF8\uD83C\uDDFF',
    'Ethiopia': '\uD83C\uDDEA\uD83C\uDDF9',
    'Fiji': '\uD83C\uDDEB\uD83C\uDDEF',
    'Finland': '\uD83C\uDDEB\uD83C\uDDEE',
    'France': '\uD83C\uDDEB\uD83C\uDDF7',
    'Gabon': '\uD83C\uDDEC\uD83C\uDDE6',
    'Gambia': '\uD83C\uDDEC\uD83C\uDDF2',
    'Georgia': '\uD83C\uDDEC\uD83C\uDDEA',
    'Germany': '\uD83C\uDDE9\uD83C\uDDEA',
    'Ghana': '\uD83C\uDDEC\uD83C\uDDED',
    'Greece': '\uD83C\uDDEC\uD83C\uDDF7',
    'Grenada': '\uD83C\uDDEC\uD83C\uDDF9',
    'Guatemala': '\uD83C\uDDEC\uD83C\uDDF9',
    'Guinea': '\uD83C\uDDEC\uD83C\uDDF3',
    'Guinea-Bissau': '\uD83C\uDDF3\uD83C\uDDEC',
    'Guyana': '\uD83C\uDDEC\uD83C\uDDFE',
    'Haiti': '\uD83C\uDDED\uD83C\uDDF9',
    'Honduras': '\uD83C\uDDED\uD83C\uDDF3',
    'Hungary': '\uD83C\uDDED\uD83C\uDDFA',
    'Iceland': '\uD83C\uDDEE\uD83C\uDDF8',
    'India': '\uD83C\uDDEE\uD83C\uDDF3',
    'Indonesia': '\uD83C\uDDEE\uD83C\uDDE9',
    'Iran': '\uD83C\uDDEE\uD83C\uDDF7',
    'Iraq': '\uD83C\uDDEE\uD83C\uDDE6',
    'Ireland': '\uD83C\uDDEE\uD83C\uDDEA',
    'Israel': '\uD83C\uDDEE\uD83C\uDDF1',
    'Italy': '\uD83C\uDDEE\uD83C\uDDF9',
    'Jamaica': '\uD83C\uDDEF\uD83C\uDDF2',
    'Japan': '\uD83C\uDDEF\uD83C\uDDF5',
    'Jordan': '\uD83C\uDDEF\uD83C\uDDF4',
    'Kazakhstan': '\uD83C\uDDF0\uD83C\uDDFF',
    'Kenya': '\uD83C\uDDF0\uD83C\uDDEA',
    'Kiribati': '\uD83C\uDDF0\uD83C\uDDEE',
    'Kuwait': '\uD83C\uDDF2\uD83C\uDDFC',
    'Kyrgyzstan': '\uD83C\uDDF0\uD83C\uDDEC',
    'Laos': '\uD83C\uDDF1\uD83C\uDDE6',
    'Latvia': '\uD83C\uDDF1\uD83C\uDDFB',
    'Lebanon': '\uD83C\uDDF1\uD83C\uDDE7',
    'Lesotho': '\uD83C\uDDF1\uD83C\uDDF8',
    'Liberia': '\uD83C\uDDF1\uD83C\uDDF7',
    'Libya': '\uD83C\uDDF1\uD83C\uDDFE',
    'Liechtenstein': '\uD83C\uDDF1\uD83C\uDDEE',
    'Lithuania': '\uD83C\uDDF1\uD83C\uDDF9',
    'Luxembourg': '\uD83C\uDDF1\uD83C\uDDFA',
    'Madagascar': '\uD83C\uDDF2\uD83C\uDDEC',
    'Malawi': '\uD83C\uDDF2\uD83C\uDDFC',
    'Malaysia': '\uD83C\uDDF2\uD83C\uDDFE',
    'Maldives': '\uD83C\uDDF2\uD83C\uDDFB',
    'Mali': '\uD83C\uDDF2\uD83C\uDDF1',
    'Malta': '\uD83C\uDDF2\uD83C\uDDF9',
    'Marshall Islands': '\uD83C\uDDF2\uD83C\uDDEC',
    'Mauritania': '\uD83C\uDDF2\uD83C\uDDF7',
    'Mauritius': '\uD83C\uDDF2\uD83C\uDDFA',
    'Mexico': '\uD83C\uDDF2\uD83C\uDDFD',
    'Micronesia': '\uD83C\uDDF2\uD83C\uDDEB',
    'Moldova': '\uD83C\uDDF2\uD83C\uDDE9',
    'Monaco': '\uD83C\uDDF2\uD83C\uDDE8',
    'Mongolia': '\uD83C\uDDF2\uD83C\uDDF3',
    'Montenegro': '\uD83C\uDDF2\uD83C\uDDEA',
    'Morocco': '\uD83C\uDDF2\uD83C\uDDE6',
    'Mozambique': '\uD83C\uDDF2\uD83C\uDDFF',
    'Myanmar': '\uD83C\uDDF2\uD83C\uDDF2',
    'Namibia': '\uD83C\uDDF3\uD83C\uDDE6',
    'Nauru': '\uD83C\uDDF3\uD83C\uDDF7',
    'Nepal': '\uD83C\uDDF3\uD83C\uDDF5',
    'Netherlands': '\uD83C\uDDF3\uD83C\uDDF1',
    'New Zealand': '\uD83C\uDDF3\uD83C\uDDFF',
    'Nicaragua': '\uD83C\uDDF3\uD83C\uDDEE',
    'Niger': '\uD83C\uDDF3\uD83C\uDDEC',
    'Nigeria': '\uD83C\uDDF3\uD83C\uDDEC',
    'North Korea': '\uD83C\uDDF0\uD83C\uDDF5',
    'North Macedonia': '\uD83C\uDDF2\uD83C\uDDF0',
    'Norway': '\uD83C\uDDF3\uD83C\uDDF4',
    'Oman': '\uD83C\uDDF4\uD83C\uDDF2',
    'Pakistan': '\uD83C\uDDF5\uD83C\uDDF0',
    'Palau': '\uD83C\uDDF5\uD83C\uDDF8',
    'Palestine': '\uD83C\uDDF5\uD83C\uDDF8',
    'Panama': '\uD83C\uDDF5\uD83C\uDDE6',
    'Papua New Guinea': '\uD83C\uDDF5\uD83C\uDDEC',
    'Paraguay': '\uD83C\uDDF5\uD83C\uDDFE',
    'Peru': '\uD83C\uDDF5\uD83C\uDDEA',
    'Philippines': '\uD83C\uDDF5\uD83C\uDDED',
    'Poland': '\uD83C\uDDF5\uD83C\uDDF1',
    'Portugal': '\uD83C\uDDF5\uD83C\uDDF9',
    'Qatar': '\uD83C\uDDF6\uD83C\uDDE6',
    'Romania': '\uD83C\uDDF7\uD83C\uDDF4',
    'Russia': '\uD83C\uDDF7\uD83C\uDDFA',
    'Rwanda': '\uD83C\uDDF7\uD83C\uDDFC',
    'Saint Kitts and Nevis': '\uD83C\uDDF0\uD83C\uDDF3',
    'Saint Lucia': '\uD83C\uDDF1\uD83C\uDDE8',
    'Saint Vincent and the Grenadines': '\uD83C\uDDFB\uD83C\uDDE8',
    'Samoa': '\uD83C\uDDFC\uD83C\uDDF8',
    'San Marino': '\uD83C\uDDF8\uD83C\uDDF2',
    'Sao Tome and Principe': '\uD83C\uDDF8\uD83C\uDDF9',
    'Saudi Arabia': '\uD83C\uDDF8\uD83C\uDDE6',
    'Senegal': '\uD83C\uDDF8\uD83C\uDDF3',
    'Serbia': '\uD83C\uDDF7\uD83C\uDDF8',
    'Seychelles': '\uD83C\uDDF8\uD83C\uDDE8',
    'Sierra Leone': '\uD83C\uDDF8\uD83C\uDDF1',
    'Singapore': '\uD83C\uDDF8\uD83C\uDDEC',
    'Slovakia': '\uD83C\uDDF8\uD83C\uDDF0',
    'Slovenia': '\uD83C\uDDF8\uD83C\uDDEE',
    'Solomon Islands': '\uD83C\uDDF8\uD83C\uDDE7',
    'Somalia': '\uD83C\uDDF8\uD83C\uDDF4',
    'South Africa': '\uD83C\uDDFF\uD83C\uDDE6',
    'South Korea': '\uD83C\uDDF0\uD83C\uDDF7',
    'South Sudan': '\uD83C\uDDF8\uD83C\uDDF8',
    'Spain': '\uD83C\uDDEA\uD83C\uDDF8',
    'Sri Lanka': '\uD83C\uDDF1\uD83C\uDDF0',
    'Sudan': '\uD83C\uDDF8\uD83C\uDDE9',
    'Suriname': '\uD83C\uDDF8\uD83C\uDDF7',
    'Sweden': '\uD83C\uDDF8\uD83C\uDDEA',
    'Switzerland': '\uD83C\uDDE8\uD83C\uDDED',
    'Syria': '\uD83C\uDDF8\uD83C\uDDFE',
    'Taiwan': '\uD83C\uDDF9\uD83C\uDDFC',
    'Tajikistan': '\uD83C\uDDF9\uD83C\uDDEF',
    'Tanzania': '\uD83C\uDDF9\uD83C\uDDFF',
    'Thailand': '\uD83C\uDDF9\uD83C\uDDED',
    'Timor-Leste': '\uD83C\uDDF9\uD83C\uDDF1',
    'Togo': '\uD83C\uDDF9\uD83C\uDDEC',
    'Tonga': '\uD83C\uDDF9\uD83C\uDDF4',
    'Trinidad and Tobago': '\uD83C\uDDF9\uD83C\uDDF9',
    'Tunisia': '\uD83C\uDDF9\uD83C\uDDF3',
    'Turkey': '\uD83C\uDDF9\uD83C\uDDF7',
    'Turkmenistan': '\uD83C\uDDF9\uD83C\uDDF2',
    'Tuvalu': '\uD83C\uDDF9\uD83C\uDDFB',
    'Uganda': '\uD83C\uDDFA\uD83C\uDDEC',
    'Ukraine': '\uD83C\uDDFA\uD83C\uDDE6',
    'United Arab Emirates': '\uD83C\uDDE6\uD83C\uDDEA',
    'United Kingdom': '\uD83C\uDDEC\uD83C\uDDE7',
    'United States': '\uD83C\uDDFA\uD83C\uDDF8',
    'Uruguay': '\uD83C\uDDFA\uD83C\uDDFE',
    'Uzbekistan': '\uD83C\uDDFA\uD83C\uDDFF',
    'Vanuatu': '\uD83C\uDDFB\uD83C\uDDE6',
    'Vatican City': '\uD83C\uDDFB\uD83C\uDDE6',
    'Venezuela': '\uD83C\uDDFB\uD83C\uDDEA',
    'Vietnam': '\uD83C\uDDFB\uD83C\uDDF3',
    'Yemen': '\uD83C\uDDFE\uD83C\uDDEA',
    'Zambia': '\uD83C\uDDFF\uD83C\uDDF2',
    'Zimbabwe': '\uD83C\uDDFF\uD83C\uDDFC',
  };

  /// Quick-select carat bands covering common bridal / marketplace sizes.
  static const List<Map<String, double>> caratQuickRanges = [
    {'min': 0.2, 'max': 0.25},
    {'min': 0.3, 'max': 0.39},
    {'min': 0.4, 'max': 0.49},
    {'min': 0.5, 'max': 0.59},
    {'min': 0.7, 'max': 0.89},
    {'min': 0.9, 'max': 0.99},
    {'min': 1.0, 'max': 1.49},
    {'min': 1.5, 'max': 1.99},
    {'min': 2.0, 'max': 2.99},
    {'min': 3.0, 'max': 4.99},
    {'min': 5.0, 'max': 9.99},
  ];

  // Slider bounds: retail-realistic ranges (most stock is 0.3–5 ct;
  // GIA Fair+ proportions sit well inside the % / ° windows below).
  static const double priceMin = 0.0;
  static const double priceMax = 250000.0;
  static const double pricePerCaratMin = 0.0;
  static const double pricePerCaratMax = 50000.0;
  static const double caratMin = 0.20;
  static const double caratMax = 10.0;
  static const double dimensionMin = 0.0;
  static const double dimensionMax = 20.0;
  static const double ratioMin = 0.80;
  static const double ratioMax = 3.0;
  static const double tableMin = 45.0;
  static const double tableMax = 75.0;
  static const double depthMin = 50.0;
  static const double depthMax = 75.0;
  static const double crownAngleMin = 20.0;
  static const double crownAngleMax = 42.0;
  static const double crownHeightMin = 7.0;
  static const double crownHeightMax = 21.0;
  static const double pavilionAngleMin = 37.0;
  static const double pavilionAngleMax = 45.0;
  static const double pavilionDepthMin = 38.0;
  static const double pavilionDepthMax = 50.0;
  static const double caratPerPcsMinLimit = 0.001;
  static const double caratPerPcsMaxLimit = 1.0;
  static const double pricePerPcsMinLimit = 0.0;
  static const double pricePerPcsMaxLimit = 5000.0;
  static const double totalPcsMinLimit = 1.0;
  static const double totalPcsMaxLimit = 100000.0;

  const DiamondFilterState({
    this.labNatural = LabNaturalType.natural,
    this.labCategory = 'Lab Diamond',
    this.selectedGrowthMethods = const [],
    this.shapes = const [],
    this.minPrice = priceMin,
    this.maxPrice = priceMax,
    this.minPricePerCarat = pricePerCaratMin,
    this.maxPricePerCarat = pricePerCaratMax,
    this.minCarat = caratMin,
    this.maxCarat = caratMax,
    this.selectedCaratQuickRanges = const [],
    this.minColorIndex = 0,
    this.maxColorIndex = 22,
    this.isFancyColor = false,
    this.selectedStandardColors = const [],
    this.selectedFancyColors = const [],
    this.selectedOvertones = const [],
    this.selectedIntensities = const [],
    this.noBgm = false,
    this.eyeClean = false,
    this.minClarityIndex = 0,
    this.maxClarityIndex = 11,
    this.selectedClarityGrades = const [],
    this.selectedCuts = const [],
    this.selectedFinishPreset = const [],
    this.heartAndArrow = false,
    this.threeEx = false,
    this.sellersWithVideo = false,
    this.sellersWithImages = false,
    this.separable = false,
    this.searchByMedia = false,
    this.selectedAvailabilities = const [],
    this.makeAnOffer = false,
    this.selectedPolish = const [],
    this.selectedSymmetry = const [],
    this.selectedFluorescence = const [],
    this.selectedFluorescenceColors = const [],
    this.selectedMilkyGrades = const [],
    this.selectedEnhancements = const [],
    this.selectedRoughSources = const [],
    this.companyNames = const [],
    this.vendorLocations = const [],
    this.excludedCompanyNames = const [],
    this.excludedVendorLocations = const [],
    this.selectedLabs = const [],
    this.couponCode,
    this.discountPercentage,
    this.showAdditionalFilters = false,
    this.minSellerRating = 0.0,
    // Upgraded structure advanced filters
    this.minLength = dimensionMin,
    this.maxLength = dimensionMax,
    this.minWidth = dimensionMin,
    this.maxWidth = dimensionMax,
    this.minHeight = dimensionMin,
    this.maxHeight = dimensionMax,
    this.minRatio = ratioMin,
    this.maxRatio = ratioMax,
    this.minTable = tableMin,
    this.maxTable = tableMax,
    this.minDepth = depthMin,
    this.maxDepth = depthMax,
    this.minCrownAngle = crownAngleMin,
    this.maxCrownAngle = crownAngleMax,
    this.minCrownHeight = crownHeightMin,
    this.maxCrownHeight = crownHeightMax,
    this.minPavilionAngle = pavilionAngleMin,
    this.maxPavilionAngle = pavilionAngleMax,
    this.minPavilionDepth = pavilionDepthMin,
    this.maxPavilionDepth = pavilionDepthMax,
    this.selectedGirdles = const [],
    this.selectedCulets = const [],
    this.selectedOrigins = const [],
    this.selectedSieveIndices = const [],
    this.activeSievePresets = const [],
    // Natural Melee Pcs range filters
    this.minCaratPerPcs = caratPerPcsMinLimit,
    this.maxCaratPerPcs = caratPerPcsMaxLimit,
    this.minPricePerPcs = pricePerPcsMinLimit,
    this.maxPricePerPcs = pricePerPcsMaxLimit,
    this.minTotalPcs = totalPcsMinLimit,
    this.maxTotalPcs = totalPcsMaxLimit,
    // Deprecated but kept for safety/backward compatibility
    this.minGirdle = 0.0,
    this.maxGirdle = 10.0,
    this.minCulet = 0.0,
    this.maxCulet = 10.0,
  });

  final LabNaturalType labNatural;

  /// Lab-grown catalog only: active category (Lab Diamond / Lab Melee switch).
  final String labCategory;

  /// Lab-grown catalog only: selected growth methods (CVD / HPHT).
  final List<String> selectedGrowthMethods;

  final List<String> shapes;
  final double minPrice;
  final double maxPrice;
  final double minPricePerCarat;
  final double maxPricePerCarat;
  final double minCarat;
  final double maxCarat;
  final List<int> selectedCaratQuickRanges;
  final int minColorIndex;
  final int maxColorIndex;
  final bool isFancyColor;
  final List<String> selectedStandardColors;
  final List<String> selectedFancyColors;
  final List<String> selectedOvertones;
  final List<String> selectedIntensities;
  final bool noBgm;
  final bool eyeClean;
  final int minClarityIndex;
  final int maxClarityIndex;
  final List<String> selectedClarityGrades;
  final List<String> selectedCuts;
  final List<String> selectedFinishPreset;
  final bool heartAndArrow;
  final bool threeEx;
  final bool sellersWithVideo;
  final bool sellersWithImages;
  final bool separable;
  final bool searchByMedia;

  /// Availability labels from [availabilityOptions] (never `'All'`).
  /// Empty = no filter.
  final List<String> selectedAvailabilities;

  /// When true, only listings that allow make-an-offer.
  final bool makeAnOffer;
  final List<String> selectedPolish;
  final List<String> selectedSymmetry;
  final List<String> selectedFluorescence;
  final List<String> selectedFluorescenceColors;
  final List<String> selectedMilkyGrades;
  final List<String> selectedEnhancements;
  final List<String> selectedRoughSources;

  /// Seller companies / locations to include (match any).
  final List<String> companyNames;
  final List<String> vendorLocations;

  /// Seller companies / locations to leave out of results.
  final List<String> excludedCompanyNames;
  final List<String> excludedVendorLocations;
  final List<String> selectedLabs;
  final String? couponCode;
  final double? discountPercentage;
  final bool showAdditionalFilters;
  final double minSellerRating;

  // Upgraded structure advanced filters
  final double minLength;
  final double maxLength;
  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;
  final double minRatio;
  final double maxRatio;
  final double minTable;
  final double maxTable;
  final double minDepth;
  final double maxDepth;
  final double minCrownAngle;
  final double maxCrownAngle;
  final double minCrownHeight;
  final double maxCrownHeight;
  final double minPavilionAngle;
  final double maxPavilionAngle;
  final double minPavilionDepth;
  final double maxPavilionDepth;
  final List<String> selectedGirdles;
  final List<String> selectedCulets;
  final List<String> selectedOrigins;

  // Sieve Size selection
  final List<int> selectedSieveIndices;
  final List<String> activeSievePresets;

  // Natural Melee Pcs range filters
  final double minCaratPerPcs;
  final double maxCaratPerPcs;
  final double minPricePerPcs;
  final double maxPricePerPcs;
  final double minTotalPcs;
  final double maxTotalPcs;

  // Deprecated/Compatibility fields
  final double minGirdle;
  final double maxGirdle;
  final double minCulet;
  final double maxCulet;

  DiamondFilterState copyWith({
    LabNaturalType? labNatural,
    String? labCategory,
    List<String>? selectedGrowthMethods,
    List<String>? shapes,
    double? minPrice,
    double? maxPrice,
    double? minPricePerCarat,
    double? maxPricePerCarat,
    double? minCarat,
    double? maxCarat,
    List<int>? selectedCaratQuickRanges,
    int? minColorIndex,
    int? maxColorIndex,
    bool? isFancyColor,
    List<String>? selectedStandardColors,
    List<String>? selectedFancyColors,
    List<String>? selectedOvertones,
    List<String>? selectedIntensities,
    bool? noBgm,
    bool? eyeClean,
    int? minClarityIndex,
    int? maxClarityIndex,
    List<String>? selectedClarityGrades,
    List<String>? selectedCuts,
    List<String>? selectedFinishPreset,
    bool? heartAndArrow,
    bool? threeEx,
    bool? sellersWithVideo,
    bool? sellersWithImages,
    bool? separable,
    bool? searchByMedia,
    List<String>? selectedAvailabilities,
    bool? makeAnOffer,
    List<String>? selectedPolish,
    List<String>? selectedSymmetry,
    List<String>? selectedFluorescence,
    List<String>? selectedFluorescenceColors,
    List<String>? selectedMilkyGrades,
    List<String>? selectedEnhancements,
    List<String>? selectedRoughSources,
    List<String>? companyNames,
    List<String>? vendorLocations,
    List<String>? excludedCompanyNames,
    List<String>? excludedVendorLocations,
    List<String>? selectedLabs,
    String? couponCode,
    double? discountPercentage,
    bool? showAdditionalFilters,
    double? minSellerRating,
    double? minLength,
    double? maxLength,
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
    double? minRatio,
    double? maxRatio,
    double? minTable,
    double? maxTable,
    double? minDepth,
    double? maxDepth,
    double? minCrownAngle,
    double? maxCrownAngle,
    double? minCrownHeight,
    double? maxCrownHeight,
    double? minPavilionAngle,
    double? maxPavilionAngle,
    double? minPavilionDepth,
    double? maxPavilionDepth,
    List<String>? selectedGirdles,
    List<String>? selectedCulets,
    List<String>? selectedOrigins,
    List<int>? selectedSieveIndices,
    List<String>? activeSievePresets,
    double? minCaratPerPcs,
    double? maxCaratPerPcs,
    double? minPricePerPcs,
    double? maxPricePerPcs,
    double? minTotalPcs,
    double? maxTotalPcs,
    double? minGirdle,
    double? maxGirdle,
    double? minCulet,
    double? maxCulet,
  }) {
    return DiamondFilterState(
      labNatural: labNatural ?? this.labNatural,
      labCategory: labCategory ?? this.labCategory,
      selectedGrowthMethods:
          selectedGrowthMethods ?? this.selectedGrowthMethods,
      shapes: shapes ?? this.shapes,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minPricePerCarat: minPricePerCarat ?? this.minPricePerCarat,
      maxPricePerCarat: maxPricePerCarat ?? this.maxPricePerCarat,
      minCarat: minCarat ?? this.minCarat,
      maxCarat: maxCarat ?? this.maxCarat,
      selectedCaratQuickRanges:
          selectedCaratQuickRanges ?? this.selectedCaratQuickRanges,
      minColorIndex: minColorIndex ?? this.minColorIndex,
      maxColorIndex: maxColorIndex ?? this.maxColorIndex,
      isFancyColor: isFancyColor ?? this.isFancyColor,
      selectedStandardColors:
          selectedStandardColors ?? this.selectedStandardColors,
      selectedFancyColors: selectedFancyColors ?? this.selectedFancyColors,
      selectedOvertones: selectedOvertones ?? this.selectedOvertones,
      selectedIntensities: selectedIntensities ?? this.selectedIntensities,
      noBgm: noBgm ?? this.noBgm,
      eyeClean: eyeClean ?? this.eyeClean,
      minClarityIndex: minClarityIndex ?? this.minClarityIndex,
      maxClarityIndex: maxClarityIndex ?? this.maxClarityIndex,
      selectedClarityGrades:
          selectedClarityGrades ?? this.selectedClarityGrades,
      selectedCuts: selectedCuts ?? this.selectedCuts,
      selectedFinishPreset: selectedFinishPreset ?? this.selectedFinishPreset,
      heartAndArrow: heartAndArrow ?? this.heartAndArrow,
      threeEx: threeEx ?? this.threeEx,
      sellersWithVideo: sellersWithVideo ?? this.sellersWithVideo,
      sellersWithImages: sellersWithImages ?? this.sellersWithImages,
      separable: separable ?? this.separable,
      searchByMedia: searchByMedia ?? this.searchByMedia,
      selectedAvailabilities:
          selectedAvailabilities ?? this.selectedAvailabilities,
      makeAnOffer: makeAnOffer ?? this.makeAnOffer,
      selectedPolish: selectedPolish ?? this.selectedPolish,
      selectedSymmetry: selectedSymmetry ?? this.selectedSymmetry,
      selectedFluorescence: selectedFluorescence ?? this.selectedFluorescence,
      selectedFluorescenceColors:
          selectedFluorescenceColors ?? this.selectedFluorescenceColors,
      selectedMilkyGrades: selectedMilkyGrades ?? this.selectedMilkyGrades,
      selectedEnhancements: selectedEnhancements ?? this.selectedEnhancements,
      selectedRoughSources: selectedRoughSources ?? this.selectedRoughSources,
      companyNames: companyNames ?? this.companyNames,
      vendorLocations: vendorLocations ?? this.vendorLocations,
      excludedCompanyNames: excludedCompanyNames ?? this.excludedCompanyNames,
      excludedVendorLocations:
          excludedVendorLocations ?? this.excludedVendorLocations,
      selectedLabs: selectedLabs ?? this.selectedLabs,
      couponCode: couponCode ?? this.couponCode,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      showAdditionalFilters:
          showAdditionalFilters ?? this.showAdditionalFilters,
      minSellerRating: minSellerRating ?? this.minSellerRating,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      minRatio: minRatio ?? this.minRatio,
      maxRatio: maxRatio ?? this.maxRatio,
      minTable: minTable ?? this.minTable,
      maxTable: maxTable ?? this.maxTable,
      minDepth: minDepth ?? this.minDepth,
      maxDepth: maxDepth ?? this.maxDepth,
      minCrownAngle: minCrownAngle ?? this.minCrownAngle,
      maxCrownAngle: maxCrownAngle ?? this.maxCrownAngle,
      minCrownHeight: minCrownHeight ?? this.minCrownHeight,
      maxCrownHeight: maxCrownHeight ?? this.maxCrownHeight,
      minPavilionAngle: minPavilionAngle ?? this.minPavilionAngle,
      maxPavilionAngle: maxPavilionAngle ?? this.maxPavilionAngle,
      minPavilionDepth: minPavilionDepth ?? this.minPavilionDepth,
      maxPavilionDepth: maxPavilionDepth ?? this.maxPavilionDepth,
      selectedGirdles: selectedGirdles ?? this.selectedGirdles,
      selectedCulets: selectedCulets ?? this.selectedCulets,
      selectedOrigins: selectedOrigins ?? this.selectedOrigins,
      selectedSieveIndices: selectedSieveIndices ?? this.selectedSieveIndices,
      activeSievePresets: activeSievePresets ?? this.activeSievePresets,
      minCaratPerPcs: minCaratPerPcs ?? this.minCaratPerPcs,
      maxCaratPerPcs: maxCaratPerPcs ?? this.maxCaratPerPcs,
      minPricePerPcs: minPricePerPcs ?? this.minPricePerPcs,
      maxPricePerPcs: maxPricePerPcs ?? this.maxPricePerPcs,
      minTotalPcs: minTotalPcs ?? this.minTotalPcs,
      maxTotalPcs: maxTotalPcs ?? this.maxTotalPcs,
      minGirdle: minGirdle ?? this.minGirdle,
      maxGirdle: maxGirdle ?? this.maxGirdle,
      minCulet: minCulet ?? this.minCulet,
      maxCulet: maxCulet ?? this.maxCulet,
    );
  }
}
