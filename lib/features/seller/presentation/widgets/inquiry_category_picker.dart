import 'package:flutter/material.dart';

import '../../domain/models/seller_inquiry.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_theme.dart';

/// Step-1 category tiles that load the matching inquiry form.
class InquiryCategoryPicker extends StatelessWidget {
  const InquiryCategoryPicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final InquiryCategory? selected;
  final ValueChanged<InquiryCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final columns = maxW >= 620 ? 5 : 3;
        const gap = AtelierSpace.s10;
        final tileW = (maxW - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final category in InquiryCategory.values)
              SizedBox(
                width: tileW,
                child: _CategoryTile(
                  category: category,
                  selected: selected == category,
                  onTap: () => onSelected(category),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final InquiryCategory category;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (category) {
    InquiryCategory.diamond => Icons.diamond_outlined,
    InquiryCategory.gemstone => Icons.auto_awesome_outlined,
    InquiryCategory.bullion => Icons.toll_outlined,
    InquiryCategory.watch => Icons.watch_outlined,
    InquiryCategory.jewelry => Icons.workspace_premium_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final fg = selected ? p.gold : p.inkSoft;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        haptic: false,
        semanticLabel: category.label,
        borderRadius: BorderRadius.circular(AtelierRadius.md),
        child: AnimatedContainer(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          padding: const EdgeInsets.fromLTRB(10, 18, 10, 14),
          decoration: BoxDecoration(
            color: selected ? p.goldSoft : p.surface,
            borderRadius: BorderRadius.circular(AtelierRadius.md),
            border: Border.all(
              color: selected ? p.gold : p.hairline,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected ? null : p.softShadow,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: AnimatedContainer(
                      duration: AtelierMotion.base,
                      curve: AtelierMotion.emphasized,
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? p.surface
                            : p.gold.withValues(alpha: p.isDark ? 0.12 : 0.07),
                        border: Border.all(
                          color: p.gold.withValues(alpha: selected ? 0.5 : 0.2),
                        ),
                      ),
                      child: Icon(_icon, size: 20, color: fg),
                    ),
                  ),
                  const SizedBox(height: AtelierSpace.s10),
                  Text(
                    category.label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.label(
                      selected ? p.ink : p.inkSoft,
                      size: 13,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: -10,
                right: -4,
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: AtelierMotion.base,
                  curve: AtelierMotion.settle,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: p.goldGradient,
                    ),
                    child: Icon(Icons.check_rounded, size: 12, color: p.onGold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
