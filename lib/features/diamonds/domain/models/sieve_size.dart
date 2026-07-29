class SieveSize {
  final String sieve;
  final double mmMin;
  final double mmMax;
  final double carat;
  final int index;

  const SieveSize({
    required this.sieve,
    required this.mmMin,
    required this.mmMax,
    required this.carat,
    required this.index,
  });

  /// Label expected by `POST /diamond/search` (`sieve_sizes`).
  String get apiLabel => sieve.contains('/') ? sieve.replaceAll('/', ' ') : sieve;

  SieveSize copyWith({
    String? sieve,
    double? mmMin,
    double? mmMax,
    double? carat,
    int? index,
  }) {
    return SieveSize(
      sieve: sieve ?? this.sieve,
      mmMin: mmMin ?? this.mmMin,
      mmMax: mmMax ?? this.mmMax,
      carat: carat ?? this.carat,
      index: index ?? this.index,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SieveSize && runtimeType == other.runtimeType && sieve == other.sieve;

  @override
  int get hashCode => sieve.hashCode;

  /// Labels match the Diamond Filters API sieve catalog.
  static const List<SieveSize> defaultSieves = [
    SieveSize(sieve: '-0000', mmMin: 0.70, mmMax: 0.80, carat: 0.002, index: 0),
    SieveSize(sieve: '+0000 -000', mmMin: 0.80, mmMax: 0.90, carat: 0.003, index: 1),
    SieveSize(sieve: '+000 -00', mmMin: 0.90, mmMax: 1.00, carat: 0.004, index: 2),
    SieveSize(sieve: '+00 -0', mmMin: 1.00, mmMax: 1.10, carat: 0.005, index: 3),
    SieveSize(sieve: '+0 -1', mmMin: 1.10, mmMax: 1.15, carat: 0.006, index: 4),
    SieveSize(sieve: '+1 -1.5', mmMin: 1.15, mmMax: 1.20, carat: 0.007, index: 5),
    SieveSize(sieve: '+1.5 -2', mmMin: 1.20, mmMax: 1.25, carat: 0.008, index: 6),
    SieveSize(sieve: '+2 -2.5', mmMin: 1.25, mmMax: 1.30, carat: 0.009, index: 7),
    SieveSize(sieve: '+2.5 -3', mmMin: 1.30, mmMax: 1.35, carat: 0.010, index: 8),
    SieveSize(sieve: '+3 -3.5', mmMin: 1.35, mmMax: 1.40, carat: 0.011, index: 9),
    SieveSize(sieve: '+3.5 -4', mmMin: 1.40, mmMax: 1.45, carat: 0.012, index: 10),
    SieveSize(sieve: '+4 -4.5', mmMin: 1.45, mmMax: 1.50, carat: 0.013, index: 11),
    SieveSize(sieve: '+4.5 -5', mmMin: 1.50, mmMax: 1.55, carat: 0.014, index: 12),
    SieveSize(sieve: '+5 -5.5', mmMin: 1.55, mmMax: 1.60, carat: 0.015, index: 13),
    SieveSize(sieve: '+5.5 -6', mmMin: 1.60, mmMax: 1.70, carat: 0.018, index: 14),
    SieveSize(sieve: '+6 -6.5', mmMin: 1.70, mmMax: 1.80, carat: 0.021, index: 15),
    SieveSize(sieve: '+6.5 -7', mmMin: 1.80, mmMax: 1.90, carat: 0.025, index: 16),
    SieveSize(sieve: '+7 -7.5', mmMin: 1.90, mmMax: 2.00, carat: 0.029, index: 17),
    SieveSize(sieve: '+7.5 -8', mmMin: 2.00, mmMax: 2.10, carat: 0.035, index: 18),
    SieveSize(sieve: '+8 -8.5', mmMin: 2.10, mmMax: 2.20, carat: 0.038, index: 19),
    SieveSize(sieve: '+8.5 -9', mmMin: 2.20, mmMax: 2.30, carat: 0.045, index: 20),
    SieveSize(sieve: '+9 -9.5', mmMin: 2.30, mmMax: 2.40, carat: 0.050, index: 21),
    SieveSize(sieve: '+9.5 -10', mmMin: 2.40, mmMax: 2.50, carat: 0.058, index: 22),
    SieveSize(sieve: '+10 -10.5', mmMin: 2.50, mmMax: 2.60, carat: 0.066, index: 23),
    SieveSize(sieve: '+10.5 -11', mmMin: 2.60, mmMax: 2.70, carat: 0.070, index: 24),
    SieveSize(sieve: '+11 -11.5', mmMin: 2.70, mmMax: 2.80, carat: 0.077, index: 25),
    SieveSize(sieve: '+11.5 -12', mmMin: 2.80, mmMax: 2.90, carat: 0.086, index: 26),
    SieveSize(sieve: '+12 -12.5', mmMin: 2.90, mmMax: 3.00, carat: 0.094, index: 27),
    SieveSize(sieve: '+12.5 -13', mmMin: 3.00, mmMax: 3.10, carat: 0.103, index: 28),
    SieveSize(sieve: '+13 -13.5', mmMin: 3.10, mmMax: 3.20, carat: 0.119, index: 29),
    SieveSize(sieve: '+13.5 -14', mmMin: 3.20, mmMax: 3.30, carat: 0.131, index: 30),
    SieveSize(sieve: '+14 -14.5', mmMin: 3.30, mmMax: 3.40, carat: 0.144, index: 31),
    SieveSize(sieve: '+14.5 -15', mmMin: 3.40, mmMax: 3.50, carat: 0.158, index: 32),
    SieveSize(sieve: '+15 -15.5', mmMin: 3.50, mmMax: 3.60, carat: 0.170, index: 33),
    SieveSize(sieve: '+15.5 -16', mmMin: 3.60, mmMax: 3.70, carat: 0.180, index: 34),
  ];

  /// Index-based lot type presets: [startIndex, endIndex] inclusive ranges.
  static const Map<String, List<int>> lotTypePresets = {
    '-2': [0, 6],
    'STAR': [7, 15],
    'MELEE': [16, 24],
    '+11': [25, 30],
    '+14': [31, 34],
  };

  /// Returns all sieve indices within [startIdx, endIdx] inclusive.
  static List<int> indicesInRange(int startIdx, int endIdx) {
    return defaultSieves
        .where((s) => s.index >= startIdx && s.index <= endIdx)
        .map((s) => s.index)
        .toList();
  }
}
