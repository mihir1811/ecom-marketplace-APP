import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';
import '../../../buyer/application/wishlist_provider.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../chat/presentation/open_product_seller_chat.dart';
import '../../../product_share/presentation/widgets/product_share_sheet.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../domain/models/product_detail.dart';
import '../../domain/models/product_price_labels.dart';
import '../widgets/luxe/luxe_detail_gallery.dart';
import '../widgets/luxe/luxe_purchase_bar.dart';
import '../widgets/product_detail_natural_specs.dart';
import '../widgets/product_detail_seller_panel.dart';
import '../widgets/product_detail_suggested_products.dart';
import 'certificate_viewer_screen.dart';

/// Luxe stone detail shared by natural diamonds, lab-grown diamonds and
/// gemstones (single and melee).
///
/// Reading order follows the buying decision: the stone (gallery), what it
/// is (title, grades, badges), what it costs (price card), why to trust it
/// (at-a-glance grades, certificate), the full record (spec tabs), who sells
/// it, then related stones. The purchase bar stays pinned.
class StoneDetailScreen extends ConsumerStatefulWidget {
  const StoneDetailScreen({required this.detail, super.key});

  final ProductDetail detail;

  static bool supports(ProductDetail detail) =>
      detail.segment == ProductSegment.naturalDiamond ||
      detail.segment == ProductSegment.labGrownDiamond ||
      detail.segment == ProductSegment.gemstone;

  @override
  ConsumerState<StoneDetailScreen> createState() => _StoneDetailScreenState();
}

