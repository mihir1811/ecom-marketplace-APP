import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../core/widgets/dark_theme_scope.dart';
import '../../../product_share/presentation/widgets/product_share_sheet.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../domain/models/product_detail.dart';
import '../widgets/product_detail_action_bar.dart';
import '../widgets/product_detail_assurance.dart';
import '../widgets/product_detail_header.dart';
import '../widgets/product_detail_highlights.dart';
import '../widgets/product_detail_media.dart';
import '../widgets/product_detail_price.dart';
import '../widgets/product_detail_specs.dart';

/// One product detail screen for every marketplace segment.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({required this.detail, super.key});

  static const double _wideBreakpoint = 900;
  static const double _maxContentWidth = 1120;

  final ProductDetail detail;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _recordedView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordRecentlyViewed());
  }

  void _recordRecentlyViewed() {
    if (_recordedView || !mounted) return;
    if (!ref.read(authProvider).isAuthenticated) return;
    _recordedView = true;
    recordRecentlyViewed(
      ref,
      productId: widget.detail.id,
      productType: widget.detail.apiProductType,
    );
  }

  List<Widget> _summaryBlocks(ProductDetail detail) {
    return [
      ProductDetailHeader(detail: detail),
      const SizedBox(height: AppSpacing.s24),
      ProductDetailPrice(detail: detail),
      const SizedBox(height: AppSpacing.s24),
      ProductDetailHighlights(highlights: detail.highlights),
      const SizedBox(height: AppSpacing.s16),
      ProductDetailAssurance(
        certification: detail.certification,
        availability: detail.availability,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final auth = ref.watch(
      authProvider.select(
        (s) => (isSeller: s.isSeller, showProtected: !s.isVerificationPending),
      ),
    );
    final visibleSpecs = detail.specsForViewer(isSeller: auth.isSeller);

    return DarkThemeScope(
      child: Builder(
        builder: (context) => _buildScaffold(context, detail, auth, visibleSpecs),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    ProductDetail detail,
    ({bool isSeller, bool showProtected}) auth,
    List<ProductSpecSection> visibleSpecs,
  ) {
    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          detail.segment.label,
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => showProductShareSheet(
              context: context,
              ref: ref,
              productId: detail.id,
              productType: detail.apiProductType,
              productTitle: detail.title,
            ),
          ),
        ],
      ),
      bottomNavigationBar: auth.showProtected
          ? ProductDetailActionBar(detail: detail)
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide =
              constraints.maxWidth >= ProductDetailScreen._wideBreakpoint;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ProductDetailScreen._maxContentWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s16,
                  AppSpacing.s16,
                  AppSpacing.s40,
                ),
                children: [
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: ProductDetailMedia(media: detail.media),
                        ),
                        const SizedBox(width: AppSpacing.s40),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _summaryBlocks(detail),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    ProductDetailMedia(media: detail.media),
                    const SizedBox(height: AppSpacing.s24),
                    ..._summaryBlocks(detail),
                  ],
                  const SizedBox(height: AppSpacing.s40),
                  for (final section in visibleSpecs) ...[
                    ProductDetailSpecSection(section: section),
                    const SizedBox(height: AppSpacing.s32),
                  ],
                  if (detail.note != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s8),
                      child: Text(
                        detail.note!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted(context),
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
