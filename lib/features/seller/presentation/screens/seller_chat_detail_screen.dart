import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/account_nav.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/seller_chat_mock_data.dart';

class SellerChatDetailScreen extends StatefulWidget {
  const SellerChatDetailScreen({required this.chatId, super.key});

  final String chatId;

  @override
  State<SellerChatDetailScreen> createState() => _SellerChatDetailScreenState();
}

class _SellerChatDetailScreenState extends State<SellerChatDetailScreen> {
  final _messageCtrl = TextEditingController();
  late final List<SellerChatMessage> _messages;
  SellerChatThread? _chat;
  bool _productExpanded = true;

  static const _headerGreen = Color(0xFF1F5C57);
  static const _sentBubble = Color(0xFFD9FDD3);
  static const _chatBg = Color(0xFFEFEAE2);

  @override
  void initState() {
    super.initState();
    _chat = findSellerChatById(widget.chatId);
    _messages = List.of(_chat?.messages ?? const []);
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    setState(() {
      _messages.add(
        SellerChatMessage(
          text: text,
          time: '${two(now.hour)}:${two(now.minute)}',
          isMine: true,
        ),
      );
      _messageCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = _chat;
    if (chat == null) {
      return Center(
        child: TextButton(
          onPressed: () => context.go(
            messagesPathFor(GoRouterState.of(context).uri.path),
          ),
          child: const Text('Back to chats'),
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: _headerGreen,
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 10),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go(
                    messagesPathFor(GoRouterState.of(context).uri.path),
                  ),
                  icon: const Icon(Icons.arrow_back, color: AppColors.warmWhite),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.warmWhite,
                  child: Icon(
                    Icons.apartment,
                    color: Color(chat.avatarColor),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.buyerId,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warmWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${chat.isOnline ? 'online' : 'offline'} - Product #${chat.productId} - ${chat.productName}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warmWhite.withValues(alpha: 0.85),
                          fontSize: 11,
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
        Material(
          color: AppColors.sandSurface,
          child: InkWell(
            onTap: () => setState(() => _productExpanded = !_productExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product #${chat.productId} - ${chat.productName}',
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_productExpanded)
                          Text(
                            '${chat.productSubtitle} - ${chat.priceLabel}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _productExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: _chatBg,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.s16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Column(
                  children: [
                    if (msg.dateLabel != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warmWhite,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          msg.dateLabel!,
                          style: AppTypography.caption.copyWith(fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Align(
                      alignment: msg.isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                        decoration: BoxDecoration(
                          color: msg.isMine ? _sentBubble : AppColors.warmWhite,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                msg.text,
                                style: AppTypography.body.copyWith(fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  msg.time,
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 10,
                                    color: AppColors.textMutedLight,
                                  ),
                                ),
                                if (msg.isMine) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.done,
                                    size: 14,
                                    color: AppColors.success,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Container(
          color: AppColors.sandSurface,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      filled: true,
                      fillColor: AppColors.warmWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.warmWhite,
                  shape: const CircleBorder(),
                  elevation: 1,
                  child: IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.chat_bubble_outline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
