import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../domain/models/reference_models.dart';
import '../../../../../core/theme/luxe_tokens.dart';

/// The buyer's invitation as an onyx members' pass: the referral code set
/// large, one gold "Share invite" action and tap-to-copy email and link.
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
    final soft = p.onOnyx.withValues(alpha: 0.62);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AtelierRadius.xl),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(p.onyx, LuxeStage.vaultTop, 0.35)!,
              p.onyx,
              LuxeStage.vaultBottom,
            ],
            stops: const [0, 0.55, 1],
          ),
          borderRadius: BorderRadius.circular(AtelierRadius.xl),
          border: Border.all(color: p.gold.withValues(alpha: 0.28)),
          boxShadow: p.floatShadow,
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: IgnorePointer(child: _Sheen())),
            // Passport-style inner rule.
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AtelierRadius.xl - 6),
                    border: Border.all(
                      color: p.gold.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.diamond_outlined, size: 14, color: p.gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'YOUR INVITATION',
                          style: AtelierType.overline(p.gold),
                        ),
                      ),
                      Text(
                        'GEMWORLD',
                        style: AtelierType.overline(
                          p.onOnyx.withValues(alpha: 0.32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    context.tr(RemainingL10n.yourCode).toUpperCase(),
                    style: AtelierType.overline(soft),
                  ),
                  const SizedBox(height: 6),
                  CircleCopyTarget(
                    value: code,
                    label: 'Referral code',
                    builder: (copied) => Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              code.isEmpty ? '—' : code,
                              maxLines: 1,
                              style: AtelierType.display(
                                p.onOnyx,
                                size: 42,
                                weight: FontWeight.w500,
                              ).copyWith(letterSpacing: 6),
                            ),
                          ),
                        ),
                        if (code.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          CopyGlyph(copied: copied, color: p.gold),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Friends who join with your code enter your circle — '
                    'you earn on their diamond and melee orders.',
                    style: AtelierType.body(soft, size: 13),
                  ),
                  const SizedBox(height: 20),
                  Builder(
                    builder: (anchor) => AtelierButton(
                      label: 'Share invite',
                      icon: Icons.ios_share_rounded,
                      variant: AtelierButtonVariant.gold,
                      expand: true,
                      onPressed: canShare ? () => onShare(anchor) : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 1,
                    color: p.onOnyx.withValues(alpha: 0.1),
                  ),
                  _PassRow(
                    icon: Icons.alternate_email_rounded,
                    label: context.tr(RemainingL10n.yourEmail),
                    value: profile.email,
                  ),
                  Container(
                    height: 1,
                    color: p.onOnyx.withValues(alpha: 0.06),
                  ),
                  _PassRow(
                    icon: Icons.link_rounded,
                    label: context.tr(RemainingL10n.shareLink),
                    value: profile.shareRegisterUrl,
                  ),
                ],
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: p.onOnyx.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AtelierType.overline(
                      p.onOnyx.withValues(alpha: 0.45),
                    ).copyWith(fontSize: 9.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    empty ? '—' : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.label(p.onOnyx, size: 13),
                  ),
                ],
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

/// A slow band of gold light that crosses the pass every few seconds.
class _Sheen extends StatefulWidget {
  const _Sheen();

  @override
  State<_Sheen> createState() => _SheenState();
}

class _SheenState extends State<_Sheen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = context.atelier.gold;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // Sweep during the first third, rest in between.
        final t = (_c.value / 0.34).clamp(0.0, 1.0);
        if (t <= 0 || t >= 1) return const SizedBox.expand();
        final x = -1.6 + t * 3.2;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(x - 0.6, -1),
              end: Alignment(x + 0.6, 1),
              colors: [
                gold.withValues(alpha: 0),
                gold.withValues(alpha: 0.13),
                gold.withValues(alpha: 0),
              ],
            ),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
