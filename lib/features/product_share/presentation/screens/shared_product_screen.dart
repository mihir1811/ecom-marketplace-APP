import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/shared_product_resolver.dart';

/// Resolves `GET /product-share/{token}` and opens the shared product in-app.
class SharedProductScreen extends ConsumerStatefulWidget {
  const SharedProductScreen({required this.token, super.key});

  final String token;

  @override
  ConsumerState<SharedProductScreen> createState() =>
      _SharedProductScreenState();
}

class _SharedProductScreenState extends ConsumerState<SharedProductScreen> {
  var _navigated = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sharedProductDetailProvider(widget.token));

    ref.listen(sharedProductDetailProvider(widget.token), (prev, next) {
      next.whenData((detail) {
        if (_navigated || !mounted) return;
        _navigated = true;
        rememberProductDetail(detail);
        context.go(
          AppRouteNames.productDetailPath(detail.segment.slug, detail.id),
          extra: detail,
        );
      });
    });

    return AppScaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRouteNames.home),
        ),
        title: Text(
          'Shared product',
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final message = e is Failure
              ? e.message
              : 'This share link is invalid or expired.';
          return CatalogEmptyState(
            icon: Icons.link_off_outlined,
            title: 'Share link unavailable',
            message: message,
            actionLabel: 'Browse catalog',
            onAction: () => context.go(AppRouteNames.home),
          );
        },
        data: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
