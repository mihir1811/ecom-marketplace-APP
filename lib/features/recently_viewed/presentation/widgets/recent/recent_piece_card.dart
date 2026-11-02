import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../buyer/application/wishlist_provider.dart';
import '../../../../buyer/presentation/maison/maison_kit.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../domain/models/recently_viewed.dart';
import 'recent_piece.dart';

/// A piece from the buyer's viewing history, as a gallery tile or a list
/// row ([compact]). Tapping returns to the piece; the heart saves it and
/// the scales add it to comparison (diamonds, gemstones and watches).
class RecentPieceCard extends ConsumerStatefulWidget {
  const RecentPieceCard({required this.entry, this.compact = false, super.key});

  final RecentlyViewedEntry entry;
  final bool compact;

  @override
  ConsumerState<RecentPieceCard> createState() => _RecentPieceCardState();
}

class _RecentPieceCardState extends ConsumerState<RecentPieceCard> {
  bool _opening = false;

  RecentlyViewedEntry get entry => widget.entry;

  Future<void> _open() async {
    if (_opening) return;
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final failedText = context.tr(AccountCommerceL10n.productOpenFailed);
    setState(() => _opening = true);
    try {
      final opened = await openRecentPiece(context, ref, entry);
      if (!opened && mounted) {
        AppHaptics.error();
        showMaisonToast(messenger, palette, failedText, tone: AtelierTone.ruby);
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  String get _semantics {
    final price = entry.priceLabel;
    final when = entry.viewedWhen;
    return [
      entry.displayTitle,
      ?price,
      if (when.isNotEmpty) 'viewed $when',
    ].join(', ');
  }

  @override
  Widget build(BuildContext context) =>
      widget.compact ? _row(context) : _tile(context);

  Widget _tile(BuildContext context) {
    final p = context.atelier;
    final price = entry.priceLabel;
    final detail = entry.detailLine;
    return Pressable(
      onTap: _opening ? null : _open,
      semanticLabel: _semantics,
      borderRadius: BorderRadius.circular(AtelierRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.lg),
          border: Border.all(color: p.hairline),
          boxShadow: p.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RecentPieceImage(entry: entry, iconSize: 34),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, 0.35, 0.7, 1],
                        colors: [
                          Color(0x30000000),
                          Color(0x00000000),
                          Color(0x00000000),
                          Color(0x38000000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _SaveButton(entry: entry),
                  ),
                  if (entry.availabilityState != RecentAvailability.unknown)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      right: 10,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _AvailabilityTag(entry: entry),
                      ),
                    ),
                  _OpeningVeil(visible: _opening),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.title(p.ink, size: 14),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.caption(p.muted, size: 11.5),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            price ?? 'Price on request',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: price == null
                                ? AtelierType.caption(p.muted, size: 12)
                                : AtelierType.display(p.ink, size: 20),
                          ),
                        ),
                        if (entry.viewedWhen.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Text(
                            entry.viewedWhen,
                            maxLines: 1,
                            style: AtelierType.caption(p.muted, size: 10.5),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context) {
    final p = context.atelier;
    final price = entry.priceLabel;
    final detail = entry.detailLine;
    final when = entry.viewedWhen;
    final availability = entry.availabilityState;
    return Pressable(
      onTap: _opening ? null : _open,
      semanticLabel: _semantics,
      borderRadius: BorderRadius.circular(AtelierRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.lg),
          border: Border.all(color: p.hairline),
          boxShadow: p.softShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AtelierRadius.md),
              child: SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RecentPieceImage(
                      entry: entry,
                      iconSize: 26,
                      memCacheWidth: 260,
                    ),
                    _OpeningVeil(visible: _opening),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.listTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.title(p.ink, size: 14.5),
                        ),
                      ),
                      if (availability != RecentAvailability.unknown) ...[
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Tooltip(
                            message: availability.label(
                              context,
                              entry.availability,
                            ),
                            child: _Dot(color: p.tone(availability.tone)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.caption(p.muted, size: 11.5),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          price ?? 'Price on request',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: price == null
                              ? AtelierType.caption(p.muted, size: 12)
                              : AtelierType.display(p.ink, size: 19),
                        ),
                      ),
                      if (when.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          when,
                          maxLines: 1,
                          style: AtelierType.caption(p.muted, size: 10.5),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            _SaveButton(entry: entry, onSurface: true),
          ],
        ),
      ),
    );
  }
}

