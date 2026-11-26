import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_tokens.dart';

/// One small line under the checkout summary, on every cart whatever the
/// setting: sellers may see this cart after an hour. Manage opens the switch
/// in Settings.
class CartOutreachNotice extends StatelessWidget {
  const CartOutreachNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final style = LuxeType.body(p.inkMuted, size: 12);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.visibility_outlined, size: 14, color: p.inkFaint),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: context.tr(InterestedBuyersL10n.cartNotice)),
                  const TextSpan(text: ' '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: Semantics(
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            context.openRoute(AppRouteNames.buyerSettings),
                        child: Text(
                          context.tr(InterestedBuyersL10n.manage),
                          style: style.copyWith(
                            color: p.accent,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: p.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
