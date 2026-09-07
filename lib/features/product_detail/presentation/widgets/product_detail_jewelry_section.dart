import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../application/jewelry_config_draft_provider.dart';
import '../../domain/models/product_detail.dart';
import '../../domain/models/product_jewelry_detail.dart';
import 'product_detail_jewelry_configurator.dart';
import 'product_detail_jewelry_tabs.dart';

/// Jewelry content after seller: configurator + Details / Specs / Care tabs.
class ProductDetailJewelrySection extends ConsumerStatefulWidget {
  const ProductDetailJewelrySection({
    required this.detail,
    required this.jewelry,
    super.key,
  });

  final ProductDetail detail;
  final ProductJewelryDetail jewelry;

  @override
  ConsumerState<ProductDetailJewelrySection> createState() =>
      _ProductDetailJewelrySectionState();
}

class _ProductDetailJewelrySectionState
    extends ConsumerState<ProductDetailJewelrySection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(jewelryConfigDraftProvider(widget.detail.id).notifier)
          .ensureSeeded(widget.jewelry);
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(jewelryConfigDraftProvider(widget.detail.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductDetailJewelryConfigurator(
          productId: widget.detail.id,
          jewelry: widget.jewelry,
          draft: draft,
          priceOnRequest: widget.detail.price.isOnRequest,
        ),
        const SizedBox(height: AppSpacing.s32),
        ProductDetailJewelryTabs(
          detail: widget.detail,
          jewelry: widget.jewelry,
          draft: draft,
        ),
      ],
    );
  }
}
