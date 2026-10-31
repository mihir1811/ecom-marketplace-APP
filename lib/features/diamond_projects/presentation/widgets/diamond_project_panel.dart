import 'package:flutter/material.dart';

import '../../../../core/theme/luxe_tokens.dart';

/// Marks a subtree whose [DiamondProjectPanel]s already sit inside a card:
/// they then drop their own border, fill and padding.
class DiamondProjectPanelFlush extends InheritedWidget {
  const DiamondProjectPanelFlush({required super.child, super.key});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DiamondProjectPanelFlush>() !=
      null;

  @override
  bool updateShouldNotify(DiamondProjectPanelFlush oldWidget) => false;
}

/// Shared luxe card chrome for diamond project analytics.
class DiamondProjectPanel extends StatelessWidget {
  const DiamondProjectPanel({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 18),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final flush = DiamondProjectPanelFlush.of(context);
    return Container(
      decoration: flush
          ? null
          : BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(LuxeSpace.radius),
              border: Border.all(color: p.hairline),
            ),
      padding: flush ? EdgeInsets.zero : padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: LuxeType.display(21, p.ink)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: LuxeType.label(p.inkMuted, size: 12),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
