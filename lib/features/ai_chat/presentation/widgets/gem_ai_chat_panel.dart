import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../application/ai_chat_providers.dart';
import '../../domain/models/ai_chat_language.dart';
import '../../domain/models/ai_chat_message.dart';
import '../../domain/models/ai_chat_reply.dart';
import 'ai_chat_product_list_section.dart';

/// Gem AI advisor panel: floating luxe card with conversation, history,
/// reply-language menu, photo attach and suggested prompts.
class GemAiChatPanel extends ConsumerStatefulWidget {
  const GemAiChatPanel({
    super.key,
    required this.onClose,
    this.alignRight = true,
  });

  final VoidCallback onClose;

  /// Anchors the card to the side the Gem AI orb is docked on.
  final bool alignRight;

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
        duration: const Duration(milliseconds: 420),
        curve: LuxeMotion.settle,
      );
    });
  }

  Future<void> _send([String? preset]) async {
    final text = preset ?? _composer.text;
    if (preset == null) _composer.clear();
    AppHaptics.light();
    await ref.read(aiChatPanelProvider.notifier).sendMessage(text);
    _scrollToEnd();
  }

  void _closeLanguageMenu() {
    if (!_languageMenuOpen) return;
    setState(() => _languageMenuOpen = false);
  }

  void _selectLanguage(AiChatLanguage language) {
    AppHaptics.selection();
    ref.read(aiChatPanelProvider.notifier).setLanguage(language);
    _closeLanguageMenu();
  }

  @override
  Widget build(BuildContext context) {
    final panel = ref.watch(aiChatPanelProvider);
    final ui = ref.watch(aiChatUiProvider);
    ref.listen(aiChatPanelProvider.select((s) => s.messages.length), (_, _) {
      _scrollToEnd();
    });
    ref.listen(aiChatPanelProvider.select((s) => s.errorMessage), (_, next) {
      if (next != null) AppHaptics.error();
    });

    final p = LuxePalette.of(context);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final panelWidth = size.width < 480 ? size.width - 20.0 : 420.0;
    final bottomGap = (keyboard > 0 ? keyboard : padding.bottom) + 10.0;
    final panelHeight = (size.height - bottomGap - padding.top - 16).clamp(
      260.0,
      size.height * 0.86,
    );

    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: widget.alignRight
            ? Alignment.bottomRight
            : Alignment.bottomLeft,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(8, 8, 8, bottomGap),
          child: Container(
            width: panelWidth,
            height: panelHeight,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: p.hairline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: p.isDark ? 0.5 : 0.18),
                  blurRadius: 48,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Column(
                  children: [
                    _Header(
                      language: panel.language,
                      languageMenuOpen: _languageMenuOpen,
                      showingHistory: ui.showHistory,
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
                        AppHaptics.medium();
                        ref.read(aiChatPanelProvider.notifier).startNewChat();
                      },
                      onToggleLanguageMenu: () {
                        AppHaptics.selection();
                        setState(() => _languageMenuOpen = !_languageMenuOpen);
                      },
                    ),
                    AnimatedSize(
                      duration: LuxeMotion.medium,
                      curve: LuxeMotion.settle,
                      child: panel.errorMessage == null
                          ? const SizedBox(width: double.infinity)
                          : _ErrorBanner(
                              message: panel.errorMessage!,
                              onDismiss: () => ref
                                  .read(aiChatPanelProvider.notifier)
                                  .clearError(),
                            ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: LuxeMotion.medium,
                        switchInCurve: LuxeMotion.settle,
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.03),
                              end: Offset.zero,
                            ).animate(a),
                            child: child,
                          ),
                        ),
                        child: ui.showHistory
                            ? _HistoryView(
                                key: const ValueKey('history'),
                                sessions: panel.sessions,
                                loading: panel.isLoadingHistory,
                                onBack: () => ref
                                    .read(aiChatUiProvider.notifier)
                                    .hideHistory(),
                                onOpen: (id) async {
                                  AppHaptics.selection();
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
                                key: const ValueKey('messages'),
                                scrollController: _scroll,
                                messages: panel.messages,
                                isSending: panel.isSending,
                                isLoadingSession: panel.isLoadingSession,
                                onClosePanel: widget.onClose,
                                onPrompt: _send,
                              ),
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
                    top: 70,
                    right: 12,
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
    required this.showingHistory,
    required this.onToggleLanguageMenu,
  });

  final VoidCallback onClose;
  final VoidCallback onHistory;
  final VoidCallback onNewChat;
  final AiChatLanguage language;
  final bool languageMenuOpen;
  final bool showingHistory;
  final VoidCallback onToggleLanguageMenu;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LuxeStage.obsidian,
              border: Border.all(color: LuxeStage.gold.withValues(alpha: 0.5)),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: LuxeStage.gold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr(RemainingL10n.gemAi),
                  maxLines: 1,
                  style: LuxeType.display(23, p.ink),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.positive,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        context.tr(ExperienceL10n.aiAdvisor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuxeType.label(p.inkMuted, size: 11.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _LanguagePill(
            language: language,
            isOpen: languageMenuOpen,
            onPressed: onToggleLanguageMenu,
          ),
          const SizedBox(width: 5),
          LuxeIconButton(
            icon: Icons.history_rounded,
            tooltip: context.tr(ExperienceL10n.aiHistory),
            active: showingHistory,
            size: 36,
            onPressed: onHistory,
          ),
          const SizedBox(width: 5),
          LuxeIconButton(
            icon: Icons.edit_square,
            tooltip: context.tr(ExperienceL10n.aiNewChat),
            size: 36,
            onPressed: onNewChat,
          ),
          const SizedBox(width: 5),
          LuxeIconButton(
            icon: Icons.close_rounded,
            tooltip: context.tr(ExperienceL10n.aiClose),
            size: 36,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({
    required this.language,
    required this.isOpen,
    required this.onPressed,
  });

  final AiChatLanguage language;
  final bool isOpen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Tooltip(
      message: context.tr(ExperienceL10n.aiLanguage),
      child: Material(
        color: isOpen ? p.ink : p.surfaceRaised,
        shape: StadiumBorder(side: BorderSide(color: p.hairline)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 5, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  language.apiValue.toUpperCase(),
                  style: LuxeType.label(
                    isOpen ? p.canvas : p.ink,
                    size: 11.5,
                  ).copyWith(letterSpacing: 1),
                ),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: LuxeMotion.fast,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: isOpen ? p.canvas : p.inkMuted,
                  ),
                ),
              ],
            ),
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
    final p = LuxePalette.of(context);
    return Container(
          width: 196,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.hairline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: p.isDark ? 0.45 : 0.14),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          padding: const EdgeInsets.all(5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
                child: Text(
                  context.tr(ExperienceL10n.aiLanguage).toUpperCase(),
                  style: LuxeType.eyebrow(p.inkFaint).copyWith(fontSize: 9.5),
                ),
              ),
              for (final l in AiChatLanguage.values)
                Material(
                  color: l == language ? p.accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSelect(l),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.label,
                              style: LuxeType.label(p.ink, size: 14),
                            ),
                          ),
                          Text(
                            l.apiValue.toUpperCase(),
                            style: LuxeType.label(p.inkFaint, size: 11),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 18,
                            child: l == language
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: p.accent,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 160.ms)
        .scale(
          begin: const Offset(0.92, 0.92),
          alignment: Alignment.topRight,
          duration: 260.ms,
          curve: LuxeMotion.settle,
        );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
      decoration: BoxDecoration(
        color: p.caution.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.caution.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: p.caution, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: LuxeType.label(p.caution, size: 12.5)),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, size: 16, color: p.caution),
          ),
        ],
      ),
    );
  }
}

