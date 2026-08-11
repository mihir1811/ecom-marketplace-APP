import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/result.dart';
import '../../../core/router/route_names.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../domain/models/chat_product_type.dart';
import '../domain/models/chat_thread.dart';

/// Opens (or starts) the product conversation with the listing seller.
///
/// Chat is seller-only; normal (buyer) accounts cannot start conversations.
Future<void> openProductSellerChat(
  BuildContext context,
  WidgetRef ref, {
  required String productId,
  required String apiProductType,
}) async {
  final auth = ref.read(authProvider);
  if (!auth.isAuthenticated) {
    await context.push(AppRouteNames.login);
    return;
  }

  if (!auth.isSeller) {
    _snack(context, 'Chat is available for seller accounts only.');
    return;
  }

  final productType = ChatProductType.fromApi(apiProductType);
  if (productType == null) {
    _snack(context, 'Chat is not available for this product type.');
    return;
  }

  final result = await ref.read(chatRepositoryProvider).getProductContext(
        productId: productId,
        productType: productType,
      );

  if (!context.mounted) return;

  switch (result) {
    case Success(value: final ctx):
      final sellerUserId = ctx.sellerUserId.trim();
      if (sellerUserId.isEmpty) {
        _snack(context, 'Seller is not available for chat.');
        return;
      }
      if (sellerUserId == auth.user?.id) {
        _snack(context, 'This is your own listing.');
        return;
      }

      final threadId = ChatThread.encodeId(
        productType: productType,
        productId: productId,
        peerUserId: sellerUserId,
      );

      final path = AppRouteNames.sellerChatDetailPath(threadId);
      await context.push(path);
    case ResultFailure(failure: final failure):
      _snack(context, failure.message);
  }
}

void _snack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(SnackBar(content: Text(message)));
}