class _StoneDetailScreenState extends ConsumerState<StoneDetailScreen> {
  static const _wide = 900.0;
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);
  bool _recordedView = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _offset.value = _scroll.offset);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordView());
  }

  void _recordView() {
    if (_recordedView || !mounted) return;
    if (!ref.read(authProvider).isAuthenticated) return;
    _recordedView = true;
    recordRecentlyViewed(
      ref,
      productId: widget.detail.id,
      productType: widget.detail.apiProductType,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    final detail = widget.detail;
    final auth = ref.watch(
      authProvider.select(
        (s) => (isSeller: s.isSeller, showProtected: !s.isVerificationPending),
      ),
    );
    final unitKey = detail.price.unitLabel == null
        ? null
        : catalogDisplayMessageKeys[detail.price.unitLabel!];
    final labels = ProductPriceLabels.resolve(
      detail.price,
      grouped: true,
      localizedUnit: unitKey == null
          ? detail.price.unitLabel
          : context.tr(unitKey),
    );
    final topInset = MediaQuery.paddingOf(context).top + 60;

    return AppScaffold(
      backgroundColor: p.canvas,
      safeTop: false,
      bottomNavigationBar: auth.showProtected
          ? LuxePurchaseBar(detail: detail, priceLabels: labels)
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wide;
          final gallery = LuxeDetailGallery(
            media: detail.media,
            availabilityStatus: detail.availabilityStatus,
            topInset: wide ? 0 : topInset,
          );
          final summary = _Summary(detail: detail, labels: labels);
          final record = _Record(detail: detail, isSeller: auth.isSeller);

          final content = wide
              ? SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, topInset, 24, 40),
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
                                Expanded(flex: 5, child: summary),
                              ],
                            ),
                            const SizedBox(height: 32),
                            record,
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
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: summary,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      child: record,
                    ),
                  ],
                );

          return Stack(
            children: [
              CustomScrollView(
                controller: _scroll,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [content],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _FloatingHeader(
                  detail: detail,
                  offset: _offset,
                  solidAfter: wide ? 1 : constraints.maxWidth * 0.75,
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
class _FloatingHeader extends ConsumerStatefulWidget {
  const _FloatingHeader({
    required this.detail,
    required this.offset,
    required this.solidAfter,
  });

  final ProductDetail detail;
  final ValueListenable<double> offset;
  final double solidAfter;

  @override
  ConsumerState<_FloatingHeader> createState() => _FloatingHeaderState();
}

class _FloatingHeaderState extends ConsumerState<_FloatingHeader> {
  bool _openingChat = false;

  Future<void> _openChat() async {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    try {
      await openProductSellerChat(
        context,
        ref,
        productId: widget.detail.id,
        apiProductType: widget.detail.apiProductType,
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final detail = widget.detail;
    final top = MediaQuery.paddingOf(context).top;
    final saved = ref.watch(isInWishlistProvider(detail.id));
    final canChat = ref.watch(authProvider.select((s) => s.isSeller));

    return ValueListenableBuilder<double>(
      valueListenable: widget.offset,
      builder: (context, offset, _) {
        final t = ((offset - widget.solidAfter + 80) / 80).clamp(0.0, 1.0);
        final glass = t < 0.5;
        Widget bar = Container(
          padding: EdgeInsets.fromLTRB(12, top + 8, 12, 8),
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
                icon: Icons.arrow_back_rounded,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                glass: glass,
                size: 42,
                onPressed: () => context.goBack(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Opacity(
                  opacity: t,
                  child: Text(
                    detail.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.display(20, p.ink),
                  ),
                ),
              ),
              if (canChat) ...[
                LuxeIconButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: context.tr(CatalogL10n.chatWithSeller),
                  glass: glass,
                  size: 42,
                  loading: _openingChat,
                  onPressed: _openChat,
                ),
                const SizedBox(width: 8),
              ],
              LuxeIconButton(
                icon: Icons.ios_share_rounded,
                tooltip: context.tr(CatalogL10n.share),
                glass: glass,
                size: 42,
                onPressed: () => showProductShareSheet(
                  context: context,
                  ref: ref,
                  productId: detail.id,
                  productType: detail.apiProductType,
                  productTitle: detail.title,
                ),
              ),
              const SizedBox(width: 8),
              LuxeIconButton(
                icon: saved
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                tooltip: context.tr(HomeL10n.wishlist),
                glass: glass,
                active: saved,
                activeColor: const Color(0xFFE5484D),
                size: 42,
                onPressed: () =>
                    toggleWishlistItem(context, ref, detail.toWishlistItem()),
              ),
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
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: p.isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: bar,
        );
      },
    );
  }
}

/// Title, grades, badges, price card, at-a-glance grid and certificate.
class _Summary extends StatelessWidget {
  const _Summary({required this.detail, required this.labels});

  final ProductDetail detail;
  final ProductPriceLabels labels;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    Widget enter(Widget child, int i) => animate
        ? child
              .animate(delay: (80 + i * 70).ms)
              .fadeIn(duration: 500.ms)
              .moveY(
                begin: 12,
                end: 0,
                duration: 700.ms,
                curve: LuxeMotion.settle,
              )
        : child;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        enter(_Eyebrow(detail: detail), 0),
        const SizedBox(height: 8),
        enter(Text(detail.title, style: LuxeType.display(36, p.ink)), 1),
        const SizedBox(height: 6),
        enter(
          Text(detail.subtitle, style: LuxeType.body(p.inkMuted, size: 15)),
          2,
        ),
        if (detail.badges.isNotEmpty) ...[
          const SizedBox(height: 14),
          enter(
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final b in detail.badges) _Badge(badge: b)],
            ),
            3,
          ),
        ],
        const SizedBox(height: 20),
        enter(_PriceCard(labels: labels), 4),
        const SizedBox(height: 26),
        if (detail.highlights.isNotEmpty) ...[
          enter(_Glance(highlights: detail.highlights), 5),
          const SizedBox(height: 16),
        ],
        if (detail.certification != null &&
            !_isMissing(detail.certification!.authority))
          enter(_Certificate(cert: detail.certification!), 6),
      ],
    );
  }
}

bool _isMissing(String value) {
  final v = value.trim();
  return v.isEmpty ||
      v == 'N/A' ||
      v == '—' ||
      v == '-' ||
      // Uncertified stones: the spec tabs already state it plainly.
      v.toLowerCase() == 'not certified';
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.detail});

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
        Tooltip(
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
                  Text(
                    '#${detail.referenceValue}',
                    style: LuxeType.figure(p.inkMuted, size: 12),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.copy_rounded, size: 12, color: p.inkFaint),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.badge});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
      child: Text(badge.label, style: LuxeType.label(fg, size: 11.5)),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.labels});

  final ProductPriceLabels labels;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
                Text(
                  labels.list!,
                  style: LuxeType.label(p.inkFaint, size: 13).copyWith(
                    decoration: TextDecoration.lineThrough,
                    decorationColor: p.inkFaint,
                  ),
                ),
                if (labels.saveAmount != null) ...[
                  const SizedBox(width: 8),
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
          if (labels.hasDiscount) const SizedBox(height: 6),
          FittedBox(
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
          if (labels.unit != null) ...[
            const SizedBox(height: 4),
            Text(labels.unit!, style: LuxeType.label(p.inkMuted, size: 13)),
          ],
        ],
      ),
    );
  }
}

