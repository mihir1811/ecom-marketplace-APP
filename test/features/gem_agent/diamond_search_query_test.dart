import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/features/diamonds/data/mappers/diamond_search_request_mapper.dart';
import 'package:gemworld/features/diamonds/domain/models/diamond_active_filters.dart';
import 'package:gemworld/features/diamonds/domain/models/diamond_catalog_type.dart';
import 'package:gemworld/features/diamonds/domain/models/diamond_filter_state.dart';
import 'package:gemworld/features/diamonds/domain/models/diamond_filter_summary.dart';
import 'package:gemworld/features/gem_agent/tools/diamond_search/diamond_search_query.dart';

void main() {
  test('normalizes loose model arguments', () {
    final q = DiamondSearchQuery.parse({
      'origin': 'lab_grown',
      'shapes': ['pear', 'OVAL CUT', 'banana'],
      'carat_min': '1.5',
      'carat_max': 1,
      'colors': ['d', 'E', 'F'],
      'clarities': 'vvs1',
      'growth_methods': ['cvd'],
    });
    expect(q.catalog, DiamondCatalogType.labGrown);
    expect(q.shapes, ['Pear', 'Oval']);
    expect(q.ignored, ['shapes:banana']);
    expect((q.caratMin, q.caratMax), (1.0, 1.5));
    expect(q.colors, ['D', 'E', 'F']);
    expect(q.clarities, ['VVS1']);

    final f = q.toFilters();
    expect(f.labCategory, 'Lab Diamond');
    expect(f.selectedGrowthMethods, ['CVD']);
    expect(f.selectedStandardColors, ['D', 'E', 'F']);
  });

  test('missing or unknown origin is unspecified', () {
    expect(DiamondSearchQuery.parse({}).origin, DiamondOrigin.unspecified);
    expect(
      DiamondSearchQuery.parse({'origin': 'moissanite'}).origin,
      DiamondOrigin.unspecified,
    );
  });

  test('fancy colours switch the finder to fancy mode', () {
    final f = DiamondSearchQuery.parse({
      'origin': 'natural',
      'fancy_colors': ['yellow'],
      'colors': ['D'],
    }).toFilters();
    expect(f.isFancyColor, isTrue);
    expect(f.selectedFancyColors, ['Yellow']);
    expect(f.selectedStandardColors, isEmpty);
  });

  test('applied filters read as value pills with nothing left over', () {
    final f = DiamondSearchQuery.parse({
      'origin': 'natural',
      'shapes': ['Round'],
      'carat': 2,
      'colors': ['D', 'E', 'F'],
      'clarities': ['VS1', 'VS2'],
      'cuts': ['Excellent'],
    }).toFilters();
    final active = DiamondActiveFilters.of(f, formatPrice: (v) => '\$$v');
    expect(active.labels, [
      'Round',
      '2–2.09 ct',
      'D–F',
      'VS1, VS2',
      'Cut: Excellent',
    ]);
    final summary = DiamondFilterSummary.of(f);
    for (final s in DiamondFinderSection.values) {
      expect(summary.count(s) - active.covered(s), 0, reason: s.name);
    }
  });

  test('excluded seller reaches the finder and the request', () {
    final q = DiamondSearchQuery.parse({
      'origin': 'natural',
      'shapes': ['Round'],
      'carat': 2,
      'sellers': ['srk', 'Kiran'],
      'exclude_sellers': [' SRK ', 'SRK'],
      'exclude_seller_locations': ['Mumbai'],
    });
    expect(q.sellers, ['Kiran']);
    expect(q.excludeSellers, ['SRK']);
    expect(q.describe(), contains('excluding SRK'));

    final f = q.toFilters();
    expect(f.companyNames, ['Kiran']);
    expect(f.excludedCompanyNames, ['SRK']);
    expect(f.excludedVendorLocations, ['Mumbai']);
    final body = DiamondSearchRequestMapper.toBody(
      filters: f,
      catalog: q.catalog,
      page: 1,
    );
    expect(body['exclude_companies'], ['SRK']);
    expect(body['companies'], ['Kiran']);
    expect(body['exclude_locations'], ['Mumbai']);
    expect(
      DiamondActiveFilters.of(f, formatPrice: (v) => '$v').labels,
      containsAll(['Seller: Kiran', 'Excl.: SRK', 'Excl.: Mumbai']),
    );
  });

  test('advanced filters map onto the finder', () {
    final q = DiamondSearchQuery.parse({
      'origin': 'natural',
      'fancy_colors': ['Yellow'],
      'fancy_intensities': ['fancy vivid'],
      'fluorescence_colors': ['blue', 'None'],
      'treatments': ['hpht'],
      'mine_countries': ['botswana', 'Atlantis'],
      'rough_sources': ['Russian'],
      'price_per_carat_max': 8000,
      'table_min': 54,
      'table_max': 60,
      'depth_max': 63,
      'ratio_min': 1.3,
      'availability': 'available',
      'with_images': true,
      'make_an_offer': true,
      'min_seller_rating': 4,
    });
    expect(q.ignored, ['fluorescence_colors:None', 'mine_countries:Atlantis']);
    final f = q.toFilters();
    expect(f.isFancyColor, isTrue);
    expect(f.selectedIntensities, ['Fancy Vivid']);
    expect(f.selectedFluorescenceColors, ['Blue']);
    expect(f.selectedEnhancements, ['HPHT (Treatment)']);
    expect(f.selectedOrigins, ['Botswana']);
    expect(f.selectedRoughSources, ['Russian']);
    expect(f.maxPricePerCarat, 8000);
    expect((f.minTable, f.maxTable), (54.0, 60.0));
    expect(f.maxDepth, 63);
    expect(f.minRatio, 1.3);
    expect(f.selectedAvailabilities, ['Available']);
    expect(f.searchByMedia, isTrue);
    expect(f.makeAnOffer, isTrue);
    expect(f.minSellerRating, 4);

    final body = DiamondSearchRequestMapper.toBody(
      filters: f,
      catalog: q.catalog,
      page: 1,
    );
    expect(body['fancy_intensities'], ['fancy vivid']);
    expect(body['treatments'], ['hpht']);
    expect(body['origins'], ['botswana']);
    expect(body['price_per_carat_max'], 8000);
    expect(body['table_min'], 54);
    expect(body['available'], 'yes');
    expect(body['has_image'], isTrue);
    expect(body['is_make_an_offer_allowed'], isTrue);
    expect(body['seller_rating'], '4');
  });

  test('lab-grown drops natural-only filters', () {
    final f = DiamondSearchQuery.parse({
      'origin': 'lab_grown',
      'mine_countries': ['Botswana'],
      'rough_sources': ['Russian'],
    }).toFilters();
    expect(f.selectedOrigins, isEmpty);
    expect(f.selectedRoughSources, isEmpty);
  });

  test('default filters show no pills', () {
    final active = DiamondActiveFilters.of(
      const DiamondFilterState(),
      formatPrice: (v) => '$v',
    );
    expect(active.labels, isEmpty);
  });
}
