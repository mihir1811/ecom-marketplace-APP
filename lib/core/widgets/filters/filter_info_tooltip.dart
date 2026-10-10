import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'filter_proportion_diagram.dart';

/// Tap-to-open filter help with optional proportion diagram + short text.
///
/// Uses a positioned overlay card instead of Material [Tooltip] so images
/// render at a stable size without rich-message layout glitches.
class FilterInfoTooltip extends StatefulWidget {
  const FilterInfoTooltip({required this.message, this.diagram, super.key});

  final String message;
  final FilterProportionDiagramKind? diagram;

  @override
  State<FilterInfoTooltip> createState() => _FilterInfoTooltipState();
}

class _FilterInfoTooltipState extends State<FilterInfoTooltip> {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _controller = OverlayPortalController();

  static const double _cardWidth = 228;
  static const double _diagramSize = 120;
  static const double _estimatedTextBlock = 56;
  static const double _gap = 8;

  void _toggle() {
    if (_controller.isShowing) {
      _controller.hide();
    } else {
      _controller.show();
    }
  }

  double get _estimatedCardHeight {
    final diagramBlock = widget.diagram == null
        ? 0.0
        : _diagramSize + AppSpacing.s12;
    return AppSpacing.s12 * 2 + diagramBlock + _estimatedTextBlock;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (context) {
          final overlayBox =
              Overlay.of(context).context.findRenderObject() as RenderBox?;
          final targetBox = this.context.findRenderObject() as RenderBox?;
          var showBelow = false;
          var horizontalShift = 0.0;

          if (overlayBox != null && targetBox != null && targetBox.hasSize) {
            final targetOffset = targetBox.localToGlobal(
              Offset.zero,
              ancestor: overlayBox,
            );
            final targetCenterX = targetOffset.dx + targetBox.size.width / 2;
            final spaceAbove = targetOffset.dy;
            final spaceBelow =
                overlayBox.size.height -
                targetOffset.dy -
                targetBox.size.height;
            showBelow =
                spaceAbove < _estimatedCardHeight + _gap &&
                spaceBelow >= spaceAbove;

            const halfWidth = _cardWidth / 2;
            const edgePad = AppSpacing.s12;
            const minCenter = halfWidth + edgePad;
            final maxCenter = overlayBox.size.width - halfWidth - edgePad;
            final clampedCenter = targetCenterX.clamp(minCenter, maxCenter);
            horizontalShift = clampedCenter - targetCenterX;
          }

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _controller.hide,
                  child: const ColoredBox(color: Color(0x00000000)),
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                targetAnchor: showBelow
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                followerAnchor: showBelow
                    ? Alignment.topCenter
                    : Alignment.bottomCenter,
                offset: Offset(horizontalShift, showBelow ? _gap : -_gap),
                child: _TooltipCard(
                  message: widget.message,
                  diagram: widget.diagram,
                  width: _cardWidth,
                  diagramSize: _diagramSize,
                ),
              ),
            ],
          );
        },
        child: Semantics(
          button: true,
          label: widget.message,
          child: InkWell(
            onTap: _toggle,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.bronze,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
    required this.message,
    required this.width,
    required this.diagramSize,
    this.diagram,
  });

  final String message;
  final FilterProportionDiagramKind? diagram;
  final double width;
  final double diagramSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.28),
      color: AppColors.charcoal.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(AppSpacing.r8),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (diagram != null) ...[
                Center(
                  child: RepaintBoundary(
                    child: FilterProportionDiagram(
                      kind: diagram!,
                      size: diagramSize,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
              ],
              Text(
                message,
                style: AppTypography.caption.copyWith(
                  color: AppColors.warmWhite,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
