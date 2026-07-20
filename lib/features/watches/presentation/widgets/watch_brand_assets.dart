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
      'Rolex' => 'public/images/watch_logo/Rolex Logo.png',
      'Patek Philippe' => 'public/images/watch_logo/Patek-Philippe-Logo.png',
      'Audemars Piguet' => 'public/images/watch_logo/Audemars-Piguet.png',
      'Cartier' => 'public/images/watch_logo/Cartier.png',
      'Omega' => 'public/images/watch_logo/Omega-Logo.png',
      'Hublot' => 'public/images/watch_logo/Hublot-Logo.png',
      'Richard Mille' => 'public/images/watch_logo/Richard_Mille_Logo.png',
      'TAG Heuer' => 'public/images/watch_logo/TAG-Heuer-Logo.png',
      'Vacheron Constantin' =>
        'public/images/watch_logo/Vacheron-Constantin-Logo.png',
      'Breitling' => 'public/images/watch_logo/Breitling-logo.png',
      'Grand Seiko' => 'public/images/watch_logo/Grand-Seiko-Logo.png',
      _ => null,
    };
  }
}
