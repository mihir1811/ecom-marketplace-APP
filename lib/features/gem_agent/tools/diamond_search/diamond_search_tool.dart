import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../diamonds/application/diamond_results_handoff.dart';
import '../../../diamonds/data/repositories/diamond_repository_impl.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../../../diamonds/domain/models/diamond_catalog_type.dart';
import '../../../diamonds/domain/models/diamond_filter_state.dart';
import '../../../diamonds/domain/repositories/diamond_repository.dart';
import '../../domain/agent_effect.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../catalog/catalog_args.dart';
import '../catalog/origin_slot.dart';
import 'diamond_search_query.dart';

/// Searches the natural or lab-grown diamond catalog with the user's
/// filters, then opens the results screen already holding the first page.
///
/// Origin is a hard requirement: without it, no API call is made.
class DiamondSearchTool extends AgentTool {
  const DiamondSearchTool();

  @override
  String get name => 'search_diamonds';

  @override
  String get description =>
      'Search loose diamonds and open the results screen. Requires origin '
      '(natural or lab-grown). Use for any request to find, show or browse '
      'diamonds.';

  @override
  Map<String, Object?> get parameters {
    Map<String, Object?> list(List<String> values, String hint) => {
      'type': 'array',
      'items': {'type': 'string', 'enum': values},
      'description': hint,
    };
    return {
      'type': 'object',
      'properties': {
        'origin': {
          'type': 'string',
          'enum': ['natural', 'lab_grown', 'unspecified'],
          'description':
              'natural = earth-mined; lab_grown = lab/CVD/HPHT. '
              '"unspecified" unless the user said it.',
        },
        'shapes': list(DiamondSearchQuery.shapeNames, 'Requested shapes.'),
        'carat': {
          'type': 'number',
          'description': 'One stated weight, e.g. 2 for "2 carat".',
        },
        'carat_min': {'type': 'number'},
        'carat_max': {'type': 'number'},
        'colors': list(
          DiamondFilterState.colors,
          'White colour grades, expanded (D to F → D,E,F).',
        ),
        'fancy_colors': list(
          DiamondSearchQuery.fancyColorNames,
          'Fancy colours (yellow, pink…).',
        ),
        'clarities': list(DiamondFilterState.clarities, 'Clarity grades.'),
        'cuts': list(DiamondFilterState.cuts, 'Cut grades.'),
        'polish': list(DiamondFilterState.polishingGrades, 'Polish grades.'),
        'symmetry': list(DiamondFilterState.symmetryGrades, 'Symmetry grades.'),
        'fluorescence': list(
          DiamondFilterState.fluorescenceGrades,
          'Fluorescence.',
        ),
        'labs': list(DiamondFilterState.labs, 'Grading labs.'),
        'growth_methods': list(
          DiamondFilterState.growthMethods,
          'Lab-grown only.',
        ),
        'price_min': {'type': 'number', 'description': 'Total price, USD.'},
        'price_max': {'type': 'number', 'description': 'Total price, USD.'},
        'melee': {
          'type': 'boolean',
          'description':
              'True only if the user asked for melee / small parcels.',
        },
        'fancy_intensities': list(
          DiamondFilterState.intensities,
          'Fancy colour intensity ("vivid" → Fancy Vivid).',
        ),
        'fancy_overtones': list(
          DiamondFilterState.overtones,
          'Secondary hue ("pinkish", "greenish").',
        ),
        'fluorescence_colors': list(
          DiamondSearchQuery.fluorescenceColorNames,
          'Fluorescence colour.',
        ),
        'treatments': list(
          DiamondSearchQuery.treatmentNames.keys.toList(),
          'Only treated stones of these kinds.',
        ),
        'mine_countries': textList(
          'Natural only: country the rough was mined in (Botswana, Russia).',
        ),
        'rough_sources': list(
          DiamondSearchQuery.roughSourceNames,
          'Natural only: rough source.',
        ),
        'price_per_carat_min': numberField('USD per carat.'),
        'price_per_carat_max': numberField('USD per carat.'),
        'length_min': numberField('mm.'),
        'length_max': numberField('mm.'),
        'width_min': numberField('mm.'),
        'width_max': numberField('mm.'),
        'height_min': numberField('mm.'),
        'height_max': numberField('mm.'),
        'ratio_min': numberField('Length/width ratio.'),
        'ratio_max': numberField('Length/width ratio.'),
        'table_min': numberField('Table %.'),
        'table_max': numberField('Table %.'),
        'depth_min': numberField('Depth %.'),
        'depth_max': numberField('Depth %.'),
        'girdles': list(DiamondFilterState.girdles, 'Girdle thickness.'),
        'culets': list(DiamondFilterState.culets, 'Culet size.'),
        ...sellerFields(),
        'min_seller_rating': numberField('Seller stars, 1–5.'),
        'with_images': flagField('Only listings with photos.'),
        ...listingFields(),
      },
      'required': ['origin'],
      'additionalProperties': false,
    };
  }

