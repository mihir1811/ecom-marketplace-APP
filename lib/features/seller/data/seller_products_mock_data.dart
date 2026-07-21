import '../domain/models/seller_product.dart';

const _shapes = [
  'round',
  'princess',
  'tortoise',
  'star',
  'sq cus',
  'oval',
  'cushion',
];
const _colors = ['f', 'e', 'd', 'g', 'h', '—'];
const _clarities = ['vvs1', 'vvs2', 'vs1', 'vs2', 'si1'];

/// Mock catalog size matching reference UI (832 total).
const kSellerProductsMockTotal = 832;

List<SellerProduct> buildSellerProductsMockCatalog() {
  final products = <SellerProduct>[];
  for (var i = 0; i < kSellerProductsMockTotal; i++) {
    final isNatural = i % 5 != 0;
    final isExpired = i % 17 == 0;
    final stock = _stockForIndex(i);
    final carat = (1.2 + (i % 40) * 0.05).toStringAsFixed(2);
    final totalPrice = (100 + (i * 17) % 9000 + (i % 7) * 12.5)
        .toDouble()
        .toStringAsFixed(2);
    final onAuction = i % 11 == 0;
    final sold = i % 23 == 0;

    products.add(
      SellerProduct(
        id: '${1000 + i}',
        sellerId: '42',
        stockNumber: stock,
        isNatural: isNatural,
        isExpired: isExpired,
        isDeleted: false,
        isOnAuction: onAuction,
        isSold: sold,
        fields: {
          'id': '${1000 + i}',
          'seller_id': '42',
          'stock_number': stock,
          'available': 'yes',
          'shape': _shapes[i % _shapes.length],
          'color': _colors[i % _colors.length],
          'clarity': _clarities[i % _clarities.length],
          'carat_weight': carat,
          'measurement': '${(6 + i % 3)}.${i % 10} x ${(6 + i % 2)}.${(i + 3) % 10}',
          'ratio': (1.0 + (i % 5) * 0.01).toStringAsFixed(2),
          'rap': i % 3 == 0 ? '—' : '${120 + i % 80}',
          'discount': i % 4 == 0 ? '—' : '-${(i % 30) + 5}.0%',
          'price_per_carat': (double.parse(totalPrice) / double.parse(carat))
              .toStringAsFixed(2),
          'total_price': totalPrice,
          'cut': i % 2 == 0 ? 'vg' : '—',
          'symmetry': i % 3 == 0 ? 'ex' : 'vg',
          'polish': 'vg',
          'fluorescence_intensity': 'none',
          'fluorescence_color': '—',
          'certificate_company_name': 'GIA',
          'certificate_number': '${1493962220 + i}',
          'certification': 'GIA',
          'video_url': '—',
          'shade': '—',
          'fancy_color': '—',
          'fancy_intensity': '—',
          'fancy_overtone': '—',
          'origin': '—',
          'comment': '—',
          'table': '${54 + i % 6}',
          'depth': '${60 + i % 4}.${i % 10}',
          'gridle_min': '—',
          'gridle_max': '—',
          'gridle_percentage': '—',
          'crown_height': '—',
          'crown_angle': '—',
          'pavilion_angle': '—',
          'pavilion_depth': '—',
          'culet_size': '—',
          'enhancement': '—',
          'growth_type': '—',
          'laser_inscription': '—',
          'gridle_condition': '—',
          'star_length': '—',
          'culet_condition': '—',
          'inclusions_type': '—',
          'eye_clean': 'yes',
          'bgm': '—',
          'milky': '—',
          'ha': '—',
          'matching_pair_number': '—',
          'rough_source': '—',
          'key_to_symbols': '—',
          'cert_comment': '—',
          'tinge': '—',
          'luster': '—',
          'tags': i % 6 == 0 ? 'featured' : '—',
          'image1': 'placeholder',
          'image2': '—',
          'image3': '—',
          'image4': '—',
          'image5': '—',
          'image6': '—',
          'is_on_auction': onAuction ? 'Yes' : 'No',
          'is_sold': sold ? 'Yes' : 'No',
          'is_expired': isExpired ? 'Expired' : 'Active',
          'is_deleted': 'No',
          'created_at': '1 Jul 2026, 09:${(i % 59).toString().padLeft(2, '0')}',
          'updated_at': '3 Jul 2026, 10:${(i % 59).toString().padLeft(2, '0')}',
          'auction_start_time': onAuction ? '5 Jul 2026, 08:00' : '—',
          'auction_end_time': onAuction ? '12 Jul 2026, 08:00' : '—',
        },
      ),
    );
  }
  return products;
}

String _stockForIndex(int i) {
  const prefixes = ['mt', 'th', 'ab', 'lk', 'zx'];
  final p = prefixes[i % prefixes.length];
  return '$p${500 + i % 200}-${10 + i % 90}';
}
