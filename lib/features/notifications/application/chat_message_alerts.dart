import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/route_names.dart';
import '../../chat/application/chat_providers.dart';
import '../../chat/data/repositories/chat_repository_impl.dart';
import '../../chat/domain/models/chat_thread.dart';
import '../data/mappers/notification_mapper.dart';
import 'in_app_notification_provider.dart';

/// Shows a top banner for every chat message that arrives on the chat
/// socket while signed in, whatever screen is open.
///
/// Keeps the chat socket connected for the whole session (through
/// [chatInboxProvider]) instead of only while a screen happens to watch the
/// inbox. Events are pushed by the server; nothing here polls.
final chatMessageAlertsProvider = Provider<void>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  if (userId == null || userId.isEmpty) return;

  // Building the inbox connects and registers the socket for this user.
  ref.listen(chatInboxProvider, (_, _) {});

  final repo = ref.watch(chatRepositoryProvider);
  final sub = repo.incomingMessages.listen((message) {
    // Only messages sent to this user by someone else.
    if (message.isMine || message.toId != userId) return;
    if (isViewingChatWith(
      senderId: message.fromId,
      productId: message.productId,
    )) {
      // The open conversation already shows it.
      return;
    }
    ref
        .read(inAppNotificationProvider.notifier)
        .show(NotificationMapper.fromChatMessage(message));
  });
  ref.onDispose(sub.cancel);
});

/// Whether the conversation with [senderId] (about [productId], when given)
/// is the screen on top right now.
bool isViewingChatWith({required String senderId, String? productId}) {
  if (senderId.isEmpty) return false;
  final String path;
  try {
    path = appRouter.routerDelegate.currentConfiguration.uri.path;
  } catch (_) {
    return false;
  }
  final thread = activeChatThread(path);
  if (thread == null || thread.peerUserId != senderId) return false;
  return productId == null ||
      productId.isEmpty ||
      thread.productId == productId;
}

/// The chat thread encoded in a chat detail [path], or `null`.
({String productId, String peerUserId})? activeChatThread(String path) {
  for (final prefix in [
    '${AppRouteNames.buyerMessages}/',
    '${AppRouteNames.sellerChat}/',
  ]) {
    if (!path.startsWith(prefix)) continue;
    final segment = path.substring(prefix.length).split('/').first;
    if (segment.isEmpty) return null;
    final decoded = ChatThread.decodeId(Uri.decodeComponent(segment));
    if (decoded == null) return null;
    return (productId: decoded.productId, peerUserId: decoded.peerUserId);
  }
  return null;
}
