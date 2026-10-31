import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/atelier_palette.dart';
import '../../product_detail/open_catalog_product_detail.dart';
import '../../seller/presentation/atelier/atelier_feedback.dart';
import '../domain/models/product_chat_context.dart';

/// Opens the full product detail page for the piece a chat thread is about.
Future<void> openChatProductDetail(
  BuildContext context,
  WidgetRef ref,
  ProductChatContext ctx,
) async {
  if (ctx.productId.trim().isEmpty) return;
  final opened = await openCatalogProductDetail(
    context,
    ref,
    productType: ctx.productType.apiValue,
    productId: ctx.productId,
  );
  if (opened || !context.mounted) return;
  showAtelierToast(
    context,
    context.tr(AccountCommerceL10n.productOpenFailed),
    tone: AtelierTone.ruby,
  );
}
