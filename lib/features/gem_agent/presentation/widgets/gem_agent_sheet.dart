import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../application/gem_agent_controller.dart';
import '../../application/gem_agent_state.dart';
import 'gem_agent_input_bar.dart';

/// The command card: conversation, live status, quick replies and input.
class GemAgentSheet extends StatelessWidget {
  const GemAgentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Material(
      type: MaterialType.transparency,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: p.hairline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(),
            _Conversation(),
            _StatusLine(),
            _QuickReplies(),
            SizedBox(height: 10),
            GemAgentInputBar(),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final controller = ref.read(gemAgentControllerProvider.notifier);
    final hasHistory = ref.watch(
      gemAgentControllerProvider.select((s) => s.entries.isNotEmpty),
    );
    return Row(
      children: [
        Icon(Icons.auto_awesome_rounded, size: 18, color: p.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Gem Agent',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: p.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (hasHistory)
          IconButton(
            tooltip: 'New request',
            onPressed: controller.newSession,
            icon: Icon(Icons.refresh_rounded, color: p.inkMuted),
          ),
        IconButton(
          tooltip: 'Close',
          onPressed: controller.close,
          icon: Icon(Icons.close_rounded, color: p.inkMuted),
        ),
      ],
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
    if (entries.isEmpty) return const _EmptyHint();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.32;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: entries.length,
        itemBuilder: (context, i) =>
            _Bubble(entry: entries[entries.length - 1 - i]),
      ),
    );
  }
}

/// Greeting shown while the conversation is empty.
class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Gem Agent! How can I help you today?',
            style: text.titleSmall?.copyWith(
              color: p.ink,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask for diamonds, gemstones, watches, jewelry or bullion, '
            'e.g. "2 carat round natural diamond" or "18K gold ring".',
            style: text.bodySmall?.copyWith(color: p.inkMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.entry});

  final GemAgentEntry entry;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final user = entry.fromUser;
    final color = user ? p.accentSoft : p.surfaceRaised;
    final textColor = entry.isError ? p.caution : p.ink;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          entry.text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: textColor, height: 1.35),
        ),
      ),
    );
  }
}

class _StatusLine extends ConsumerWidget {
  const _StatusLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final s = ref.watch(gemAgentControllerProvider);
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: p.inkMuted);

    final Widget? line = switch (s.phase) {
      GemAgentPhase.listening => Text(
        s.liveTranscript.isEmpty
            ? 'Listening… tap stop when you\'re done.'
            : s.liveTranscript,
        style: style?.copyWith(
          color: s.liveTranscript.isEmpty ? p.inkMuted : p.ink,
        ),
      ),
      GemAgentPhase.thinking || GemAgentPhase.acting => Row(
        children: [
          SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(s.activity ?? 'Working…', style: style)),
        ],
      ),
      _ when s.notice != null => Text(s.notice!, style: style),
      _ => null,
    };
    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      alignment: Alignment.topCenter,
      child: line == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Semantics(liveRegion: true, child: line),
            ),
    );
  }
}

class _QuickReplies extends ConsumerWidget {
  const _QuickReplies();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final options = ref.watch(
      gemAgentControllerProvider.select(
        (s) =>
            s.phase == GemAgentPhase.awaitingInput ||
                s.phase == GemAgentPhase.listening
            ? s.options
            : const <String>[],
      ),
    );
    if (options.isEmpty) return const SizedBox.shrink();
    final controller = ref.read(gemAgentControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            ActionChip(
              label: Text(option),
              labelStyle: TextStyle(color: p.ink),
              backgroundColor: p.surfaceRaised,
              side: BorderSide(color: p.hairline),
              shape: const StadiumBorder(),
              onPressed: () => controller.submitText(option),
            ),
        ],
      ),
    );
  }
}
