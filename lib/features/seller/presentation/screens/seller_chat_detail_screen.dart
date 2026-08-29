import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../../chat/application/chat_providers.dart';
import '../../../chat/domain/models/chat_message.dart';
import '../../../chat/domain/models/chat_thread.dart';
import '../../../chat/domain/models/product_chat_context.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/remaining_messages.dart';

class SellerChatDetailScreen extends ConsumerStatefulWidget {
  const SellerChatDetailScreen({required this.chatId, super.key});

  final String chatId;

  @override
  ConsumerState<SellerChatDetailScreen> createState() =>
      _SellerChatDetailScreenState();
}

class _SellerChatDetailScreenState
    extends ConsumerState<SellerChatDetailScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final ChatThreadArgs? _args;

  @override
  void initState() {
    super.initState();
    final rawId = Uri.decodeComponent(widget.chatId);
    final decoded = ChatThread.decodeId(rawId);
    _args = decoded == null
        ? null
        : ChatThreadArgs(
            threadId: rawId,
            productId: decoded.productId,
            productTypeApi: decoded.productType.apiValue,
            peerUserId: decoded.peerUserId,
          );
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final args = _args;
    if (args == null) return;
    final text = _messageCtrl.text;
    if (text.trim().isEmpty) return;
    _messageCtrl.clear();
    await ref.read(chatThreadProvider(args).notifier).sendText(text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    if (args == null) {
      return CatalogEmptyState(
        title: context.tr(RemainingL10n.conversationNotFound),
        message: context.tr(RemainingL10n.threadInvalid),
        actionLabel: context.tr(RemainingL10n.backToMessages),
        onAction: () => context.goBack(),
      );
    }

    final state = ref.watch(chatThreadProvider(args));
    final peerName =
        state.context?.sellerName.isNotEmpty == true && state.messages.isEmpty
        ? state.context!.sellerName
        : _peerName(state.messages, args.peerUserId);

    return ColoredBox(
      color: AppColors.bg(context),
      child: Column(
        children: [
          _ThreadHeader(
            peerName: peerName,
            productLabel:
                state.context?.productName ??
                '${args.productTypeApi} · ${args.productId}',
            onBack: () => context.goBack(),
          ),
          if (state.context != null) _ProductStrip(contextData: state.context!),
          Expanded(child: _messagesBody(state, args)),
          _Composer(
            controller: _messageCtrl,
            isSending: state.isSending,
            sendError: state.sendError,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Widget _messagesBody(ChatThreadState state, ChatThreadArgs args) {
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (state.errorMessage != null && state.messages.isEmpty) {
      return CatalogErrorState(
        message: state.errorMessage!,
        onRetry: () => ref.read(chatThreadProvider(args).notifier).refresh(),
      );
    }
    if (state.messages.isEmpty) {
      return CatalogEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: context.tr(RemainingL10n.startConversation),
        message: context.tr(RemainingL10n.keepItShortAskAboutAvailabilitySpecs),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s16,
        AppSpacing.s16,
      ),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final msg = state.messages[index];
        final prev = index > 0 ? state.messages[index - 1] : null;
        final showDate =
            prev == null ||
            !_sameDay(prev.createdAt.toLocal(), msg.createdAt.toLocal());
        return Column(
          children: [
            if (showDate) _DateChip(date: msg.createdAt.toLocal()),
            _MessageBubble(message: msg),
          ],
        );
      },
    );
  }

  String _peerName(List<ChatMessage> messages, String peerId) {
    for (final m in messages.reversed) {
      if (m.from?.id == peerId && (m.from?.name.isNotEmpty ?? false)) {
        return m.from!.name;
      }
      if (m.to?.id == peerId && (m.to?.name.isNotEmpty ?? false)) {
        return m.to!.name;
      }
    }
    return context.tr(RemainingL10n.conversation);
  }
}

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({
    required this.peerName,
    required this.productLabel,
    required this.onBack,
  });

  final String peerName;
  final String productLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 10),
          child: Row(
            children: [
              TextButton(
                onPressed: onBack,
                child: Text(context.tr(RemainingL10n.inbox)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peerName,
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      productLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductStrip extends StatelessWidget {
  const _ProductStrip({required this.contextData});

  final ProductChatContext contextData;

  @override
  Widget build(BuildContext context) {
    final image = contextData.primaryImage;
    final price = contextData.productPrice;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(bottom: BorderSide(color: AppColors.border(context))),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: image == null || image.isEmpty
                  ? ColoredBox(
                      color: AppColors.border(context),
                      child: Icon(
                        Icons.diamond_outlined,
                        size: 20,
                        color: AppColors.textMuted(context),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: AppColors.border(context),
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 18,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contextData.productName,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (contextData.stockNumber != null &&
                        contextData.stockNumber!.isNotEmpty)
                      contextData.stockNumber!,
                    if (price != null) AppCurrency.format(price),
                  ].join(' · '),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    final time = message.createdAt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.s8),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: mine
                ? (AppColors.isDark(context)
                      ? AppColors.slateBorder
                      : AppColors.charcoal)
                : AppColors.card(context),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppSpacing.r16),
              topRight: const Radius.circular(AppSpacing.r16),
              bottomLeft: Radius.circular(
                mine ? AppSpacing.r16 : AppSpacing.r4,
              ),
              bottomRight: Radius.circular(
                mine ? AppSpacing.r4 : AppSpacing.r16,
              ),
            ),
            border: mine ? null : Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.body.isEmpty
                      ? (message.messageType == ChatMessageType.image
                            ? context.tr(RemainingL10n.photo)
                            : context.tr(RemainingL10n.attachment))
                      : message.body,
                  style: AppTypography.body.copyWith(
                    fontSize: 14,
                    height: 1.35,
                    color: mine
                        ? AppColors.warmWhite
                        : AppColors.textPrimary(context),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${two(time.hour)}:${two(time.minute)}',
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  color: mine
                      ? AppColors.warmWhite.withValues(alpha: 0.65)
                      : AppColors.textMuted(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
      child: Text(
        _label(context, date),
        style: AppTypography.caption.copyWith(
          color: AppColors.textMuted(context),
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  String _label(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return context.tr(RemainingL10n.today);
    if (day == today.subtract(const Duration(days: 1)))
      return context.tr(RemainingL10n.yesterday);
    final months = [
      context.tr(RemainingL10n.januaryShort),
      context.tr(RemainingL10n.februaryShort),
      context.tr(RemainingL10n.marchShort),
      context.tr(RemainingL10n.aprilShort),
      context.tr(RemainingL10n.mayShort),
      context.tr(RemainingL10n.juneShort),
      context.tr(RemainingL10n.julyShort),
      context.tr(RemainingL10n.augustShort),
      context.tr(RemainingL10n.septemberShort),
      context.tr(RemainingL10n.octoberShort),
      context.tr(RemainingL10n.novemberShort),
      context.tr(RemainingL10n.decemberShort),
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
    this.sendError,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final String? sendError;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s12,
            AppSpacing.s12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sendError != null) ...[
                Text(
                  sendError!,
                  style: AppTypography.caption.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 6),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                      onSubmitted: (_) => onSend(),
                      decoration: InputDecoration(
                        hintText: context.tr(RemainingL10n.writeMessage),
                        hintStyle: AppTypography.body.copyWith(
                          color: AppColors.textMuted(context),
                        ),
                        filled: true,
                        fillColor: AppColors.surface(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.r16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  IconButton.filled(
                    onPressed: isSending ? null : onSend,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.charcoal,
                      foregroundColor: AppColors.warmWhite,
                      disabledBackgroundColor: AppColors.charcoal.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    icon: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.warmWhite,
                            ),
                          )
                        : const Icon(Icons.arrow_upward_rounded, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
