import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../application/gem_agent_controller.dart';
import '../../application/gem_agent_state.dart';

/// Text field plus mic toggle. Send appears once something is typed.
class GemAgentInputBar extends ConsumerStatefulWidget {
  const GemAgentInputBar({super.key});

  @override
  ConsumerState<GemAgentInputBar> createState() => _GemAgentInputBarState();
}

class _GemAgentInputBarState extends ConsumerState<GemAgentInputBar> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final value = _text.text.trim();
    if (value.isEmpty) return;
    _text.clear();
    FocusScope.of(context).unfocus();
    ref.read(gemAgentControllerProvider.notifier).submitText(value);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(gemAgentControllerProvider.notifier);
    final phase = ref.watch(gemAgentControllerProvider.select((s) => s.phase));
    final voice = ref.watch(
      gemAgentControllerProvider.select((s) => s.voiceAvailable),
    );
    final busy =
        phase == GemAgentPhase.thinking || phase == GemAgentPhase.acting;
    final listening = phase == GemAgentPhase.listening;
    final typed = _text.text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: LuxeStage.glass,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: listening
              ? LuxeStage.gold.withValues(alpha: 0.7)
              : LuxeStage.glassBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _text,
              enabled: !busy,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              onChanged: (_) => setState(() {}),
              cursorColor: LuxeStage.gold,
              style: LuxeType.body(LuxeStage.ink),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search or ask',
                hintStyle: LuxeType.body(LuxeStage.inkMuted),
                // Override the app theme's filled, outlined field.
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 5),
          if (typed)
            _RoundButton(
              icon: Icons.arrow_upward_rounded,
              label: 'Send',
              filled: true,
              onTap: busy ? null : _send,
            )
          else if (voice)
            _RoundButton(
              icon: listening ? Icons.stop_rounded : Icons.mic_none_rounded,
              label: listening ? 'Stop' : 'Voice',
              filled: listening,
              onTap: busy
                  ? null
                  : () {
                      AppHaptics.light();
                      listening
                          ? controller.stopListening()
                          : controller.startListening();
                    },
            ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: filled && enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [LuxeStage.goldLight, LuxeStage.goldDeep],
                  )
                : null,
            color: filled && enabled ? null : LuxeStage.glass,
          ),
          child: Icon(
            icon,
            size: 20,
            color: !enabled
                ? LuxeStage.inkMuted.withValues(alpha: 0.5)
                : filled
                ? LuxeStage.obsidian
                : LuxeStage.goldLight,
          ),
        ),
      ),
    );
  }
}
