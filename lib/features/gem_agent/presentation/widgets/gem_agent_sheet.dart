import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/navigation/bottom_nav/app_bottom_nav_destinations.dart';
import '../../application/gem_agent_controller.dart';
import '../../application/gem_agent_state.dart';
import 'gem_agent_cards.dart';
import 'gem_agent_input_bar.dart';

/// The command card: conversation, live status, quick replies and input.
class GemAgentSheet extends StatelessWidget {
  const GemAgentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [LuxeStage.raised, LuxeStage.obsidian],
          ),
          border: Border.all(color: LuxeStage.glassBorder),
          boxShadow: [
            BoxShadow(
              color: LuxeStage.gold.withValues(alpha: 0.10),
              blurRadius: 40,
              spreadRadius: -6,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(),
              _Conversation(),
              _StatusLine(),
              _QuickReplies(),
              SizedBox(height: 8),
              GemAgentInputBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gemAgentControllerProvider.notifier);
    final phase = ref.watch(gemAgentControllerProvider.select((s) => s.phase));
    final hasHistory = ref.watch(
      gemAgentControllerProvider.select((s) => s.entries.isNotEmpty),
    );
    final (status, live) = switch (phase) {
      GemAgentPhase.listening => ('Listening', true),
      GemAgentPhase.thinking || GemAgentPhase.acting => ('Working', true),
      _ => ('Ready', false),
    };
    return Row(
      children: [
        const _Mark(),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gem Agent', style: LuxeType.display(20, LuxeStage.ink)),
              const SizedBox(height: 3),
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: live ? LuxeStage.gold : LuxeStage.inkMuted,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    status.toUpperCase(),
                    style: LuxeType.eyebrow(
                      live ? LuxeStage.goldLight : LuxeStage.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (hasHistory)
          _IconAction(
            icon: Icons.refresh_rounded,
            tooltip: 'New chat',
            onTap: controller.newSession,
          ),
        _IconAction(
          icon: Icons.close_rounded,
          tooltip: 'Close',
          onTap: controller.close,
        ),
      ],
    );
  }
}

/// Faceted gold emblem.
class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LuxeStage.goldLight, LuxeStage.gold, LuxeStage.goldDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: LuxeStage.gold.withValues(alpha: 0.35),
            blurRadius: 14,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        AppBottomNav.agentGlyph,
        maxLines: 1,
        textScaler: TextScaler.noScaling,
        style: LuxeType.display(
          22,
          LuxeStage.obsidian,
        ).copyWith(fontWeight: FontWeight.w800, height: 1, letterSpacing: 0),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(backgroundColor: LuxeStage.glass),
      icon: Icon(icon, size: 18, color: LuxeStage.inkMuted),
    );
  }
}

class _Conversation extends ConsumerWidget {
  const _Conversation();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(
      gemAgentControllerProvider.select((s) => s.entries),
    );
    if (entries.isEmpty) return const _Suggestions();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.5;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView.builder(
          reverse: true,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: entries.length,
          itemBuilder: (context, i) =>
              _Bubble(entry: entries[entries.length - 1 - i]),
        ),
      ),
    );
  }
}

/// Starter prompts shown while the conversation is empty, matched to the
/// account (guest, buyer, seller) and the side of the app.
class _Suggestions extends ConsumerWidget {
  const _Suggestions();

