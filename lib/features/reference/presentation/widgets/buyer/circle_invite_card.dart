import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../domain/models/reference_models.dart';

/// The buyer's invitation, kept minimal: referral code with copy and a
/// share button, then tap-to-copy email and link rows.
class CircleInviteCard extends StatelessWidget {
  const CircleInviteCard({
    required this.profile,
    required this.onShare,
    super.key,
  });

  final ReferenceProfile profile;

  /// Opens the share sheet anchored to the given context.
  final void Function(BuildContext anchor) onShare;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final code = profile.referralCode.trim();
    final canShare = code.isNotEmpty || profile.shareRegisterUrl.isNotEmpty;

    return AtelierCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(RemainingL10n.yourCode).toUpperCase(),
                      style: AtelierType.overline(p.muted),
                    ),
                    const SizedBox(height: 2),
                    CircleCopyTarget(
                      value: code,
                      label: 'Referral code',
                      builder: (copied) => Row(
                        children: [
                          Flexible(
                            child: Text(
                              code.isEmpty ? '—' : code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AtelierType.display(
                                p.ink,
                                size: 24,
                                weight: FontWeight.w500,
                              ).copyWith(letterSpacing: 2),
                            ),
                          ),
                          if (code.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            CopyGlyph(copied: copied, color: p.gold, size: 16),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (anchor) => AtelierButton(
                  label: 'Share',
                  icon: Icons.ios_share_rounded,
                  variant: AtelierButtonVariant.gold,
                  onPressed: canShare ? () => onShare(anchor) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Friends who join with your code enter your circle — you earn '
            'on their diamond and melee orders.',
            style: AtelierType.caption(p.muted, size: 12),
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: p.hairline),
          _PassRow(
            icon: Icons.alternate_email_rounded,
            label: context.tr(RemainingL10n.yourEmail),
            value: profile.email,
          ),
          Container(height: 1, color: p.hairline),
          _PassRow(
            icon: Icons.link_rounded,
            label: context.tr(RemainingL10n.shareLink),
            value: profile.shareRegisterUrl,
          ),
        ],
      ),
    );
  }
}

class _PassRow extends StatelessWidget {
  const _PassRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final empty = value.trim().isEmpty;
    return CircleCopyTarget(
      value: value.trim(),
      label: label,
      builder: (copied) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: p.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                empty ? '—' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.label(p.inkSoft, size: 12.5),
              ),
            ),
            if (!empty) ...[
              const SizedBox(width: 10),
              CopyGlyph(copied: copied, color: p.gold, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tap-to-copy wrapper: copies [value], toasts and flips [builder]'s
/// `copied` flag for a moment so the glyph can confirm in place.
class CircleCopyTarget extends StatefulWidget {
  const CircleCopyTarget({
    required this.value,
    required this.label,
    required this.builder,
    super.key,
  });

  final String value;
  final String label;
  final Widget Function(bool copied) builder;

  @override
  State<CircleCopyTarget> createState() => _CircleCopyTargetState();
}

class _CircleCopyTargetState extends State<CircleCopyTarget> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await atelierCopy(widget.value);
    if (!mounted) return;
    showAtelierToast(
      context,
      '${widget.label} copied',
      tone: AtelierTone.emerald,
      icon: Icons.content_copy_rounded,
    );
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: widget.value.isEmpty ? null : _copy,
      scale: 0.985,
      semanticLabel: 'Copy ${widget.label}',
      child: widget.builder(_copied),
    );
  }
}

/// Copy icon that morphs into a check while [copied].
class CopyGlyph extends StatelessWidget {
  const CopyGlyph({
    required this.copied,
    required this.color,
    this.size = 18,
    super.key,
  });

  final bool copied;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AtelierMotion.base,
      transitionBuilder: (child, a) => ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: AtelierMotion.settle),
        child: FadeTransition(opacity: a, child: child),
      ),
      child: Icon(
        copied ? Icons.check_rounded : Icons.copy_rounded,
        key: ValueKey(copied),
        size: size,
        color: color,
      ),
    );
  }
}
