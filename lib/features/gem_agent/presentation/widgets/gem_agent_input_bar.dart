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
    final p = LuxePalette.of(context);
    final controller = ref.read(gemAgentControllerProvider.notifier);
    final phase = ref.watch(gemAgentControllerProvider.select((s) => s.phase));
    final voice = ref.watch(
      gemAgentControllerProvider.select((s) => s.voiceAvailable),
    );
    final busy =
        phase == GemAgentPhase.thinking || phase == GemAgentPhase.acting;
    final listening = phase == GemAgentPhase.listening;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _text,
            enabled: !busy,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: p.ink),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Ask Gem Agent…',
              hintStyle: TextStyle(color: p.inkFaint),
              filled: true,
              fillColor: p.surfaceRaised,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (_text.text.trim().isNotEmpty)
          _RoundButton(
            icon: Icons.arrow_upward_rounded,
            label: 'Send',
            filled: true,
            onTap: busy ? null : _send,
          )
        else if (voice)
          _RoundButton(
            icon: listening ? Icons.stop_rounded : Icons.mic_rounded,
            label: listening ? 'Stop listening' : 'Speak',
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
    final p = LuxePalette.of(context);
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? p.accent : p.surfaceRaised,
          ),
          child: Icon(
            icon,
            color: !enabled
                ? p.inkFaint
                : filled
                ? p.onAccent
                : p.ink,
          ),
        ),
      ),
    );
  }
}
