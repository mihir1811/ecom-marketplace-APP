import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../domain/models/product_detail.dart';
import '../widgets/product_detail_action_bar.dart';
import '../widgets/product_detail_assurance.dart';
import '../widgets/product_detail_header.dart';
import '../widgets/product_detail_highlights.dart';
import '../widgets/product_detail_media.dart';
import '../widgets/product_detail_price.dart';
import '../widgets/product_detail_seller_panel.dart';
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

  List<Widget> _summaryBlocks(
    ProductDetail detail, {
    required bool isSeller,
  }) {
    return [
      ProductDetailHeader(detail: detail),
      const SizedBox(height: AppSpacing.s24),
      ProductDetailPrice(detail: detail),
      const SizedBox(height: AppSpacing.s24),
      ProductDetailHighlights(highlights: detail.highlights),
      const SizedBox(height: AppSpacing.s16),
      ProductDetailAssurance(certification: detail.certification),
      if (isSeller && detail.listingSeller != null) ...[
        const SizedBox(height: AppSpacing.s24),
        ProductDetailSellerPanel(seller: detail.listingSeller!),
      ],
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

    return _buildScaffold(context, detail, auth, visibleSpecs);
  }

  Widget _buildScaffold(
    BuildContext context,
    ProductDetail detail,
    ({bool isSeller, bool showProtected}) auth,
    List<ProductSpecSection> visibleSpecs,
  ) {
    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppTopBar(
        title: detail.segment.label,
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
                          child: ProductDetailMedia(
                            media: detail.media,
                            availabilityStatus: detail.availabilityStatus,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s40),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _summaryBlocks(
                              detail,
                              isSeller: auth.isSeller,
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    ProductDetailMedia(
                      media: detail.media,
                      availabilityStatus: detail.availabilityStatus,
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    ..._summaryBlocks(detail, isSeller: auth.isSeller),
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
