import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../buyer/presentation/maison/maison_kit.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../domain/models/recently_viewed.dart';
import 'recent_piece.dart';

/// Onyx spotlight for the last piece the buyer opened, so returning to it
/// is a single tap. The photo drifts slowly and a champagne sheen passes
/// once when the card arrives.
class RecentResumeCard extends ConsumerStatefulWidget {
  const RecentResumeCard({required this.entry, super.key});

  final RecentlyViewedEntry entry;

  @override
  ConsumerState<RecentResumeCard> createState() => _RecentResumeCardState();
}

class _RecentResumeCardState extends ConsumerState<RecentResumeCard> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final failedText = context.tr(AccountCommerceL10n.productOpenFailed);
    setState(() => _opening = true);
    try {
      final opened = await openRecentPiece(context, ref, widget.entry);
      if (!opened && mounted) {
        AppHaptics.error();
        showMaisonToast(messenger, palette, failedText, tone: AtelierTone.ruby);
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final entry = widget.entry;
    final price = entry.priceLabel;
    final detail = entry.detailLine;
    final when = entry.viewedWhen;
    final availability = entry.availabilityState;
    final soft = p.onOnyx.withValues(alpha: 0.62);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        final imageSize = wide ? 168.0 : 112.0;

        Widget photo = RecentPieceImage(
          entry: entry,
          iconSize: 32,
          memCacheWidth: 420,
        );
        if (!context.reduceMotion) {
          photo = photo
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1,
                end: 1.07,
                duration: 9.seconds,
                curve: Curves.easeInOut,
              );
        }

        Widget card = Container(
          decoration: BoxDecoration(
            color: p.onyx,
            borderRadius: BorderRadius.circular(AtelierRadius.xl),
            border: Border.all(color: p.gold.withValues(alpha: 0.28)),
            boxShadow: p.floatShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(wide ? 12 : 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AtelierRadius.lg),
                      child: SizedBox(
                        width: imageSize,
                        height: imageSize,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            photo,
                            AnimatedOpacity(
                              duration: AtelierMotion.base,
                              opacity: _opening ? 1 : 0,
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.4),
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
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: wide ? 20 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              'Last viewed',
                              if (when.isNotEmpty) when,
                            ].join(' · ').toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.overline(p.gold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            entry.displayTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.display(
                              p.onOnyx,
                              size: wide ? 28 : 21,
                              weight: FontWeight.w500,
                            ),
                          ),
                          if (detail != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AtelierType.caption(soft, size: 11.5),
                            ),
                          ],
                          SizedBox(height: wide ? 14 : 10),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      price ?? 'Price on request',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: price == null
                                          ? AtelierType.caption(soft)
                                          : AtelierType.display(
                                              p.gold,
                                              size: wide ? 24 : 20,
                                            ),
                                    ),
                                    if (availability !=
                                        RecentAvailability.unknown) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        availability.label(
                                          context,
                                          entry.availability,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AtelierType.caption(
                                          soft,
                                          size: 10.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _ResumeArrow(wide: wide),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (!context.reduceMotion) {
          card = card.animate().shimmer(
            delay: 700.ms,
            duration: 1800.ms,
            color: p.gold.withValues(alpha: 0.16),
          );
        }

        return Pressable(
          onTap: _opening ? null : _open,
          scale: 0.985,
          semanticLabel: 'Return to ${entry.displayTitle}',
          borderRadius: BorderRadius.circular(AtelierRadius.xl),
          child: card,
        );
      },
    );
  }
}

class _ResumeArrow extends StatelessWidget {
  const _ResumeArrow({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final size = wide ? 48.0 : 42.0;
    Widget arrow = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: p.goldGradient,
        boxShadow: [
          BoxShadow(
            color: p.gold.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Icon(Icons.arrow_forward_rounded, size: 20, color: p.onGold),
    );
    if (!context.reduceMotion) {
      arrow = arrow
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveX(begin: 0, end: 3, duration: 1400.ms, curve: Curves.easeInOut);
    }
    return arrow;
  }
}
