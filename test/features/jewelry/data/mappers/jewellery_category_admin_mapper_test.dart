import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/jewelry/data/mappers/jewellery_category_admin_mapper.dart';
import 'package:gemstone/features/jewelry/domain/models/jewellery_category_admin.dart';
import 'package:gemstone/features/jewelry/domain/models/jewelry_filter_state.dart';

void main() {
  test('list page reads nested data.data and meta.next', () {
    final page = JewelleryCategoryAdminMapper.listPageFromJson(
      {
        'success': true,
        'message': 'Categories fetched successfully.',
        'data': {
          'data': [
            {
              'id': '3b35026f-34d3-4a4d-9d06-26678b5a2779',
              'name': 'Ring',
              'imageUrl': '/images/jewelryCategoryImages/ring.png',
              'isActive': true,
              'subcategories': [
                {
                  'id': 'c0a4f879-fa9c-41d9-811c-539ef7060feb',
                  'name': 'Engagement Ring',
                  'categoryId': '3b35026f-34d3-4a4d-9d06-26678b5a2779',
                  'imageUrl': null,
                  'isActive': true,
                },
              ],
            },
            {
              'id': 'inactive-1',
              'name': 'GwDocProbe',
              'isActive': false,
              'subcategories': <Map<String, dynamic>>[],
            },
          ],
          'meta': {
            'total': 4,
            'currentPage': 1,
            'perPage': 2,
            'lastPage': 2,
            'prev': null,
            'next': 2,
          },
        },
      },
      page: 1,
      limit: 2,
    );

    expect(page.items.length, 2);
    expect(page.items.first.name, 'Ring');
    expect(page.items.first.subcategories.single.name, 'Engagement Ring');
    expect(page.items.last.isActive, isFalse);
    expect(page.hasMore, isTrue);
    expect(page.total, 4);
  });

  test('get-one envelope maps category entity from data', () {
    final category = JewelleryCategoryAdminMapper.categoryFromResponse({
      'success': true,
      'message': 'Category fetched successfully.',
      'data': {
        'id': 'cat-1',
        'name': 'Bracelet',
        'isActive': true,
        'subcategories': [
          {
            'id': 'sub-1',
            'name': 'Bangle',
            'categoryId': 'cat-1',
            'isActive': true,
          },
        ],
      },
    });

    expect(category?.id, 'cat-1');
    expect(category?.name, 'Bracelet');
    expect(category?.subcategories.single.id, 'sub-1');
  });

  test('add-subcategory envelope maps subcategory, ignoring nested category', () {
    final sub = JewelleryCategoryAdminMapper.subcategoryFromResponse({
      'success': true,
      'message': 'Subcategory added successfully.',
      'data': {
        'id': 'sub-2',
        'name': 'Cuff',
        'categoryId': 'cat-1',
        'isActive': true,
        'category': {'id': 'cat-1', 'name': 'Bracelet'},
      },
    });

    expect(sub?.id, 'sub-2');
    expect(sub?.name, 'Cuff');
    expect(sub?.categoryId, 'cat-1');
  });

  test('UI plurals resolve to live API category names', () {
    const items = [
      JewelleryCategoryAdmin(id: '1', name: 'Ring', isActive: true),
      JewelleryCategoryAdmin(id: '2', name: 'Bracelet', isActive: true),
    ];

    expect(JewelleryCategoryMatch.apiNameForUi('Rings'), 'Ring');
    expect(JewelleryCategoryMatch.find(items, 'Rings')?.id, '1');
    expect(JewelleryCategoryMatch.find(items, 'Bracelets')?.name, 'Bracelet');
    expect(JewelleryCategoryMatch.find(items, 'All Accessories'), isNull);
    expect(JewelryFilterState.parentCategoryOrDefault('Ring'), 'Rings');
    expect(JewelryFilterState.parentCategoryOrDefault('Earring'), 'Earrings');
  });
}
