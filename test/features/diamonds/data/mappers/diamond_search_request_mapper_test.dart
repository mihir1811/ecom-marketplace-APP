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

    test('maps availability and make-an-offer filters', () {
      final body = DiamondSearchRequestMapper.toBody(
        filters: const DiamondFilterState(
          selectedAvailabilities: ['On Hold'],
          makeAnOffer: true,
        ),
        catalog: DiamondCatalogType.natural,
        page: 1,
      );

      expect(body['available'], 'hold');
      expect(body['is_make_an_offer_allowed'], isTrue);
    });

    test('sends excluded companies and locations', () {
      final body = DiamondSearchRequestMapper.toBody(
        filters: const DiamondFilterState(
          excludedCompanyNames: ['Acme Gems'],
          excludedVendorLocations: ['Surat', ' '],
        ),
        catalog: DiamondCatalogType.natural,
        page: 1,
      );

      expect(body['exclude_companies'], ['Acme Gems']);
      expect(body['exclude_locations'], ['Surat']);
      expect(body.containsKey('companies'), isFalse);
    });

    test('omits availability when several statuses are picked', () {
      final body = DiamondSearchRequestMapper.toBody(
        filters: const DiamondFilterState(
          selectedAvailabilities: ['Available', 'On Memo'],
        ),
        catalog: DiamondCatalogType.natural,
        page: 1,
      );

      expect(body.containsKey('available'), isFalse);
    });

    test('omits availability and make-an-offer when unset', () {
      final body = DiamondSearchRequestMapper.toBody(
        filters: const DiamondFilterState(),
        catalog: DiamondCatalogType.natural,
        page: 1,
      );

      expect(body.containsKey('available'), isFalse);
      expect(body.containsKey('is_make_an_offer_allowed'), isFalse);
    });

    test('maps late colors to O-P style pairs from filters API', () {
      final body = DiamondSearchRequestMapper.toBody(
        filters: const DiamondFilterState(
          selectedStandardColors: ['O', 'P', 'Y', 'Z', 'D'],
        ),
        catalog: DiamondCatalogType.natural,
        page: 1,
      );

      expect(body['colors'], containsAll(['O-P', 'Y-Z', 'D']));
      expect(body['colors'], isNot(contains('O')));
      expect(body['colors'], isNot(contains('Y')));
    });

    test(
      'maps enhancement, fancy grey, and rough source to filters API values',
      () {
        final body = DiamondSearchRequestMapper.toBody(
          filters: const DiamondFilterState(
            isFancyColor: true,
            selectedFancyColors: ['Grey', 'Multi'],
            selectedIntensities: ['Fancy Vivid'],
            selectedOvertones: ['Yellowish'],
            selectedEnhancements: ['HPHT (Treatment)', 'None (Treatment)'],
            selectedRoughSources: ['Canadian', 'Russian'],
            selectedOrigins: ['South Africa', 'Botswana'],
            selectedFluorescenceColors: ['Blue', 'None'],
            selectedFluorescence: ['Very Strong'],
          ),
          catalog: DiamondCatalogType.natural,
          page: 1,
        );

        expect(body['fancy_colors'], ['gray', 'other']);
        expect(body['fancy_intensities'], ['fancy vivid']);
        expect(body['fancy_overtones'], ['yellowish']);
        expect(body['treatments'], ['hpht']);
        expect(body['rough_sources'], ['canada', 'russia']);
        expect(body['origins'], ['south africa', 'botswana']);
        expect(body['fluorescence_colors'], ['blue']);
        expect(body['fluorescence'], ['Very Strong']);
      },
    );

    test(
      'sends narrowed length width height and ratio measurement columns',
      () {
        final body = DiamondSearchRequestMapper.toBody(
          filters: const DiamondFilterState(
            minLength: 5,
            maxLength: 6,
            minWidth: 4,
            maxWidth: 5.5,
            minHeight: 3,
            maxHeight: 4,
            minRatio: 1.0,
            maxRatio: 1.1,
          ),
          catalog: DiamondCatalogType.natural,
          page: 1,
        );

        expect(body['length_min'], 5);
        expect(body['length_max'], 6);
        expect(body['width_min'], 4);
        expect(body['width_max'], 5.5);
        expect(body['height_min'], 3);
        expect(body['height_max'], 4);
        expect(body['ratio_min'], 1.0);
        expect(body['ratio_max'], 1.1);
      },
    );

    test('omits measurement keys on full default ranges', () {
      final body = DiamondSearchRequestMapper.toBody(
        filters: const DiamondFilterState(),
        catalog: DiamondCatalogType.natural,
        page: 1,
      );

      expect(body.containsKey('length_min'), isFalse);
      expect(body.containsKey('width_min'), isFalse);
      expect(body.containsKey('height_min'), isFalse);
      expect(body.containsKey('ratio_min'), isFalse);
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

    test('maps treatments and certifications to filters API values', () {
      final body = GemstoneSearchRequestMapper.toBody(
        filters: const GemstoneFilterState(
          selectedTreatments: ['Oiled', 'Heated'],
          selectedCertifications: ['Gübelin', 'Others'],
          selectedOrigin: 'Burma',
        ),
        page: 1,
      );

      expect(body['treatments'], ['Oiling', 'Heated']);
      expect(body['certifications'], ['Gubelin', 'Non-certified']);
      expect(body['origins'], ['Burma (Myanmar)']);
    });

    test('sends narrowed length width height but never ratio', () {
      final body = GemstoneSearchRequestMapper.toBody(
        filters: const GemstoneFilterState(
          minLength: 5,
          maxLength: 10,
          minWidth: 4,
          maxWidth: 8,
          minHeight: 2,
          maxHeight: 6,
          minRatio: 1.0,
          maxRatio: 1.3,
        ),
        page: 1,
      );

      expect(body['length_min'], 5);
      expect(body['length_max'], 10);
      expect(body['width_min'], 4);
      expect(body['width_max'], 8);
      expect(body['height_min'], 2);
      expect(body['height_max'], 6);
      expect(body.containsKey('ratio_min'), isFalse);
      expect(body.containsKey('ratio_max'), isFalse);
    });
  });
}
