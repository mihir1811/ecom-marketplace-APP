/// Catalog brand list used by the mock repository (not the A–Z directory).
class WatchCatalogBrands {
  const WatchCatalogBrands._();

  static const catalogBrands = [
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
    'IWC',
    'Tissot',
    'Seiko',
    'Panerai',
  ];

  static const modelsByBrand = <String, List<String>>{
    'Rolex': [
      'Submariner',
      'Yacht-Master II',
      'Daytona',
      'Datejust',
      'GMT-Master II',
    ],
    'Patek Philippe': [
      'Nautilus',
      'Calatrava',
      'Aquanaut',
      'Grand Complications',
    ],
    'Audemars Piguet': ['Royal Oak', 'Royal Oak Offshore', 'Code 11.59'],
    'Cartier': ['Santos de Cartier', 'Tank', 'Ballon Bleu', 'Drive de Cartier'],
    'Omega': [
      'Speedmaster Professional',
      'Seamaster',
      'Constellation',
      'De Ville',
    ],
    'Hublot': ['Big Bang Unico', 'Classic Fusion', 'Spirit of Big Bang'],
    'Richard Mille': ['Skeleton RM-011', 'RM 35-02', 'RM 67-01'],
    'TAG Heuer': ['Carrera', 'Monaco', 'Aquaracer', 'Formula 1'],
    'Vacheron Constantin': ['Overseas', 'Patrimony', 'Historoire'],
    'Breitling': ['Navitimer', 'Superocean', 'Chronomat'],
    'Grand Seiko': ['Snowflake', 'Hibiki', 'Evolution 9'],
    'IWC': ['Pilot', 'Portugieser', 'Aquatimer', 'Ingenieur'],
    'Tissot': ['PRX', 'Gentleman', 'Seastar', 'Chronograph'],
    'Seiko': ['Prospex', 'Presage', '5 Sports'],
    'Panerai': ['Luminor', 'Submersible', 'Radiomir'],
  };
}