class _MessagesView extends StatelessWidget {
  const _MessagesView({
    super.key,
    required this.scrollController,
    required this.messages,
    required this.isSending,
    required this.isLoadingSession,
    required this.onClosePanel,
    required this.onPrompt,
  });

  final ScrollController scrollController;
  final List<AiChatMessage> messages;
  final bool isSending;
  final bool isLoadingSession;
  final VoidCallback onClosePanel;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    if (isLoadingSession) return const _ConversationSkeleton();
    if (messages.isEmpty && !isSending) {
      return _EmptyState(onPrompt: onPrompt);
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
      itemCount: messages.length + (isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= messages.length) return const _TypingBubble();
        Widget bubble = _MessageBubble(
          key: ValueKey(messages[index].id),
          message: messages[index],
          sourceQuery: _sourceQueryFor(messages, index),
          onClosePanel: onClosePanel,
        );
        // Only fresh messages animate in; history stays still.
        if (index >= messages.length - 2 &&
            !MediaQuery.disableAnimationsOf(context)) {
          bubble = bubble
              .animate(key: ValueKey('in-${messages[index].id}'))
              .fadeIn(duration: 320.ms)
              .moveY(
                begin: 12,
                end: 0,
                duration: 520.ms,
                curve: LuxeMotion.settle,
              );
        }
        return bubble;
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

/// Greeting with a turnable stone and tappable starter prompts.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPrompt});

  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final prompts = [
      (Icons.diamond_outlined, context.tr(ExperienceL10n.aiPrompt1)),
      (Icons.spa_outlined, context.tr(ExperienceL10n.aiPrompt2)),
      (Icons.science_outlined, context.tr(ExperienceL10n.aiPrompt3)),
      (Icons.card_giftcard_outlined, context.tr(ExperienceL10n.aiPrompt4)),
    ];
    final still = MediaQuery.disableAnimationsOf(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              context.tr(ExperienceL10n.aiGreeting),
              textAlign: TextAlign.center,
              style: LuxeType.display(28, p.ink),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              context.tr(RemainingL10n.askForDiamondsMeleeGemstonesJewelleryOr),
              textAlign: TextAlign.center,
              style: LuxeType.body(p.inkMuted, size: 13),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr(ExperienceL10n.aiTryAsking).toUpperCase(),
            style: LuxeType.eyebrow(p.accent).copyWith(fontSize: 10),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < prompts.length; i++)
            _reveal(
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _PromptTile(
                  icon: prompts[i].$1,
                  text: prompts[i].$2,
                  onTap: () => onPrompt(prompts[i].$2),
                ),
              ),
              index: i,
              still: still,
            ),
        ],
      ),
    );
  }
}

