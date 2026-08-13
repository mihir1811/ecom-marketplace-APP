import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/buyer/data/mappers/favorite_mapper.dart';

void main() {
  test('bullion card uses metal weight, not stock id or nested id map', () {
    final item = FavoriteMapper.fromJson({
      'id': 'fav-1',
      'productId': 'bullion-1',
      'productType': 'bullion',
      'product': {
        'id': 'bullion-1',
        'stockNumber': 'AU-COIN-MAPLE-003',
        'metalWeight': 31.103,
        'condition': 'uncirculated',
        'price': 2950,
        'metalType': {
          'id': '548a5c47-a6b7-413c-83a7-644141a74c38',
          'name': 'GOLD',
        },
        'metalShape': {'id': 'shape-1', 'name': 'coin'},
      },
    });

    expect(item.title, '1oz Gold');
    expect(item.subtitle, 'Coin · Uncirculated');
    expect(item.title, isNot(contains('AU-COIN')));
    expect(item.subtitle, isNot(contains('id:')));
  });

  test('diamond card uses carat and shape, not stock number', () {
    final item = FavoriteMapper.fromJson({
      'id': 'fav-2',
      'productId': 'diamond-1',
      'productType': 'diamond',
      'product': {
        'id': 'diamond-1',
        'stockNumber': 'gy255-07e',
        'caratWeight': 0.5,
        'shape': 'marquise',
        'color': 'pink',
        'clarity': 'vvs2',
        'growthType': 'natural',
        'totalPrice': 28.6,
      },
    });

    expect(item.title, '0.5ct Marquise');
    expect(item.subtitle, 'Natural · PINK VVS2');
    expect(item.title, isNot('gy255-07e'));
  });

  test('watch card combines brand and model', () {
    final item = FavoriteMapper.fromJson({
      'id': 'fav-3',
      'productId': 'watch-1',
      'productType': 'watch',
      'product': {
        'id': 'watch-1',
        'brand': 'Breitling',
        'model': 'Superocean Automatic 42',
        'modelYear': 2022,
        'caseMaterial': 'steel',
        'price': 3900,
      },
    });

    expect(item.title, 'Breitling Superocean Automatic 42');
    expect(item.subtitle, '2022 · Steel');
  });

  test('jewelry card prefers product title and variant image', () {
    final item = FavoriteMapper.fromJson({
      'id': 'fav-4',
      'productId': 'jewel-1',
      'productType': 'jewellery',
      'product': {
        'id': 'jewel-1',
        'productTitle': 'Platinum Diamond Tennis Bracelet',
        'imageUrl': 'https://example.com/category-ring.png',
        'subcategory': {
          'name': 'Tennis',
          'category': {'name': 'bracelet'},
        },
        'variants': [
          {
            'metalType': 'Platinum',
            'totalPrice': 320000,
            'image1': 'https://example.com/bracelet.png',
          },
        ],
      },
    });

    expect(item.title, 'Platinum Diamond Tennis Bracelet');
    expect(item.subtitle, 'Bracelets · Platinum');
    expect(item.imageUrl, 'https://example.com/bracelet.png');
  });
}
