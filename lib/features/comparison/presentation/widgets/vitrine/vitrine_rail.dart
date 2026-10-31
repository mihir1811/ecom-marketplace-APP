import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../domain/models/compare_insights.dart';
import '../../../domain/models/compare_item.dart';
import 'vitrine_gem.dart';
import 'vitrine_style.dart';

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Column geometry shared by the rail and the spec rows, so every value
/// sits under its piece.
class VitrineColumns {
  const VitrineColumns({required this.count, required this.width});

  /// Columns shown: the pieces, and at least two.
  final int count;
  final double width;

  static const pad = 16.0;
  static const gap = 8.0;

  double get column => (width - 2 * pad - gap * (count - 1)) / count;

  /// Medallion image size when the rail is fully open.
  double get image => math.min(column - 14, 96).toDouble();
}

/// Pinned header: one medallion per piece, folding from photo cards into a
/// slim strip of thumbnails and prices as the specs scroll under it, with
/// an add-piece chip beneath.
class VitrineRailDelegate extends SliverPersistentHeaderDelegate {
  VitrineRailDelegate({
    required this.items,
    required this.insights,
    required this.columns,
    required this.onTapPiece,
    required this.onRemove,
    required this.onReorder,
    required this.onAdd,
  });

  final List<CompareItem> items;
  final CompareInsights insights;
  final VitrineColumns columns;
  final ValueChanged<int> onTapPiece;
  final ValueChanged<int> onRemove;
  final void Function(int from, int to) onReorder;
  final VoidCallback onAdd;

  /// Band under the rail holding the add chip; gone when it has nothing.
  bool get _showAdd => items.length >= 2 && items.length < 4;
  double get _band => _showAdd ? 56.0 : 0.0;
  static const _open = 108.0;
  static const _folded = 64.0;

  @override
  double get maxExtent => columns.image + _open + _band;

  @override
  double get minExtent => _folded + _band;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final v = Vitrine.of(context);
    final range = maxExtent - minExtent;
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final railHeight = _lerp(columns.image + _open, _folded, t);
    final leader = insights.frontRunner;