Widget _reveal(Widget child, {required int index, required bool still}) {
  if (still) return child;
  final delay = (120 + 70 * index).ms;
  return child
      .animate()
      .fadeIn(delay: delay, duration: 360.ms)
      .moveX(
        begin: 14,
        end: 0,
        delay: delay,
        duration: 520.ms,
        curve: LuxeMotion.settle,
      );
}

class _PromptTile extends StatelessWidget {
  const _PromptTile({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Material(
      color: p.surfaceRaised.withValues(alpha: p.isDark ? 1 : 0.6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: p.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text, style: LuxeType.label(p.ink, size: 13.5)),
              ),
              Icon(Icons.north_east_rounded, size: 16, color: p.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationSkeleton extends StatelessWidget {
  const _ConversationSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget line(double w, {bool right = false}) => Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: LuxeSkeleton(width: w, height: 44, radius: 18),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          line(180, right: true),
          line(260),
          line(220),
          line(140, right: true),
          line(240),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) _dot(p.accent, i, still),
            const SizedBox(width: 6),
            Text(
              context.tr(RemainingL10n.gemAiIsSearching),
              style: LuxeType.label(p.inkMuted, size: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _dot(Color color, int index, bool still) {
  final dot = Container(
    width: 6,
    height: 6,
    margin: const EdgeInsets.only(right: 4),
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
  if (still) return dot;
  return dot
      .animate(onPlay: (c) => c.repeat())
      .moveY(
        begin: 0,
        end: -4,
        delay: (index * 140).ms,
        duration: 300.ms,
        curve: Curves.easeOut,
      )
      .then()
      .moveY(begin: 0, end: 4, duration: 300.ms)
      .then(delay: 280.ms);
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.sourceQuery,
    required this.onClosePanel,
  });

  final AiChatMessage message;
  final String sourceQuery;
  final VoidCallback onClosePanel;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final isUser = message.role == AiChatRole.user;
    final products = message.products.isNotEmpty
        ? message.products
        : message.productGroups.expand((g) => g.products).toList();
    const r = Radius.circular(20);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                    ? MediaQuery.sizeOf(context).width * 0.72
                    : double.infinity,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: isUser ? p.ink : p.surfaceRaised,
                  borderRadius: BorderRadius.only(
                    topLeft: r,
                    topRight: r,
                    bottomLeft: isUser ? r : const Radius.circular(6),
                    bottomRight: isUser ? const Radius.circular(6) : r,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.imageUrls.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: message.imageUrls.first,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              const LuxeSkeleton(height: 130, radius: 14),
                          errorWidget: (_, _, _) => SizedBox(
                            height: 72,
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: p.inkFaint,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    SelectableText(
                      message.content,
                      style: LuxeType.body(isUser ? p.canvas : p.ink, size: 14),
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
    super.key,
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
    final p = LuxePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 6),
          child: Row(
            children: [
              LuxeIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: context.tr(RemainingL10n.backToChat),
                size: 36,
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(RemainingL10n.chatHistory),
                      style: LuxeType.display(22, p.ink),
                    ),
                    Text(
                      loading
                          ? context.tr(RemainingL10n.loadingSessions)
                          : sessions.isEmpty
                          ? context.tr(RemainingL10n.noConversations)
                          : context.tr(RemainingL10n.conversationsCount, {
                              'count': sessions.length,
                            }),
                      style: LuxeType.label(p.inkMuted, size: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 14),
                  children: [
                    for (var i = 0; i < 4; i++)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: LuxeSkeleton(height: 86, radius: 18),
                      ),
                  ],
                )
              : sessions.isEmpty
              ? LuxeStateView(
                  icon: Icons.forum_outlined,
                  title: context.tr(RemainingL10n.noSavedChats),
                  message: context.tr(RemainingL10n.savedChatsEmptyBody),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 14),
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _HistorySessionCard(
                    session: sessions[index],
                    onOpen: onOpen,
                  ),
                ),
        ),
      ],
    );
  }
}

class _HistorySessionCard extends StatelessWidget {
  const _HistorySessionCard({required this.session, required this.onOpen});

  final AiChatSessionSummary session;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
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
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onOpen(session.sessionId),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.accentSoft,
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 17,
                  color: p.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuxeType.label(p.ink, size: 14),
                          ),
                        ),
                        if (session.messageCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: ShapeDecoration(
                              color: p.surfaceRaised,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              '${session.messageCount}',
                              style: LuxeType.figure(p.inkMuted, size: 11),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.body(p.inkMuted, size: 12.5),
                    ),
                    if (when != null) ...[
                      const SizedBox(height: 5),
                      Text(when, style: LuxeType.label(p.inkFaint, size: 11)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: p.inkFaint),
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
    final p = LuxePalette.of(context);
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: c),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.hairline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendingImageName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child:
                  Container(
                        padding: const EdgeInsets.fromLTRB(8, 4, 2, 4),
                        decoration: ShapeDecoration(
                          color: p.accentSoft,
                          shape: const StadiumBorder(),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 15,
                              color: p.accent,
                            ),
                            const SizedBox(width: 5),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                pendingImageName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: LuxeType.label(p.ink, size: 12),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).deleteButtonTooltip,
                              onPressed: onClearImage,
                              icon: Icon(
                                Icons.close_rounded,
                                size: 15,
                                color: p.ink,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        alignment: Alignment.centerLeft,
                      ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              LuxeIconButton(
                icon: Icons.add_photo_alternate_outlined,
                tooltip: context.tr(ExperienceL10n.aiAttach),
                loading: isUploading,
                size: 46,
                onPressed: enabled ? onAttach : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  scrollPadding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                  cursorColor: p.accent,
                  style: LuxeType.body(p.ink, size: 14.5),
                  onSubmitted: (_) {
                    if (enabled) onSend();
                  },
                  decoration: InputDecoration(
                    hintText: context.tr(RemainingL10n.askGemAi2),
                    hintStyle: LuxeType.body(p.inkFaint, size: 14.5),
                    filled: true,
                    fillColor: p.surfaceRaised,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: border(Colors.transparent),
                    enabledBorder: border(Colors.transparent),
                    disabledBorder: border(Colors.transparent),
                    focusedBorder: border(p.accent.withValues(alpha: 0.6)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Semantics(
                button: true,
                label: context.tr(ExperienceL10n.aiSend),
                excludeSemantics: true,
                child: Material(
                  color: enabled ? p.ink : p.surfaceRaised,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: enabled ? onSend : null,
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 20,
                        color: enabled ? p.canvas : p.inkFaint,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
