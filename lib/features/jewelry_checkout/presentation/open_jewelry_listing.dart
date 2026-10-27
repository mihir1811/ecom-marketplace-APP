import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/luxe/luxe_feedback.dart';
import '../../jewelry/data/repositories/jewelry_repository_impl.dart';
import '../../product_detail/product_detail_navigation.dart';

/// Opens the product page for a listing [slug] (bag lines, order items).
Future<void> openJewelryListing(
  BuildContext context,
  WidgetRef ref,
  String? slug,
) async {
  if (slug == null || slug.isEmpty) return;
  if (openRememberedProductDetail(context, slug)) return;
  final result = await ref.read(jewelryRepositoryProvider).getListing(slug);
  if (!context.mounted) return;
  switch (result) {
    case Success(value: final jewelry):
      openJewelryDetail(context, jewelry);
    case ResultFailure():
      showLuxeToast(
        context,
        context.tr(JewelryMarketL10n.pieceUnavailable),
        tone: LuxeTone.error,
      );
  }
}
