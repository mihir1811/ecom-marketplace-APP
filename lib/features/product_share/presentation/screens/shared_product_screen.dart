import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
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
        backgroundColor: AppColors.bg(context),
        appBar: SimpleAppTopBar(
          title: context.tr(CatalogL10n.sharedProduct),
          backgroundColor: AppColors.bg(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) {
        final message = e is Failure
            ? e.message
            : context.tr(CatalogL10n.shareInvalidOrExpired);
        return AppScaffold(
          backgroundColor: AppColors.bg(context),
          appBar: SimpleAppTopBar(
            title: context.tr(CatalogL10n.sharedProduct),
            backgroundColor: AppColors.bg(context),
          ),
          body: CatalogEmptyState(
            icon: Icons.link_off_outlined,
            title: context.tr(CatalogL10n.shareUnavailable),
            message: message,
            actionLabel: context.tr(CatalogL10n.browseCatalog),
            onAction: () => context.resetTo(AppRouteNames.home),
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