    // Fixed geometry: large system text would spill out of the slots.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18 * t, sigmaY: 18 * t),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: v.paper.withValues(alpha: _lerp(0.0, 0.88, t)),
              border: Border(
                bottom: BorderSide(
                  color: v.line.withValues(alpha: t),
                  width: 0.6,
                ),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: railHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VitrineColumns.pad,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < columns.count; i++) ...[
                          if (i > 0) const SizedBox(width: VitrineColumns.gap),
                          SizedBox(
                            width: columns.column,
                            child: i < items.length
                                ? _Draggable(
                                    key: ValueKey(items[i].id),
                                    index: i,
                                    width: columns.column,
                                    item: items[i],
                                    imageSize: columns.image,
                                    onReorder: onReorder,
                                    child: _Medallion(
                                      item: items[i],
                                      index: i,
                                      t: t,
                                      imageSize: columns.image,
                                      wins:
                                          insights.wins.elementAtOrNull(i) ?? 0,
                                      decisive: insights.decisive,
                                      leader: leader == i,
                                      onTap: () => onTapPiece(i),
                                      onRemove: () => onRemove(i),
                                    ),
                                  )
                                : _AddSlot(
                                    t: t,
                                    imageSize: columns.image,
                                    onTap: onAdd,
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_showAdd)
                  SizedBox(
                    height: _band,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [_AddChip(onTap: onAdd)],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(VitrineRailDelegate old) => true;
}

class _Medallion extends StatelessWidget {
  const _Medallion({
    required this.item,
    required this.index,
    required this.t,
    required this.imageSize,
    required this.wins,
    required this.decisive,
    required this.leader,
    required this.onTap,
    required this.onRemove,
  });

  final CompareItem item;
  final int index;
  final double t;
  final double imageSize;
  final int wins;
  final int decisive;
  final bool leader;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    final fade = (1 - t * 2.2).clamp(0.0, 1.0);
    final size = _lerp(imageSize, 28, t);

    return Semantics(
      button: true,
      label: '${item.title}, ${item.displayValues['price'] ?? ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: Column(
          children: [
            SizedBox(height: _lerp(8, 6, t)),
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  VitrinePieceImage(
                    item: item,
                    size: size,
                    radius: _lerp(20, 9, t),
                    ring: leader,
                  ),
                  if (fade > 0) ...[
                    Positioned(
                      left: 8,
                      top: 7,
                      child: Opacity(
                        opacity: fade,
                        child: Text(
                          vitrineNumeral(index),
                          style: v.display(
                            12,
                            color: v.gold,
                            style: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Opacity(
                        opacity: fade,
                        child: _RemoveDot(onTap: onRemove),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: _lerp(10, 6, t)),
            _Slot(
              height: _lerp(34, 0, t),
              full: 34,
              child: Opacity(
                opacity: fade,
                child: Text(
                  item.title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: v.display(13.5),
                ),
              ),
            ),
            SizedBox(height: _lerp(4, 0, t)),
            SizedBox(
              height: 18,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.displayValues['price'] ?? '',
                  style: v.figure(13.5, color: leader ? v.gold : v.ink),
                ),
              ),
            ),
            SizedBox(height: _lerp(6, 0, t)),
            _Slot(
              height: _lerp(20, 0, t),
              full: 20,
              child: Opacity(
                opacity: fade,
                child: decisive == 0
                    ? const SizedBox.shrink()
                    : _LeadMeter(wins: wins, total: decisive),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Leads 3 of 7" over a row of hairline ticks, the won ones in gold.
class _LeadMeter extends StatelessWidget {
  const _LeadMeter({required this.wins, required this.total});

  final int wins;
  final int total;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.tr(AccountCommerceL10n.compareLeads, {
              'wins': wins,
              'total': total,
            }),
            maxLines: 1,
            style: v.text(9.5, color: v.muted, weight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 3),
        TweenAnimationBuilder<double>(
          tween: Tween(end: wins.toDouble()),
          duration: VitrineMotion.settle * 2,
          curve: VitrineMotion.ease,
          builder: (context, lit, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < total; i++)
                Flexible(
                  child: Container(
                    width: 8,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: ShapeDecoration(
                      shape: const StadiumBorder(),
                      color: Color.lerp(
                        v.line,
                        v.gold,
                        (lit - i).clamp(0.0, 1.0),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RemoveDot extends StatelessWidget {
  const _RemoveDot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    return Semantics(
      button: true,
      label: context.tr(AccountCommerceL10n.removeComparison),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.light();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: v.ink,
              border: Border.all(color: v.paper, width: 2),
            ),
            child: Icon(Icons.close_rounded, size: 12, color: v.paper),
          ),
        ),
      ),
    );
  }
}

/// Empty column that invites another piece.
class _AddSlot extends StatelessWidget {
  const _AddSlot({
    required this.t,
    required this.imageSize,
    required this.onTap,
  });

  final double t;
  final double imageSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    final size = _lerp(imageSize, 28, t);
    final fade = (1 - t * 2.2).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      child: Column(
        children: [
          SizedBox(height: _lerp(8, 6, t)),
          CustomPaint(
            painter: _DashedFrame(color: v.faint, radius: _lerp(20, 9, t)),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                Icons.add_rounded,
                size: _lerp(26, 16, t),
                color: v.gold,
              ),
            ),
          ),
          SizedBox(height: _lerp(10, 6, t)),
          _Slot(
            height: _lerp(34, 0, t),
            full: 34,
            child: Opacity(
              opacity: fade,
              child: Text(
                context.tr(AccountCommerceL10n.compareAddPiece),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: v.display(13.5, color: v.muted, style: FontStyle.italic),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedFrame extends CustomPainter {
  _DashedFrame({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(0.5),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 4.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedFrame old) =>
      old.color != color || old.radius != radius;
}

/// Long-press a medallion to lift it; drop it on another to swap places.
class _Draggable extends StatelessWidget {
  const _Draggable({
    required this.index,
    required this.width,
    required this.item,
    required this.imageSize,
    required this.onReorder,
    required this.child,
    super.key,
  });

  final int index;
  final double width;
  final CompareItem item;
  final double imageSize;
  final void Function(int from, int to) onReorder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) {
        if (d.data == index) return false;
        AppHaptics.selection();
        return true;
      },
      onAcceptWithDetails: (d) {
        AppHaptics.medium();
        onReorder(d.data, index);
      },
      builder: (context, candidates, _) {
        final hovered = candidates.isNotEmpty;
        return LongPressDraggable<int>(
          data: index,
          delay: const Duration(milliseconds: 220),
          hapticFeedbackOnStart: true,
          feedback: Material(
            type: MaterialType.transparency,
            child: Transform.rotate(
              angle: -0.035,
              child: SizedBox(
                width: width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VitrinePieceImage(
                      item: item,
                      size: imageSize * 1.06,
                      ring: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: v.display(13.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.25, child: child),
          child: AnimatedScale(
            duration: VitrineMotion.quick,
            curve: VitrineMotion.ease,
            scale: hovered ? 0.94 : 1,
            child: AnimatedOpacity(
              duration: VitrineMotion.quick,
              opacity: hovered ? 0.7 : 1,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    return Material(
      color: Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: v.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16, color: v.gold),
              const SizedBox(width: 4),
              Text(
                context.tr(AccountCommerceL10n.compareAddPiece),
                style: v.text(12, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A slot that shrinks to [height] while its child keeps its [full]
/// height, clipped, so folding never overflows.
class _Slot extends StatelessWidget {
  const _Slot({required this.height, required this.full, required this.child});

  final double height;
  final double full;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: full,
          maxHeight: full,
          child: child,
        ),
      ),
    );
  }
}
