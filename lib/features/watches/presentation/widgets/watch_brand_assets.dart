/// Maps luxury watch brand names to local logo assets.
class WatchBrandAssets {
  const WatchBrandAssets._();

  static const featuredBrands = [
    'Rolex',
    'Patek Philippe',
    'Audemars Piguet',
    'Cartier',
    'Omega',
    'Hublot',
    'Richard Mille',
    'TAG Heuer',
    'Vacheron Constantin',
    'Breitling',
    'Grand Seiko',
  ];

  static const chipBrands = [
    'Rolex',
    'Patek Philippe',
    'Audemars Piguet',
    'Cartier',
    'Omega',
    'Hublot',
    'Richard Mille',
  ];

  static String? logoPath(String brand) {
    return switch (brand) {
      'Rolex' => 'public/images/watch_logo/Rolex Logo.webp',
      'Patek Philippe' => 'public/images/watch_logo/Patek-Philippe-Logo.webp',
      'Audemars Piguet' => 'public/images/watch_logo/Audemars-Piguet.webp',
      'Cartier' => 'public/images/watch_logo/Cartier.webp',
      'Omega' => 'public/images/watch_logo/Omega-Logo.webp',
      'Hublot' => 'public/images/watch_logo/Hublot-Logo.webp',
      'Richard Mille' => 'public/images/watch_logo/Richard_Mille_Logo.webp',
      'TAG Heuer' => 'public/images/watch_logo/TAG-Heuer-Logo.webp',
      'Vacheron Constantin' =>
        'public/images/watch_logo/Vacheron-Constantin-Logo.webp',
      'Breitling' => 'public/images/watch_logo/Breitling-logo.webp',
      'Grand Seiko' => 'public/images/watch_logo/Grand-Seiko-Logo.webp',
      _ => null,
    };
  }
}
