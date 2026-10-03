import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../luxe/luxe_dropdown_field.dart';
import 'filter_section_header.dart';

/// Localized label for an availability filter value ("All", "On Memo", …).
String catalogAvailabilityLabel(BuildContext context, String option) {
  return switch (option) {
    'All' => context.tr(RemainingL10n.all),
    'Available' => context.tr(CatalogL10n.available),
    'On Memo' => context.tr(CatalogL10n.onMemo),
    'On Hold' => context.tr(CatalogL10n.onHold),
    'Sold' => context.tr(CatalogL10n.sold),
    _ => option,
  };
}

/// "Availability" heading plus a dropdown of the catalog's options; shared
/// by every catalog filter screen.
class CatalogAvailabilityFilter extends StatelessWidget {
  const CatalogAvailabilityFilter({
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterSectionHeader(title: context.tr(CatalogL10n.availability)),
        const SizedBox(height: 8),
        LuxeDropdownField<String>(
          value: value,
          items: [
            for (final opt in options)
              DropdownMenuItem(
                value: opt,
                child: Text(catalogAvailabilityLabel(context, opt)),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