  @override
  String get promptGuidance => '''
Required: origin. If the user has not said natural or lab-grown, call ask_user ("Natural or lab-grown diamond?", options ["Natural","Lab-grown"]) and wait. Never assume natural.
Include only filters the user stated:
- "2 carat" → carat 2; "over 2" → carat_min 2; "under 1" → carat_max 1; "1 to 1.5" → carat_min 1, carat_max 1.5.
- Colour: list every grade in a range ("D to F" → D,E,F). "colorless" → D,E,F; "near colorless" → G,H,I,J. Coloured stones ("yellow", "pink") → fancy_colors.
- Clarity families: "VVS" → VVS1,VVS2; "VS" → VS1,VS2; "SI" → SI1,SI2.
- "3EX"/"triple excellent" → cuts, polish, symmetry = Excellent.
- Price is the stone total in USD; "per carat" prices → price_per_carat_min/max.
- Seller / company / supplier / vendor names → sellers. "except SRK", "not from SRK", "SRK sivay", "SRK sivayna", "SRK ke alava", "SRK chhodke", "SRK vagar" → exclude_sellers ["SRK"]. Send the bare name ("SRK", not "seller SRK").
- Seller city or country ("Surat sellers", "not from Mumbai") → seller_locations / exclude_seller_locations. Mine country ("Russian diamond", "Botswana origin") → mine_countries.
- "untreated"/"no treatment" → leave treatments out. "4 star sellers" → min_seller_rating 4. "with photos" → with_images. "in stock" → availability "Available". "negotiable"/"can make an offer" → make_an_offer.
- "no fluorescence" → fluorescence ["None"]. "vivid yellow" → fancy_colors ["Yellow"], fancy_intensities ["Fancy Vivid"].
Examples:
"find me a 2 carat round diamond" → ask_user (origin missing)
then "natural" → search_diamonds {"origin":"natural","shapes":["Round"],"carat":2}
"seller srk sivay na 2 carat round natural diamond batavo" → search_diamonds {"origin":"natural","shapes":["Round"],"carat":2,"exclude_sellers":["SRK"]}
"1 carat oval natural diamond from Surat sellers except Kiran, GIA, no fluorescence" → search_diamonds {"origin":"natural","shapes":["Oval"],"carat":1,"seller_locations":["Surat"],"exclude_sellers":["Kiran"],"labs":["GIA"],"fluorescence":["None"]}
"lab grown pear 1 to 1.5 carat D-F VVS" → search_diamonds {"origin":"lab_grown","shapes":["Pear"],"carat_min":1,"carat_max":1.5,"colors":["D","E","F"],"clarities":["VVS1","VVS2"]}''';

  @override
  String progressLabel(Map<String, Object?> args) {
    final origin = DiamondOrigin.parse(args['origin']);
    return switch (origin) {
      DiamondOrigin.labGrown => 'Searching lab-grown diamonds…',
      DiamondOrigin.natural => 'Searching natural diamonds…',
      DiamondOrigin.unspecified => 'Checking your request…',
    };
  }

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    final query = DiamondSearchQuery.parse(args);
    final hold = StoneOrigin.require(
      query.origin == DiamondOrigin.unspecified
          ? StoneOrigin.unspecified
          : StoneOrigin.natural,
      context.userUtterances,
      noun: 'diamond',
    );
    if (hold != null) return hold;

    final filters = query.toFilters();
    final result = await context.ref
        .read(diamondRepositoryProvider)
        .getDiamonds(
          filters: filters,
          catalog: query.catalog,
          page: 1,
          pageSize: DiamondPageSize.defaultSize,
          cancelToken: context.cancelToken,
        );

    switch (result) {
      case ResultFailure(failure: final failure):
        return ToolFailure(
          failure is NetworkFailure && failure.isCancelled
              ? 'Cancelled.'
              : failure.message,
        );
      case Success(value: final page):
        final total = page.totalCount > 0
            ? page.totalCount
            : page.diamonds.length;
        final label = query.describe();
        return ToolSuccess(
          summary: total == 0
              ? 'No exact matches for $label. Opened results so you can adjust.'
              : 'Found $total ${total == 1 ? 'diamond' : 'diamonds'} · $label',
          data: {
            'total': total,
            'applied_filters': query.toJson(),
            if (query.ignored.isNotEmpty) 'ignored_values': query.ignored,
          },
          effects: [
            _PresentDiamondResults(
              catalog: query.catalog,
              filters: filters,
              page: page,
            ),
          ],
          completesTurn: true,
        );
    }
  }
}

/// Hands the fetched page to the diamonds feature, then opens its results.
class _PresentDiamondResults extends AgentEffect {
  const _PresentDiamondResults({
    required this.catalog,
    required this.filters,
    required this.page,
  });

  final DiamondCatalogType catalog;
  final DiamondFilterState filters;
  final DiamondListResponse page;

  @override
  Future<void> apply(Ref ref) async {
    publishDiamondResultsHandoff(
      ref,
      DiamondResultsHandoff(
        catalog: catalog,
        filters: filters,
        firstPage: page,
      ),
    );
    // Lab-grown state lives in its shell route's scope; `go` keeps that
    // scope alive when the user taps Edit filters.
    await NavigateEffect(
      catalog.isLabGrown
          ? AppRouteNames.labGrownDiamondResults
          : AppRouteNames.diamondResults,
      replaceStack: catalog.isLabGrown,
    ).apply(ref);
  }
}
