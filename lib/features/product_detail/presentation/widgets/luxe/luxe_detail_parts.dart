import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/app_navigation.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../../../core/utils/format_catalog_price.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../domain/models/product_detail.dart';
import '../../../domain/models/product_price_labels.dart';
import '../../screens/certificate_viewer_screen.dart';
import 'luxe_detail_gallery.dart';

/// Page frame shared by every luxe detail page (catalogue products and
/// auctions): full-bleed gallery under a floating header that frosts on
/// scroll, a summary column (beside the gallery on wide screens), the full
/// record below and a pinned action bar.
class LuxeDetailLayout extends StatefulWidget {
  const LuxeDetailLayout({
    required this.title,
    required this.media,
    required this.summary,
    required this.record,
    super.key,
    this.availabilityStatus,
    this.headerActions,
    this.related,
    this.bottomBar,
    this.onRefresh,
  });

  final String title;
  final ProductMedia media;
  final String? availabilityStatus;
  final Widget summary;
  final Widget record;

  /// Strip below the record laid out edge to edge; receives its leading
  /// gutter.
  final Widget Function(double gutter)? related;

  /// Trailing header controls; `glass` is true while over the gallery.
  final List<Widget> Function(bool glass)? headerActions;
  final Widget? bottomBar;

  /// Enables pull-to-refresh when set.
  final Future<void> Function()? onRefresh;

  @override
  State<LuxeDetailLayout> createState() => _LuxeDetailLayoutState();
}

class _LuxeDetailLayoutState extends State<LuxeDetailLayout> {
  static const _wide = 900.0;
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _offset.value = _scroll.offset);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final topInset = MediaQuery.paddingOf(context).top + 60;

    return AppScaffold(
      backgroundColor: p.canvas,
      safeTop: false,
      bottomNavigationBar: widget.bottomBar,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wide;
          final gallery = LuxeDetailGallery(
            media: widget.media,
            availabilityStatus: widget.availabilityStatus,
            topInset: wide ? 0 : topInset,
          );

          final content = wide
              ? SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, topInset, 16, 40),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      LuxeSpace.radius,
                                    ),
                                    child: gallery,
                                  ),
                                ),
                                const SizedBox(width: 40),
                                Expanded(flex: 5, child: widget.summary),
                              ],
                            ),
                            const SizedBox(height: 20),
                            widget.record,
                            ?widget.related?.call(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : SliverList.list(
                  children: [
                    gallery,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                      child: widget.summary,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                      child: widget.record,
                    ),
                    ?widget.related?.call(20),
                    const SizedBox(height: 40),
                  ],
                );

          Widget scroll = CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [content],
          );
          final refresh = widget.onRefresh;
          if (refresh != null) {
            scroll = RefreshIndicator(
              color: p.ink,
              backgroundColor: p.surface,
              edgeOffset: topInset,
              onRefresh: refresh,
              child: scroll,
            );
          }

          return Stack(
            children: [
              scroll,
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LuxeFloatingHeader(
                  title: widget.title,
                  offset: _offset,
                  solidAfter: wide ? 1 : constraints.maxWidth * 0.75,
                  actions: widget.headerActions,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Header that floats over the gallery with glass controls and turns into
/// a frosted bar (with the title) once the gallery scrolls away.
class LuxeFloatingHeader extends StatelessWidget {
  const LuxeFloatingHeader({
    required this.title,
    required this.offset,
    required this.solidAfter,
    super.key,
    this.actions,
    this.darkBackdrop = false,
    this.leadingIcon = Icons.arrow_back_rounded,
  });

  /// Icon of the leading button (a chevron-down when the page is a sheet).
  final IconData leadingIcon;

  final String title;
  final ValueListenable<double> offset;
  final double solidAfter;
  final List<Widget> Function(bool glass)? actions;

  /// True when the header first floats over a dark stage, so the status bar
  /// stays light until the bar turns solid.
  final bool darkBackdrop;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return ValueListenableBuilder<double>(
      valueListenable: offset,
      builder: (context, offset, _) {
        final t = ((offset - solidAfter + 80) / 80).clamp(0.0, 1.0);
        final glass = t < 0.5;
        Widget bar = Container(
          padding: EdgeInsets.fromLTRB(8, top + 6, 8, 6),
          decoration: BoxDecoration(
            color: p.canvas.withValues(alpha: 0.9 * t),
            border: Border(
              bottom: BorderSide(
                color: p.hairline.withValues(alpha: t),
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            children: [
              LuxeIconButton(
                icon: leadingIcon,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                glass: glass,
                size: 42,
                onPressed: () => context.goBack(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Opacity(
                  opacity: t,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.display(20, p.ink),
                  ),
                ),
              ),
              ...?actions?.call(glass),
            ],
          ),
        );
        if (t > 0.01) {
          bar = ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16 * t, sigmaY: 16 * t),
              child: bar,
            ),
          );
        }
        if (darkBackdrop && glass && !p.isDark) {
          // Smoked glass controls while over the dark stage.
          final theme = Theme.of(context);
          bar = Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                brightness: Brightness.dark,
              ),
            ),
            child: bar,
          );
        }
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: p.isDark || (darkBackdrop && glass)
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: bar,
        );
      },
    );
  }
}

