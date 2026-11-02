import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/spotlight_models.dart';
import 'spotlight_banner_carousel.dart';
import 'spotlight_impression.dart';
import 'spotlight_product_row.dart';

/// Top of a section's list and search screens: the section's paid banner
/// (CATEGORY_BANNER), then its Sponsored row (CATEGORY_SPONSORED).
///
/// Each part disappears, spacing included, when it has nothing live.
/// Diamond screens pass `sponsoredRow: false` and draw their sponsored
/// stones as result cards instead.
class SpotlightCategoryBlock extends StatefulWidget {
  const SpotlightCategoryBlock({
    required this.category,
    super.key,
    this.gutter = 16,
    this.sponsoredRow = true,
    this.banner = true,
    this.topSpacing = 6,
    this.bottomSpacing = 14,
  });

  final SpotlightCategory category;
  final double gutter;
  final bool sponsoredRow;
  final bool banner;
  final double topSpacing;
  final double bottomSpacing;

  /// Products asked for in the sponsored row.
  static const rowLimit = 8;

  @override
  State<SpotlightCategoryBlock> createState() => _SpotlightCategoryBlockState();
}

class _SpotlightCategoryBlockState extends State<SpotlightCategoryBlock> {
  final _visit = SpotlightVisit();

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.banner)
          SpotlightBannerCarousel(
            query: spotlightQuery(
              SpotlightPlacement.categoryBanner,
              category: c,
            ),
            visit: _visit,
            padding: EdgeInsets.fromLTRB(
              widget.gutter,
              widget.topSpacing,
              widget.gutter,
              widget.bottomSpacing,
            ),
          ),
        if (widget.sponsoredRow)
          SpotlightProductRow(
            query: spotlightQuery(
              SpotlightPlacement.categorySponsored,
              category: c,
              limit: SpotlightCategoryBlock.rowLimit,
            ),
            titleKey: SpotlightL10n.featuredPicks,
            gutter: widget.gutter,
            visit: _visit,
            padding: EdgeInsets.only(
              top: widget.topSpacing,
              bottom: widget.bottomSpacing + 6,
            ),
          ),
      ],
    );
  }
}
