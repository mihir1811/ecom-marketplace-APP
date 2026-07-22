/// Product category allowed in a single comparison session.
enum CompareCategory {
  diamond,
  gemstone,
  watch;

  String get label => switch (this) {
        CompareCategory.diamond => 'diamond',
        CompareCategory.gemstone => 'gemstone',
        CompareCategory.watch => 'watch',
      };

  String get labelPlural => switch (this) {
        CompareCategory.diamond => 'diamonds',
        CompareCategory.gemstone => 'gemstones',
        CompareCategory.watch => 'watches',
      };
}