/// Staggered fade-up used for summary blocks on detail pages.
Widget luxeEnter(BuildContext context, Widget child, int index) {
  if (MediaQuery.disableAnimationsOf(context)) return child;
  return child
      .animate(delay: (80 + index * 70).ms)
      .fadeIn(duration: 500.ms)
      .moveY(begin: 12, end: 0, duration: 700.ms, curve: LuxeMotion.settle);
}

/// Diamond reports read "Report no."; other records keep their own label
/// (e.g. "Certificate", "Mint").
String luxeReferenceLabel(BuildContext context, ProductCertification cert) {
  final label = cert.referenceLabel?.trim();
  if (label == null || label.isEmpty || label == 'Report') {
    return context.tr(DiamondFlowL10n.reportNumber);
  }
  return label;
}

/// True for blank / placeholder values ("N/A", "—", "not certified").
bool luxeIsMissing(String value) {
  final v = value.trim();
  return v.isEmpty ||
      v == 'N/A' ||
      v == '—' ||
      v == '-' ||
      // Uncertified stones: the spec tabs already state it plainly.
      v.toLowerCase() == 'not certified';
}

/// Segment eyebrow with a tap-to-copy stock reference.
class LuxeDetailEyebrow extends StatelessWidget {
  const LuxeDetailEyebrow({required this.detail, super.key});

