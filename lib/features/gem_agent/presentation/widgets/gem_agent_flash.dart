import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../application/gem_agent_controller.dart';

/// The last action's result, shown above the dock for a few seconds after
/// the sheet closes. The agent itself opens from the dock's Agent slot.
class GemAgentFlash extends ConsumerWidget {
  const GemAgentFlash({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flash = ref.watch(gemAgentControllerProvider.select((s) => s.flash));
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: flash == null
          ? const SizedBox.shrink()
          : _FlashPill(key: ValueKey(flash), text: flash),
    );
  }
}

class _FlashPill extends StatelessWidget {
  const _FlashPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final maxWidth = MediaQuery.sizeOf(context).width - 32;
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth.clamp(120, 360)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: p.ink, height: 1.3),
      ),
    );
  }
}
