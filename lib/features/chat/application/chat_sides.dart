import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/result.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../domain/models/chat_product_type.dart';
import '../domain/models/chat_thread.dart';
import 'chat_providers.dart';

/// Owner (seller user id) of a chatted product, fetched once per product
/// from the existing product-context endpoint; `null` when it can't be
/// resolved.
final chatProductOwnerProvider =
    FutureProvider.family<
      String?,
      ({String productId, ChatProductType productType})
    >((ref, key) async {
      final result = await ref
          .read(chatRepositoryProvider)
          .getProductContext(
            productId: key.productId,
            productType: key.productType,
          );
      return switch (result) {
        Success(:final value) =>
          value.sellerUserId.trim().isEmpty ? null : value.sellerUserId.trim(),
        ResultFailure() => null,
      };
    });

/// The buyer's own inbox: conversations about pieces listed by the other
/// person (the user is the one buying). Threads about the user's own
/// listings belong to the seller inbox and are left out.
class BuyerInboxView {
  const BuyerInboxView({
    required this.inbox,
    required this.threads,
    required this.resolving,
  });

  final ChatInboxState inbox;
  final List<ChatThread> threads;

  /// True while some threads' product owners are still being looked up.
  final bool resolving;
}

final buyerChatInboxProvider = Provider<BuyerInboxView>((ref) {
  final inbox = ref.watch(chatInboxProvider);
  final me = ref.watch(authProvider.select((s) => s.user?.id)) ?? '';
  final threads = <ChatThread>[];
  var resolving = false;
  for (final t in inbox.threads) {
    final owner = ref.watch(
      chatProductOwnerProvider((
        productId: t.productId,
        productType: t.productType,
      )),
    );
    switch (owner) {
      case AsyncData(:final value):
        // Unknown owner: keep the conversation rather than hide it.
        if (value == null || value != me) threads.add(t);
      case AsyncError():
        threads.add(t);
      default:
        resolving = true;
    }
  }
  return BuyerInboxView(inbox: inbox, threads: threads, resolving: resolving);
});
