import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/account_commerce_messages.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../application/comparison_provider.dart';
import '../../domain/models/compare_spec.dart';
import '../widgets/comparison_table.dart';

/// Side-by-side comparison — shell only; table owns scroll sync + paint isolation.
class ComparisonScreen extends ConsumerWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(
      comparisonProvider.select(
        (s) =>
            (itemCount: s.items.length, category: s.category, items: s.items),
      ),
    );

    if (snapshot.itemCount < 2 || snapshot.category == null) {
      return AppScaffold(
        appBar: SimpleAppTopBar(title: context.tr(AccountCommerceL10n.compare)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr(AccountCommerceL10n.compareInstruction),
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.s16),
                FilledButton(
                  onPressed: () => context.goBack(),
                  child: Text(context.tr(AccountCommerceL10n.goBack)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final category = snapshot.category!;
    final items = snapshot.items;
    final specs = specsForCategory(category);

    return AppScaffold(
      appBar: AppTopBar(
        title: context.tr(AccountCommerceL10n.compareTitle, {
          'category': context.tr(category.labelPluralKey),
        }),
        extraActions: [
          TextButton(
            onPressed: () {
              ref.read(comparisonProvider.notifier).clear();
              context.goBack();
            },
            child: Text(
              context.tr(AccountCommerceL10n.startNew),
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.bronze,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ComparisonTable(
              items: items,
              specs: specs,
              onRemove: (id) {
                ref.read(comparisonProvider.notifier).remove(id);
                if (ref.read(comparisonProvider).count < 2) {
                  context.goBack();
                }
              },
              onReorder: (oldIndex, newIndex) {
                ref
                    .read(comparisonProvider.notifier)
                    .reorder(oldIndex, newIndex);
              },
            ),
          ),
          ComparisonFooterBar(
            count: items.length,
            labelPlural: category.labelPlural,
            onBrowse: () => context.goBack(),
            onClear: () {
              ref.read(comparisonProvider.notifier).clear();
              context.goBack();
            },
          ),
        ],
      ),
    );
  }
}