  final ProductDetail detail;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Row(
      children: [
        Flexible(
          child: Text(
            detail.segment.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LuxeType.eyebrow(p.accent),
          ),
        ),
        Text('  ·  ', style: LuxeType.eyebrow(p.inkFaint)),
        // Long references (UUIDs) ellipsize instead of overflowing.
        Flexible(
          flex: 2,
          child: Tooltip(
            message: detail.referenceLabel,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                Clipboard.setData(ClipboardData(text: detail.referenceValue));
                showLuxeToast(
                  context,
                  context.tr(DiamondFlowL10n.stockIdCopied),
                  tone: LuxeTone.success,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '#${detail.referenceValue}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuxeType.figure(p.inkMuted, size: 12),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.copy_rounded, size: 12, color: p.inkFaint),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Toned stadium badge (certified, below list, …).
class LuxeDetailBadge extends StatelessWidget {
  const LuxeDetailBadge({required this.badge, super.key});

  final ProductBadge badge;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final (fg, bg) = switch (badge.tone) {
      ProductBadgeTone.accent => (p.accent, p.accentSoft),
      ProductBadgeTone.positive => (
        p.positive,
        p.positive.withValues(alpha: 0.1),
      ),
      ProductBadgeTone.caution => (p.caution, p.caution.withValues(alpha: 0.1)),
      ProductBadgeTone.neutral => (p.inkMuted, p.surfaceRaised),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
      child: Text(badge.label, style: LuxeType.label(fg, size: 11.5)),
    );
  }
}

/// Price card: struck list price with saving, serif sale price, unit.
class LuxePriceCard extends StatelessWidget {
  const LuxePriceCard({required this.labels, super.key, this.footer});

  final ProductPriceLabels labels;

  /// Extra lines under the price (tax note, reference, …).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labels.hasDiscount)
            Row(
              children: [
                Flexible(
                  child: Text(
                    labels.list!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(p.inkFaint, size: 13).copyWith(
                      decoration: TextDecoration.lineThrough,
                      decorationColor: p.inkFaint,
                    ),
                  ),
                ),
                if (labels.saveAmount != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      context.tr(DiamondFlowL10n.youSave, {
                        'amount':
                            labels.currencySymbol +
                            formatGroupedWhole(
                              labels.saveAmount!.roundToDouble(),
                            ),
                      }),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.label(p.positive, size: 12),
                    ),
                  ),
                ],
              ],
            ),
          if (labels.hasDiscount) const SizedBox(height: 5),
          // The figure rolls in when it changes (e.g. a new variant).
          AnimatedSwitcher(
            duration: LuxeMotion.medium,
            switchInCurve: LuxeMotion.settle,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previous, ?current],
            ),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.35),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: FittedBox(
              key: ValueKey(labels.sale),
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                labels.sale,
                style: LuxeType.display(
                  40,
                  p.ink,
                ).copyWith(fontFeatures: const [FontFeature.liningFigures()]),
              ),
            ),
          ),
          if (labels.unit != null) ...[
            const SizedBox(height: 4),
            Text(labels.unit!, style: LuxeType.label(p.inkMuted, size: 13)),
          ],
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );
  }
}

/// Four key grades as quiet tiles.
class LuxeGlance extends StatelessWidget {
  const LuxeGlance({required this.highlights, super.key});

