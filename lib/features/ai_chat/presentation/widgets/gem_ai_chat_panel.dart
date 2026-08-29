import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/keyboard_aware.dart';
import '../../application/ai_chat_providers.dart';
import '../../domain/models/ai_chat_language.dart';
import '../../domain/models/ai_chat_message.dart';
import '../../domain/models/ai_chat_reply.dart';
import 'ai_chat_product_list_section.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/remaining_messages.dart';

class GemAiChatPanel extends ConsumerStatefulWidget {
  const GemAiChatPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<GemAiChatPanel> createState() => _GemAiChatPanelState();
}

class _GemAiChatPanelState extends ConsumerState<GemAiChatPanel> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  bool _languageMenuOpen = false;

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      if (!position.hasContentDimensions) return;
      _scroll.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _composer.text;
    _composer.clear();
    await ref.read(aiChatPanelProvider.notifier).sendMessage(text);
    _scrollToEnd();
  }

  void _closeLanguageMenu() {
    if (!_languageMenuOpen) return;
    setState(() => _languageMenuOpen = false);
  }

  void _selectLanguage(AiChatLanguage language) {
    ref.read(aiChatPanelProvider.notifier).setLanguage(language);
    _closeLanguageMenu();
  }

  @override
  Widget build(BuildContext context) {
    final panel = ref.watch(aiChatPanelProvider);
    final ui = ref.watch(aiChatUiProvider);
    ref.listen(aiChatPanelProvider.select((s) => s.messages.length), (_, __) {
      _scrollToEnd();
    });

    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final panelWidth = size.width < 520 ? size.width - 24.0 : 400.0;
    final bottomGap = AppKeyboard.overlayBottomGap(
      keyboardInset: keyboard,
      safeBottom: padding.bottom,
    );
    final panelHeight = (size.height - bottomGap - padding.top - 24).clamp(
      200.0,
      size.height * 0.78,
    );

    return _buildPanel(
      context: context,
      panel: panel,
      ui: ui,
      panelWidth: panelWidth,
      panelHeight: panelHeight,
      bottomGap: bottomGap,
    );
  }

  Widget _buildPanel({
    required BuildContext context,
    required AiChatPanelState panel,
    required AiChatUiState ui,
    required double panelWidth,
    required double panelHeight,
    required double bottomGap,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.bottomRight,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s16,
            AppSpacing.s16,
            bottomGap,
          ),
          child: SizedBox(
            width: panelWidth,
            height: panelHeight,
            child: Material(
              color: AppColors.card(context),
              elevation: 16,
              shadowColor: AppColors.charcoal.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppSpacing.r24),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Column(
                    children: [
                      _Header(
                        onClose: () {
                          _closeLanguageMenu();
                          widget.onClose();
                        },
                        onHistory: () async {
                          _closeLanguageMenu();
                          ref.read(aiChatUiProvider.notifier).showHistory();
                          await ref
                              .read(aiChatPanelProvider.notifier)
                              .loadHistory();
                        },
                        onNewChat: () {
                          _closeLanguageMenu();
                          ref.read(aiChatPanelProvider.notifier).startNewChat();
                        },
                        language: panel.language,
                        languageMenuOpen: _languageMenuOpen,
                        onToggleLanguageMenu: () {
                          setState(
                            () => _languageMenuOpen = !_languageMenuOpen,
                          );
                        },
                      ),
                      if (panel.errorMessage != null)
                        _ErrorBanner(
                          message: panel.errorMessage!,
                          onDismiss: () => ref
                              .read(aiChatPanelProvider.notifier)
                              .clearError(),
                        ),
                      Expanded(
                        child: ui.showHistory
                            ? _HistoryView(
                                sessions: panel.sessions,
                                loading: panel.isLoadingHistory,
                                onBack: () => ref
                                    .read(aiChatUiProvider.notifier)
                                    .hideHistory(),
                                onOpen: (id) async {
                                  await ref
                                      .read(aiChatPanelProvider.notifier)
                                      .openSession(id);
                                  ref
                                      .read(aiChatUiProvider.notifier)
                                      .hideHistory();
                                  _scrollToEnd();
                                },
                              )
                            : _MessagesView(
                                scrollController: _scroll,
                                messages: panel.messages,
                                isSending: panel.isSending,
                                isLoadingSession: panel.isLoadingSession,
                                onClosePanel: widget.onClose,
                              ),
                      ),
                      if (!ui.showHistory)
                        _Composer(
                          controller: _composer,
                          enabled: !panel.isSending && !panel.isUploading,
                          isUploading: panel.isUploading,
                          pendingImageName: panel.pendingImageName,
                          onAttach: () => ref
                              .read(aiChatPanelProvider.notifier)
                              .pickAndUploadImage(),
                          onClearImage: () => ref
                              .read(aiChatPanelProvider.notifier)
                              .clearPendingImage(),
                          onSend: _send,
                        ),
                    ],
                  ),
                  if (_languageMenuOpen) ...[
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _closeLanguageMenu,
                        child: const ColoredBox(color: Colors.transparent),
                      ),
                    ),
                    Positioned(
                      top: 72,
                      right: AppSpacing.s12,
                      child: _LanguageMenuPanel(
                        language: panel.language,
                        onSelect: _selectLanguage,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onClose,
    required this.onHistory,
    required this.onNewChat,
    required this.language,
    required this.languageMenuOpen,
    required this.onToggleLanguageMenu,
  });

  final VoidCallback onClose;
  final VoidCallback onHistory;
  final VoidCallback onNewChat;
  final AiChatLanguage language;
  final bool languageMenuOpen;
  final VoidCallback onToggleLanguageMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s24,
        AppSpacing.s20,
        AppSpacing.s12,
        AppSpacing.s16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2330), AppColors.charcoal, Color(0xFF6E4C2E)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bronze.withValues(alpha: 0.25),
              border: Border.all(
                color: AppColors.bronzeLight.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.bronzeLight,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(RemainingL10n.gemAi),
                  style: AppTypography.title.copyWith(
                    color: AppColors.warmWhite,
                    fontSize: 17,
                  ),
                ),
                Text(
                  context.tr(RemainingL10n.gemAiSearchSubtitle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.bronzeLight,
                  ),
                ),
              ],
            ),
          ),
          _LanguageDropdownButton(
            language: language,
            isOpen: languageMenuOpen,
            onPressed: onToggleLanguageMenu,
          ),
          IconButton(
            onPressed: onHistory,
            icon: const Icon(Icons.history_rounded, color: AppColors.warmWhite),
          ),
          IconButton(
            onPressed: onNewChat,
            icon: const Icon(
              Icons.add_comment_outlined,
              color: AppColors.warmWhite,
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: AppColors.warmWhite),
          ),
        ],
      ),
    );
  }
}