  static IconData _iconFor(String prompt) {
    final p = prompt.toLowerCase();
    if (p.contains('cart')) return Icons.shopping_bag_outlined;
    if (p.contains('order')) return Icons.receipt_long_outlined;
    if (p.contains('sales')) return Icons.insights_outlined;
    if (p.contains('auction')) return Icons.gavel_rounded;
    if (p.contains('offer')) return Icons.local_offer_outlined;
    if (p.contains('watch')) return Icons.watch_outlined;
    if (p.contains('ring')) return Icons.circle_outlined;
    if (p.contains('diamond')) return Icons.diamond_outlined;
    return Icons.auto_awesome_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild when the account (and so the starters) changes.
    ref.watch(authProvider.select((s) => (s.isAuthenticated, s.isSeller)));
    final controller = ref.read(gemAgentControllerProvider.notifier);
    final prompts = controller.starterPrompts();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How can I help?', style: LuxeType.display(24, LuxeStage.ink)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final label in prompts)
                _Chip(
                  icon: _iconFor(label),
                  label: label,
                  onTap: () => controller.submitText(label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LuxeStage.glass,
      shape: const StadiumBorder(
        side: BorderSide(color: LuxeStage.glassBorder),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: LuxeStage.goldLight),
                const SizedBox(width: 5),
              ],
              Text(label, style: LuxeType.label(LuxeStage.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.entry});

  final GemAgentEntry entry;

  @override
  Widget build(BuildContext context) {
    final user = entry.fromUser;
    final textColor = entry.isError
        ? LuxePalette.of(context).caution
        : user
        ? LuxeStage.obsidian
        : LuxeStage.ink;
    const r = Radius.circular(18);
    const tail = Radius.circular(4);
    final bubble = _bubble(context, user, textColor, r, tail);
    if (entry.cards.isEmpty) return bubble;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bubble,
        GemAgentCards(cards: entry.cards),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _bubble(
    BuildContext context,
    bool user,
    Color textColor,
    Radius r,
    Radius tail,
  ) {
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        decoration: BoxDecoration(
          color: user ? null : LuxeStage.glass,
          gradient: user
              ? LinearGradient(colors: [LuxeStage.goldLight, LuxeStage.gold])
              : null,
          border: user ? null : Border.all(color: LuxeStage.glassBorder),
          borderRadius: BorderRadius.only(
            topLeft: r,
            topRight: r,
            bottomLeft: user ? r : tail,
            bottomRight: user ? tail : r,
          ),
        ),
        child: Text(
          entry.text,
          style: LuxeType.body(textColor, size: 14).copyWith(height: 1.4),
        ),
      ),
    );
  }
}

class _StatusLine extends ConsumerWidget {
  const _StatusLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gemAgentControllerProvider);
    final muted = LuxeType.body(LuxeStage.inkMuted, size: 14);

    final Widget? line = switch (s.phase) {
      GemAgentPhase.listening => Row(
        children: [
          _Level(level: s.soundLevel),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.liveTranscript.isEmpty ? 'Speak now' : s.liveTranscript,
              style: s.liveTranscript.isEmpty
                  ? muted
                  : LuxeType.body(LuxeStage.ink, size: 14),
            ),
          ),
        ],
      ),
      GemAgentPhase.thinking || GemAgentPhase.acting => Row(
        children: [
          SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              color: LuxeStage.gold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(s.activity ?? 'Working…', style: muted)),
        ],
      ),
      _ when s.notice != null => Text(s.notice!, style: muted),
      _ => null,
    };
    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      alignment: Alignment.topCenter,
      child: line == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(liveRegion: true, child: line),
            ),
    );
  }
}

/// Five-bar meter driven by the recognizer's sound level.
class _Level extends StatelessWidget {
  const _Level({required this.level});

  final double level;

  static const _shape = [0.5, 0.8, 1.0, 0.8, 0.5];

  @override
  Widget build(BuildContext context) {
    // speech_to_text reports roughly -2..10 dB.
    final t = ((level + 2) / 12).clamp(0.15, 1.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final k in _shape)
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3,
            height: 4 + 14 * k * t,
            decoration: BoxDecoration(
              color: LuxeStage.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}

class _QuickReplies extends ConsumerWidget {
  const _QuickReplies();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(
      gemAgentControllerProvider.select(
        (s) => s.isBusy ? const <String>[] : s.options,
      ),
    );
    if (options.isEmpty) return const SizedBox.shrink();
    final controller = ref.read(gemAgentControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final option in options)
            _Chip(label: option, onTap: () => controller.submitText(option)),
        ],
      ),
    );
  }
}