  final List<ProductHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(DiamondFlowL10n.atAGlance).toUpperCase(),
          style: LuxeType.eyebrow(p.inkMuted),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final perRow = constraints.maxWidth > 420 ? 4 : 2;
            const gap = 8.0;
            final w = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final h in highlights.take(4))
                  Container(
                    width: w,
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    decoration: BoxDecoration(
                      color: p.surfaceRaised,
                      borderRadius: BorderRadius.circular(
                        LuxeSpace.radiusSmall,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.label,
                          style: LuxeType.label(p.inkMuted, size: 11.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          h.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.display(24, p.ink),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Certifying lab, report number and a "View certificate" action.
class LuxeCertificateCard extends StatelessWidget {
  const LuxeCertificateCard({required this.cert, super.key});

  final ProductCertification cert;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.positive.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: p.positive,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(DiamondFlowL10n.certifiedBy, {
                        'lab': cert.authority,
                      }),
                      style: LuxeType.label(p.ink, size: 14.5),
                    ),
                    if (cert.referenceValue != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${luxeReferenceLabel(context, cert)} '
                        '${cert.referenceValue}',
                        style: LuxeType.figure(p.inkMuted, size: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (cert.hasCertificateLink) ...[
            const SizedBox(height: 10),
            LuxeButton(
              label: context.tr(DiamondFlowL10n.viewCertificate),
              variant: LuxeButtonVariant.secondary,
              icon: Icons.open_in_new_rounded,
              height: 44,
              expand: true,
              onPressed: () => openCertificateViewer(
                context,
                url: cert.certificateUrl!,
                title:
                    cert.certificateLabel ??
                    context.tr(CatalogL10n.certification),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One label / value row of a spec list. [emphasis] sets the value in the
/// serif display face (totals); [tone] colours it (e.g. a saving).
class LuxeSpecLine {
  const LuxeSpecLine(
    this.label,
    this.value, {
    this.emphasis = false,
    this.tone,
  });

  final String label;
  final String value;
  final bool emphasis;
  final Color? tone;
}

/// Hairline-separated label / value rows.
class LuxeSpecList extends StatelessWidget {
  const LuxeSpecList({required this.lines, super.key});

  final List<LuxeSpecLine> lines;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Column(
      children: [
        for (var i = 0; i < lines.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: i == lines.length - 1
                  ? null
                  : Border(bottom: BorderSide(color: p.hairline, width: 0.6)),
            ),
            child: Row(
              crossAxisAlignment: lines[i].emphasis
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    lines[i].label,
                    style: LuxeType.label(
                      lines[i].emphasis ? p.ink : p.inkMuted,
                      size: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lines[i].value,
                    textAlign: TextAlign.right,
                    style: lines[i].emphasis
                        ? LuxeType.display(22, lines[i].tone ?? p.ink)
                        : LuxeType.label(lines[i].tone ?? p.ink, size: 13.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Eyebrow-titled group of spec rows inside a tab.
class LuxeSpecGroup extends StatelessWidget {
  const LuxeSpecGroup({required this.title, required this.lines, super.key});

  final String title;
  final List<LuxeSpecLine> lines;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(title.toUpperCase(), style: LuxeType.eyebrow(p.accent)),
        LuxeSpecList(lines: lines),
      ],
    );
  }
}

/// Serif-titled panel with a tab selector (segmented for up to three tabs,
/// scrolling chips beyond) and an animated card body.
class LuxeTabbedPanel extends StatefulWidget {
  const LuxeTabbedPanel({
    required this.title,
    required this.tabs,
    required this.bodyOf,
    super.key,
  });

  final String title;
  final List<String> tabs;
  final Widget Function(BuildContext context, int index) bodyOf;

  @override
  State<LuxeTabbedPanel> createState() => _LuxeTabbedPanelState();
}

class _LuxeTabbedPanelState extends State<LuxeTabbedPanel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final tabs = widget.tabs;
    final index = _index.clamp(0, tabs.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: LuxeType.display(28, p.ink)),
        const SizedBox(height: 10),
        if (tabs.length > 1)
          tabs.length <= 3
              ? LuxeSegmented<int>(
                  options: [for (var i = 0; i < tabs.length; i++) i],
                  selected: index,
                  onChanged: (i) => setState(() => _index = i),
                  labelOf: (i) => tabs[i],
                  dense: true,
                )
              : SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: tabs.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, i) => ChoiceChip(
                      label: Text(tabs[i]),
                      selected: i == index,
                      onSelected: (_) {
                        AppHaptics.selection();
                        setState(() => _index = i);
                      },
                    ),
                  ),
                ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(LuxeSpace.radius),
            border: Border.all(color: p.hairline),
          ),
          child: AnimatedSwitcher(
            duration: LuxeMotion.medium,
            switchInCurve: LuxeMotion.settle,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(index),
              child: widget.bodyOf(context, index),
            ),
          ),
        ),
      ],
    );
  }
}

/// Specification tabs with an animated switch between rows.
class LuxeSpecTabs extends StatelessWidget {
  const LuxeSpecTabs({required this.specs, super.key});

  final ProductTabbedSpecs specs;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final tabs = specs.tabs;

    List<LuxeSpecLine> lines(List<ProductSpec> rows) => [
      for (final r in rows) LuxeSpecLine(r.label, r.value),
    ];

    Widget body(BuildContext context, int index) {
      final tab = tabs[index];
      if (tab.isComment) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            tab.commentBody ?? 'No Comment Available',
            style: LuxeType.body(p.inkMuted, size: 14),
          ),
        );
      }
      if (tab.hasSections) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in tab.sections)
              LuxeSpecGroup(title: section.title, lines: lines(section.rows)),
          ],
        );
      }
      return LuxeSpecList(lines: lines(tab.rows));
    }

    return LuxeTabbedPanel(
      title: context.tr(DiamondFlowL10n.specifications),
      tabs: [for (final t in tabs) t.title],
      bodyOf: body,
    );
  }
}
