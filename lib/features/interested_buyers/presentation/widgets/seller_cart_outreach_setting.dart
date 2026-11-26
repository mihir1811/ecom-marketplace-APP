import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/interested_buyers_providers.dart';

/// Buyer privacy switch "Seller offers on my cart", on by default. Off hides
/// the buyer from every seller's Interested buyers list at once.
class SellerCartOutreachSetting extends ConsumerWidget {
  const SellerCartOutreachSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final pref = ref.watch(sellerCartOutreachProvider);
    final value = pref.asData?.value ?? true;
    final loading = pref.isLoading && !pref.hasValue;
    final title = context.tr(InterestedBuyersL10n.settingTitle);

    Future<void> toggle(bool next) async {
      AppHaptics.selection();
      final failedText = context.tr(InterestedBuyersL10n.settingSaveFailed);
      final ok = await ref.read(sellerCartOutreachProvider.notifier).set(next);
      if (!ok && context.mounted) {
        AppHaptics.error();
        showAtelierToast(context, failedText, tone: AtelierTone.ruby);
      }
    }

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(shape: BoxShape.circle, color: p.sunken),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 18,
                color: p.inkSoft,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AtelierType.label(p.ink, size: 14)),
                  const SizedBox(height: 3),
                  Text(
                    context.tr(InterestedBuyersL10n.settingBody),
                    style: AtelierType.caption(p.muted, size: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Switch.adaptive(
              value: value,
              activeTrackColor: p.gold,
              onChanged: loading ? null : toggle,
            ),
          ],
        ),
      ),
    );
  }
}
