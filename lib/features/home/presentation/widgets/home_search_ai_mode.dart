import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/gem3d/gem_view.dart';
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
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
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
                const SizedBox(width: 6),
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

/// AI Mode's resting state: what Gem AI can find, plus one ready-made ask
/// per catalogue world.
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GemAiMark(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(HomeL10n.aiModeEyebrow).toUpperCase(),
                    style: HomeType.eyebrow(palette.accent),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr(HomeL10n.aiModeBody),
                    style: HomeType.body(palette.inkMuted, size: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          context.tr(ExperienceL10n.aiTryAsking).toUpperCase(),
          style: HomeType.eyebrow(palette.inkMuted),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _prompts.length; i++)
          _maybeAnimate(
            _AiPromptRow(
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

/// Gem AI's identity: obsidian glass holding a live, turning diamond.
class _GemAiMark extends StatelessWidget {
  const _GemAiMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.05,
          colors: [HomeStage.raised, HomeStage.obsidian],
        ),
        border: Border.all(color: HomeStage.gold.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      child: GemView(
        size: 34,
        spin: 0.7,
        tilt: 0.5,
        glints: true,
        semanticLabel: context.tr(RemainingL10n.gemAi),
      ),
    );
  }
}

class _AiPromptRow extends StatelessWidget {
  const _AiPromptRow({
    required this.topic,
    required this.icon,
    required this.prompt,
    required this.onTap,
  });

  final String topic;
  final IconData icon;
  final String prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: palette.hairline, width: 0.8),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: palette.accent),
            const SizedBox(width: 14),
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
            const SizedBox(width: 10),
            Icon(Icons.north_east_rounded, size: 18, color: palette.accent),
          ],
        ),
      ),
    );
  }
}
