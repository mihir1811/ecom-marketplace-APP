import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/diamonds/data/mappers/diamond_search_request_mapper.dart';
import 'package:gemstone/features/diamonds/domain/models/diamond_catalog_type.dart';
import 'package:gemstone/features/diamonds/domain/models/diamond_filter_state.dart';
import 'package:gemstone/features/gemstones/data/mappers/gemstone_search_request_mapper.dart';
import 'package:gemstone/features/gemstones/domain/models/gemstone_filter_state.dart';

void main() {
  group('DiamondSearchRequestMapper', () {
    test('includes company and location filters in POST body', () {
      final body = DiamondSearchRequestMapper.toBody(
        filters: const DiamondFilterState(
          companyNames: ['Acme Gems', '  '],
          vendorLocations: ['Surat', 'Mumbai'],
        ),
        catalog: DiamondCatalogType.natural,
        page: 1,
      );

      expect(body['companies'], ['Acme Gems']);
      expect(body['locations'], ['Surat', 'Mumbai']);
    });

    test('omits company and location keys when empty', () {
      final body = DiamondSearchRequestMapper.toBody(
        filters: const DiamondFilterState(),
        catalog: DiamondCatalogType.natural,
        page: 1,
      );

      expect(body.containsKey('companies'), isFalse);
      expect(body.containsKey('locations'), isFalse);
    });
  });

  group('GemstoneSearchRequestMapper', () {
    test('includes company and location filters in POST body', () {
      final body = GemstoneSearchRequestMapper.toBody(
        filters: const GemstoneFilterState(
          companyNames: ['Sattvam'],
          vendorLocations: ['Jaipur'],
        ),
        page: 1,
      );

      expect(body['companies'], ['Sattvam']);
      expect(body['locations'], ['Jaipur']);
    });
  });
}
