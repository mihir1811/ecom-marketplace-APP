import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../theme/home_tokens.dart';

/// Catalogue search ⇄ AI Mode. A capsule glides to the active mode; AI Mode
/// keeps its gold sparkle so it reads as Gem AI even while inactive.
class HomeSearchModeSwitch extends StatelessWidget {
  const HomeSearchModeSwitch({
    required this.aiMode,
    required this.onChanged,
    super.key,
  });

  final bool aiMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return SizedBox(
      width: double.infinity,
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: ShapeDecoration(
          color: palette.surface,
          shape: StadiumBorder(side: BorderSide(color: palette.hairline)),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: HomeMotion.medium,
              curve: HomeMotion.settle,
              alignment: aiMode
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: AnimatedContainer(
                  duration: HomeMotion.medium,
                  curve: HomeMotion.settle,
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: aiMode ? HomeStage.obsidian : palette.ink,
                    shadows: [
                      BoxShadow(
                        color: HomeStage.gold.withValues(
                          alpha: aiMode ? 0.28 : 0,
                        ),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _ModeSegment(
                    label: context.tr(HomeL10n.searchModeCatalog),
                    icon: Icons.search_rounded,
                    selected: !aiMode,
                    selectedColor: palette.canvas,
                    idleColor: palette.inkMuted,
                    onTap: () => onChanged(false),
                  ),
                ),
                Expanded(
                  child: _ModeSegment(
                    label: context.tr(HomeL10n.aiMode),
                    icon: Icons.auto_awesome_rounded,
                    selected: aiMode,
                    selectedColor: HomeStage.gold,
                    idleColor: palette.accent,
                    onTap: () => onChanged(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.idleColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final Color idleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : idleColor;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 5),
                AnimatedDefaultTextStyle(
                  duration: HomeMotion.medium,
                  style: HomeType.label(color),
                  child: Text(label, maxLines: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// AI Mode's resting state: one ready-made ask per catalogue world.
class HomeAiModeSuggestions extends StatelessWidget {
  const HomeAiModeSuggestions({
    required this.animate,
    required this.onAsk,
    super.key,
  });

  final bool animate;
  final ValueChanged<String> onAsk;

  static const _prompts = <(String, IconData, String)>[
    (
      RemainingL10n.naturalDiamonds,
      Icons.diamond_outlined,
      HomeL10n.aiModePromptDiamonds,
    ),
    (
      RemainingL10n.gemstones,
      Icons.spa_outlined,
      HomeL10n.aiModePromptGemstones,
    ),
    (
      RemainingL10n.jewelry,
      Icons.workspace_premium_outlined,
      HomeL10n.aiModePromptJewellery,
    ),
    (RemainingL10n.watches, Icons.watch_outlined, HomeL10n.aiModePromptWatches),
    (
      RemainingL10n.bullion,
      Icons.view_module_outlined,
      HomeL10n.aiModePromptBullion,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text(
          context.tr(ExperienceL10n.aiTryAsking).toUpperCase(),
          style: HomeType.eyebrow(palette.inkMuted),
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < _prompts.length; i++)
          _maybeAnimate(
            HomeSearchPromptRow(
              topic: context.tr(_prompts[i].$1),
              icon: _prompts[i].$2,
              prompt: context.tr(_prompts[i].$3),
              onTap: () => onAsk(context.tr(_prompts[i].$3)),
            ),
            i,
          ),
      ],
    );
  }

  Widget _maybeAnimate(Widget child, int i) {
    if (!animate) return child;
    return child
        .animate(delay: (60 + i * 50).ms)
        .fadeIn(duration: 380.ms)
        .moveY(begin: -14, end: 0, duration: 600.ms, curve: HomeMotion.settle);
  }
}

/// One suggested search: topic eyebrow, the query, and a north-east arrow.
class HomeSearchPromptRow extends StatelessWidget {
  const HomeSearchPromptRow({
    required this.topic,
    required this.icon,
    required this.prompt,
    required this.onTap,
    this.showDivider = true,
    super.key,
  });

  final String topic;
  final IconData icon;
  final String prompt;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: showDivider
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: palette.hairline, width: 0.8),
                ),
              )
            : null,
        child: Row(
          children: [
            Icon(icon, size: 20, color: palette.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HomeType.eyebrow(
                      palette.inkFaint,
                    ).copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(prompt, style: HomeType.body(palette.ink, size: 15)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.north_east_rounded, size: 18, color: palette.accent),
          ],
        ),
      ),
    );
  }
}
