enum ChatProductType {
  diamond('diamond'),
  gemstone('gemstone'),
  meleeDiamond('meleeDiamond'),
  jewellery('jewellery'),
  watch('watch'),
  bullion('bullion');

  const ChatProductType(this.apiValue);

  final String apiValue;

  static ChatProductType? fromApi(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final key = raw.trim();
    for (final value in ChatProductType.values) {
      if (value.apiValue == key) return value;
    }
    return null;
  }

  String get label => switch (this) {
        ChatProductType.diamond => 'Diamond',
        ChatProductType.gemstone => 'Gemstone',
        ChatProductType.meleeDiamond => 'Melee',
        ChatProductType.jewellery => 'Jewellery',
        ChatProductType.watch => 'Watch',
        ChatProductType.bullion => 'Bullion',
      };
}