/// Heart that saves / unsaves the piece and pops when it changes.
class _SaveButton extends ConsumerStatefulWidget {
  const _SaveButton({required this.entry, this.onSurface = false});

  final RecentlyViewedEntry entry;
  final bool onSurface;

  @override
  ConsumerState<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends ConsumerState<_SaveButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final addedText = context.tr(AccountCommerceL10n.addedWishlist);
    final removedText = context.tr(AccountCommerceL10n.removedWishlist);
    final router = GoRouter.of(context);
    final item = widget.entry.toWishlistItem();
    final notifier = ref.read(wishlistProvider.notifier);
    setState(() => _busy = true);
    final added = await notifier.toggle(item);
    if (!mounted) return;
    setState(() => _busy = false);
    final error = ref.read(wishlistProvider).errorMessage;
    if (error != null && error.isNotEmpty) {
      AppHaptics.error();
      showMaisonToast(messenger, palette, error, tone: AtelierTone.ruby);
      return;
    }
    AppHaptics.medium();
    if (added) {
      showMaisonToast(
        messenger,
        palette,
        addedText,
        icon: Icons.favorite_rounded,
        tone: AtelierTone.ruby,
        actionLabel: 'View',
        onAction: () => router.go(AppRouteNames.buyerWishlist),
      );
    } else {
      showMaisonToast(
        messenger,
        palette,
        removedText,
        icon: Icons.heart_broken_outlined,
        actionLabel: 'Undo',
        onAction: () => notifier.add(item),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final saved = ref.watch(isInWishlistProvider(widget.entry.productId));
    final label = saved
        ? context.tr(AccountCommerceL10n.removeWishlist)
        : 'Save to wishlist';
    Widget icon = Icon(
      saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      key: ValueKey(saved),
      size: 18,
      color: saved ? p.ruby : (widget.onSurface ? p.inkSoft : p.ink),
    );
    if (saved && !context.reduceMotion) {
      icon = icon.animate().scaleXY(
        begin: 0.5,
        end: 1,
        duration: 420.ms,
        curve: AtelierMotion.settle,
      );
    }
    return Tooltip(
      message: label,
      child: Pressable(
        onTap: _busy ? null : _toggle,
        scale: 0.82,
        haptic: false,
        semanticLabel: label,
        borderRadius: BorderRadius.circular(40),
        child: _RoundControl(
          onSurface: widget.onSurface,
          active: saved,
          activeColor: p.ruby,
          child: _busy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: p.ruby,
                  ),
                )
              : icon,
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.child,
    required this.onSurface,
    required this.active,
    required this.activeColor,
  });

  final Widget child;
  final bool onSurface;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final Color fill;
    if (onSurface) {
      fill = active
          ? activeColor.withValues(alpha: p.isDark ? 0.16 : 0.08)
          : p.sunken;
    } else {
      fill = Colors.white.withValues(alpha: 0.92);
    }
    return AnimatedContainer(
      duration: AtelierMotion.base,
      curve: AtelierMotion.emphasized,
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        boxShadow: onSurface
            ? null
            : const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: IconTheme(
        data: IconThemeData(color: onSurface ? p.inkSoft : p.ink),
        child: child,
      ),
    );
  }
}

class _AvailabilityTag extends StatelessWidget {
  const _AvailabilityTag({required this.entry});

  final RecentlyViewedEntry entry;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final state = entry.availabilityState;
    final color = switch (state) {
      RecentAvailability.available => const Color(0xFF7FE0AE),
      RecentAvailability.reserved => const Color(0xFFF2C46B),
      RecentAvailability.gone => const Color(0xFFFF9C90),
      RecentAvailability.unknown => p.muted,
    };
    return Tooltip(
      message: state.label(context, entry.availability),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: _Dot(color: color),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
      ],
    ),
  );
}

class _OpeningVeil extends StatelessWidget {
  const _OpeningVeil({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: AtelierMotion.base,
        opacity: visible ? 1 : 0,
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
