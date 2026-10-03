import 'package:flutter/widgets.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/models/bullions_filter_summary.dart';

/// Display title of a bullion filter section.
String bullionSectionTitle(BuildContext context, BullionsFilterSection s) =>
    context.tr(switch (s) {
      BullionsFilterSection.formWeight => CatalogFlowL10n.sectionFormWeight,
      BullionsFilterSection.price => CatalogFlowL10n.sectionPrice,
      BullionsFilterSection.quantity => CatalogFlowL10n.sectionQuantity,
      BullionsFilterSection.provenance => CatalogFlowL10n.sectionProvenance,
      BullionsFilterSection.listing => DiamondFlowL10n.sectionListing,
      BullionsFilterSection.dimensions => DiamondFlowL10n.sectionMeasurements,
    });