/// Four key grades as quiet tiles.
class _Glance extends StatelessWidget {
  const _Glance({required this.highlights});

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
        const SizedBox(height: 12),
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
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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

class _Certificate extends StatelessWidget {
  const _Certificate({required this.cert});

  final ProductCertification cert;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 14),
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
                        '${context.tr(DiamondFlowL10n.reportNumber)} '
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
            const SizedBox(height: 14),
            LuxeButton(
              label: context.tr(DiamondFlowL10n.viewCertificate),
              variant: LuxeButtonVariant.secondary,
              icon: Icons.open_in_new_rounded,
              height: 44,
              expand: true,
              onPressed: () => openCertificateViewer(
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

/// Melee quantity, spec tabs, seller, note and related stones.
class _Record extends StatelessWidget {
  const _Record({required this.detail, required this.isSeller});

  final ProductDetail detail;
  final bool isSeller;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final specs = detail.naturalSpecTabs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (specs?.meleeQty != null) ...[
          const SizedBox(height: 16),
          ProductMeleeQtySelector(
            productId: detail.id,
            qty: specs!.meleeQty!,
            lotPrice: detail.price.displayAmount,
            currencySymbol: detail.price.currencySymbol,
          ),
        ],
        if (specs != null && specs.tabs.isNotEmpty) ...[
          const SizedBox(height: 32),
          ScrollReveal(child: _SpecTabs(specs: specs)),
        ],
        if (detail.listingSeller != null &&
            detail.listingSeller!.hasAnyData) ...[
          const SizedBox(height: 28),
          ScrollReveal(
            child: ProductDetailSellerPanel(
              seller: detail.listingSeller!,
              // Individual viewers: name only. Business viewers: full contact
              // when the listing seller is also business.
              showContactDetails: isSeller,
            ),
          ),
        ],
        if (detail.note != null) ...[
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: p.inkFaint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detail.note!,
                  style: LuxeType.body(p.inkMuted, size: 12.5),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 36),
        ProductDetailSuggestedProducts(detail: detail),
      ],
    );
  }
}

/// Specification tabs with an animated switch between rows.
class _SpecTabs extends StatefulWidget {
  const _SpecTabs({required this.specs});

  final ProductTabbedSpecs specs;

  @override
  State<_SpecTabs> createState() => _SpecTabsState();
}

class _SpecTabsState extends State<_SpecTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final tabs = widget.specs.tabs;
    final index = _index.clamp(0, tabs.length - 1);
    final tab = tabs[index];

    Widget rows(List<ProductSpec> specs) => Column(
      children: [
        for (var i = 0; i < specs.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: i == specs.length - 1
                  ? null
                  : Border(bottom: BorderSide(color: p.hairline, width: 0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    specs[i].label,
                    style: LuxeType.label(p.inkMuted, size: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    specs[i].value,
                    textAlign: TextAlign.right,
                    style: LuxeType.label(p.ink, size: 13.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    final Widget body;
    if (tab.isComment) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          tab.commentBody ?? 'No Comment Available',
          style: LuxeType.body(p.inkMuted, size: 14),
        ),
      );
    } else if (tab.hasSections) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final section in tab.sections) ...[
            const SizedBox(height: 14),
            Text(
              section.title.toUpperCase(),
              style: LuxeType.eyebrow(p.accent),
            ),
            rows(section.rows),
          ],
        ],
      );
    } else {
      body = rows(tab.rows);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(DiamondFlowL10n.specifications),
          style: LuxeType.display(28, p.ink),
        ),
        const SizedBox(height: 14),
        if (tabs.length > 1)
          tabs.length <= 3
              ? LuxeSegmented<int>(
                  options: [for (var i = 0; i < tabs.length; i++) i],
                  selected: index,
                  onChanged: (i) => setState(() => _index = i),
                  labelOf: (i) => tabs[i].title,
                  dense: true,
                )
              : SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: tabs.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => ChoiceChip(
                      label: Text(tabs[i].title),
                      selected: i == index,
                      onSelected: (_) {
                        AppHaptics.selection();
                        setState(() => _index = i);
                      },
                    ),
                  ),
                ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
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
            child: KeyedSubtree(key: ValueKey(index), child: body),
          ),
        ),
      ],
    );
  }
}