class _LanguageDropdownButton extends StatelessWidget {
  const _LanguageDropdownButton({
    required this.language,
    required this.isOpen,
    required this.onPressed,
  });

  final AiChatLanguage language;
  final bool isOpen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.r20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          decoration: BoxDecoration(
            color: AppColors.warmWhite.withValues(alpha: isOpen ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.r20),
            border: Border.all(
              color: AppColors.bronzeLight.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                language.apiValue.toUpperCase(),
                style: AppTypography.caption.copyWith(
                  color: AppColors.warmWhite,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isOpen
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.warmWhite.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageMenuPanel extends StatelessWidget {
  const _LanguageMenuPanel({required this.language, required this.onSelect});

  final AiChatLanguage language;
  final ValueChanged<AiChatLanguage> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      shadowColor: AppColors.charcoal.withValues(alpha: 0.28),
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(AppSpacing.r12),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < AiChatLanguage.values.length; i++) ...[
              if (i > 0) Divider(height: 1, color: AppColors.border(context)),
              _LanguageMenuItem(
                language: AiChatLanguage.values[i],
                selected: AiChatLanguage.values[i] == language,
                onTap: () => onSelect(AiChatLanguage.values[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageMenuItem extends StatelessWidget {
  const _LanguageMenuItem({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AiChatLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.bronze,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              language.label,
              style: AppTypography.body.copyWith(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Text(
              language.apiValue.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                message,
                style: AppTypography.caption.copyWith(color: AppColors.error),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 16, color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesView extends StatelessWidget {
  const _MessagesView({
    required this.scrollController,
    required this.messages,
    required this.isSending,
    required this.isLoadingSession,
    required this.onClosePanel,
  });

  final ScrollController scrollController;
  final List<AiChatMessage> messages;
  final bool isSending;
  final bool isLoadingSession;
  final VoidCallback onClosePanel;

  @override
  Widget build(BuildContext context) {
    if (isLoadingSession) {
      return const Center(child: CircularProgressIndicator());
    }
    if (messages.isEmpty && !isSending) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.diamond_outlined,
              size: 40,
              color: AppColors.bronze.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              context.tr(RemainingL10n.askForDiamondsMeleeGemstonesJewelleryOr),
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s8,
      ),
      itemCount: messages.length + (isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= messages.length) {
          return const _TypingBubble();
        }
        return _MessageBubble(
          message: messages[index],
          sourceQuery: _sourceQueryFor(messages, index),
          onClosePanel: onClosePanel,
        );
      },
    );
  }

  static String _sourceQueryFor(List<AiChatMessage> messages, int index) {
    final current = messages[index];
    if (current.sourceQuery.trim().isNotEmpty) return current.sourceQuery;
    for (var i = index - 1; i >= 0; i--) {
      if (messages[i].role == AiChatRole.user) {
        return messages[i].content;
      }
    }
    return '';
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s12),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r16),
        ),
        child: Text(
          context.tr(RemainingL10n.gemAiIsSearching),
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.sourceQuery,
    required this.onClosePanel,
  });

  final AiChatMessage message;
  final String sourceQuery;
  final VoidCallback onClosePanel;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiChatRole.user;
    final products = message.products.isNotEmpty
        ? message.products
        : message.productGroups.expand((g) => g.products).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isUser
                    ? MediaQuery.sizeOf(context).width * 0.78
                    : double.infinity,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: isUser
                      ? (AppColors.isDark(context)
                            ? AppColors.slateBorder
                            : AppColors.charcoal)
                      : AppColors.surface(context),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppSpacing.r16),
                    topRight: const Radius.circular(AppSpacing.r16),
                    bottomLeft: Radius.circular(
                      isUser ? AppSpacing.r16 : AppSpacing.r4,
                    ),
                    bottomRight: Radius.circular(
                      isUser ? AppSpacing.r4 : AppSpacing.r16,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.imageUrls.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.r12),
                        child: CachedNetworkImage(
                          imageUrl: message.imageUrls.first,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const SizedBox(
                            height: 72,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                    ],
                    SelectableText(
                      message.content,
                      style: AppTypography.body.copyWith(
                        color: isUser
                            ? AppColors.warmWhite
                            : AppColors.textPrimary(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isUser && products.isNotEmpty)
            AiChatProductListSection(
              products: products,
              productGroups: message.productGroups,
              totalFound: message.totalFound,
              sourceQuery: sourceQuery,
              onBeforeOpen: onClosePanel,
            ),
        ],
      ),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView({
    required this.sessions,
    required this.loading,
    required this.onBack,
    required this.onOpen,
  });

  final List<AiChatSessionSummary> sessions;
  final bool loading;
  final VoidCallback onBack;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s8,
              AppSpacing.s8,
              AppSpacing.s16,
              AppSpacing.s8,
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: onBack,
                  child: Text(context.tr(RemainingL10n.backToChat)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(RemainingL10n.chatHistory),
                        style: AppTypography.title.copyWith(
                          fontSize: 16,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      Text(
                        loading
                            ? context.tr(RemainingL10n.loadingSessions)
                            : sessions.isEmpty
                            ? context.tr(RemainingL10n.noConversations)
                            : context.tr(RemainingL10n.conversationsCount, {
                                'count': sessions.length,
                              }),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : sessions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.bronze.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.forum_outlined,
                              color: AppColors.bronze,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          Text(
                            context.tr(RemainingL10n.noSavedChats),
                            style: AppTypography.title.copyWith(
                              fontSize: 15,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            context.tr(RemainingL10n.savedChatsEmptyBody),
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      AppSpacing.s4,
                      AppSpacing.s16,
                      AppSpacing.s24,
                    ),
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.s12),
                    itemBuilder: (context, index) {
                      return _HistorySessionCard(
                        session: sessions[index],
                        onOpen: onOpen,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistorySessionCard extends StatelessWidget {
  const _HistorySessionCard({required this.session, required this.onOpen});

  final AiChatSessionSummary session;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final title = session.title.trim().isEmpty
        ? context.tr(RemainingL10n.untitledChat)
        : session.title;
    final preview = session.preview.trim().isEmpty
        ? context.tr(RemainingL10n.noMessagePreview)
        : session.preview.trim();
    final when = _formatSessionDate(
      context,
      session.updatedAt ?? session.createdAt,
    );

    return Material(
      color: AppColors.card(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        side: BorderSide(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onOpen(session.sessionId),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: AppColors.bronze),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s12,
                    AppSpacing.s12,
                    AppSpacing.s12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.r12,
                              ),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16,
                              color: AppColors.bronze,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.title.copyWith(
                                fontSize: 14,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ),
                          if (session.messageCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.isDark(context)
                                    ? AppColors.slateBorder
                                    : AppColors.charcoal.withValues(
                                        alpha: 0.08,
                                      ),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.r20,
                                ),
                              ),
                              child: Text(
                                '${session.messageCount} msg'
                                '${session.messageCount == 1 ? '' : 's'}',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary(context),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      if (when != null) ...[
                        const SizedBox(height: AppSpacing.s8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: AppColors.textSecondary(
                                context,
                              ).withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              when,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary(context),
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.textSecondary(
                                context,
                              ).withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _formatSessionDate(BuildContext context, DateTime? value) {
    if (value == null) return null;
    final local = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    if (diff == 0) {
      return context.tr(RemainingL10n.todayTime, {'time': time});
    }
    if (diff == 1) {
      return context.tr(RemainingL10n.yesterdayTime, {'time': time});
    }
    if (diff < 7) {
      return context.tr(RemainingL10n.daysAgoTime, {
        'count': diff,
        'time': time,
      });
    }
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} · $time';
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.isUploading,
    required this.pendingImageName,
    required this.onAttach,
    required this.onClearImage,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isUploading;
  final String? pendingImageName;
  final VoidCallback onAttach;
  final VoidCallback onClearImage;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s12,
          AppSpacing.s12,
          AppSpacing.s12,
          AppSpacing.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pendingImageName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      size: 16,
                      color: AppColors.bronze,
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Text(
                        pendingImageName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption,
                      ),
                    ),
                    IconButton(
                      onPressed: onClearImage,
                      icon: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  onPressed: enabled ? onAttach : null,
                  icon: isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                    onSubmitted: (_) {
                      if (enabled) onSend();
                    },
                    decoration: InputDecoration(
                      hintText: context.tr(RemainingL10n.askGemAi2),
                      hintStyle: AppTypography.body.copyWith(
                        color: AppColors.textSecondary(context),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.field(context),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s16,
                        vertical: AppSpacing.s12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.r20),
                        borderSide: BorderSide(
                          color: AppColors.border(context),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.r20),
                        borderSide: BorderSide(
                          color: AppColors.border(context),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.r20),
                        borderSide: const BorderSide(
                          color: AppColors.bronze,
                          width: 1.5,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.r20),
                        borderSide: BorderSide(
                          color: AppColors.border(
                            context,
                          ).withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                FilledButton(
                  onPressed: enabled ? onSend : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.charcoal,
                    foregroundColor: AppColors.warmWhite,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(AppSpacing.s16),
                  ),
                  child: const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
