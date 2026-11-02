import 'package:flutter/material.dart';

import '../../../../core/theme/luxe_tokens.dart';

/// Shared luxe card chrome for cart blocks, with an optional eyebrow header.
///
/// Uses [Material] (not a colored [DecoratedBox]) so nested [ListTile]s can
/// paint ink/selection on this ancestor without Flutter's visibility assert.
class CartSectionCard extends StatelessWidget {
  const CartSectionCard({
    required this.child,
    super.key,
    this.title,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 12),
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        side: BorderSide(color: p.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: title == null
            ? child
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 16, color: p.accent),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          title!.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.eyebrow(
                            p.inkMuted,
                          ).copyWith(fontSize: 10.5),
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
      ),
    );
  }
}
