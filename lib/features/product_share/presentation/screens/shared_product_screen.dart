import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../product_detail/presentation/screens/product_detail_screen.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/shared_product_resolver.dart';

/// Resolves `GET /product-share/{token}` and shows the shared product in-app.
///
/// Keeps `/share/:token` in the address bar so refresh reloads the share
/// payload (with includePrice / images / videos flags) instead of a cold
/// catalog deep link.
class SharedProductScreen extends ConsumerWidget {
  const SharedProductScreen({required this.token, super.key});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sharedProductDetailProvider(token));

    return async.when(
      loading: () => AppScaffold(
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
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) {
        final message = e is Failure
            ? e.message
            : 'This share link is invalid or expired.';
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
          body: CatalogEmptyState(
            icon: Icons.link_off_outlined,
            title: 'Share link unavailable',
            message: message,
            actionLabel: 'Browse catalog',
            onAction: () => context.go(AppRouteNames.home),
          ),
        );
      },
      data: (detail) {
        rememberProductDetail(detail);
        return ProductDetailScreen(detail: detail);
      },
    );
  }
}
