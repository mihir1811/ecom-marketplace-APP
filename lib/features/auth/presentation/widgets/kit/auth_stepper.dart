import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations.dart';
import 'auth_tokens.dart';

/// Multi-step progress: "STEP 2 OF 5", a segmented rail that fills as you
/// go, and the current step's title + one-line purpose.
class AuthStepper extends StatelessWidget {
  const AuthStepper({
    super.key,
    required this.current,
    required this.titles,
    required this.hints,
  });

  final int current;
  final List<String> titles;
  final List<String> hints;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final total = titles.length;
    return Semantics(
      container: true,
      liveRegion: true,
      label:
          '${context.tr(AccountCommerceL10n.stepOf, {'current': current + 1, 'total': total})}. '
          '${titles[current]}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.tr(AccountCommerceL10n.stepOf, {
                  'current': current + 1,
                  'total': total,
                }).toUpperCase(),
                style: AuthType.eyebrow(p),
              ),
              const SizedBox(width: AuthSpace.s12),
              Expanded(
                child: Text(
                  titles.length > current + 1 ? '→ ${titles[current + 1]}' : '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AuthType.caption(p),
                ),
              ),
            ],
          ),
          const SizedBox(height: AuthSpace.s12),
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: AuthSpace.s6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        Container(height: 3, color: p.hairline),
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: i <= current ? 1 : 0),
                          duration: AuthMotion.slow,
                          curve: AuthMotion.ease,
                          builder: (context, v, _) => FractionallySizedBox(
                            widthFactor: v,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    p.accent.withValues(alpha: 0.7),
                                    p.accent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AuthSpace.s20),
          AnimatedSwitcher(
            duration: AuthMotion.base,
            switchInCurve: AuthMotion.ease,
            layoutBuilder: (top, rest) =>
                Stack(alignment: Alignment.topLeft, children: [...rest, ?top]),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(current),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titles[current], style: AuthType.title(p)),
                const SizedBox(height: AuthSpace.s4),
                Text(hints[current], style: AuthType.caption(p)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
