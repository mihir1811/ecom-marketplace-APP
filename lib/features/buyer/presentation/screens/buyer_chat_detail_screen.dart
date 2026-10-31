import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../chat/application/chat_providers.dart';
import '../../../chat/domain/models/chat_message.dart';
import '../../../chat/domain/models/chat_thread.dart';
import '../../../chat/domain/models/product_chat_context.dart';
import '../../../chat/presentation/open_chat_product_detail.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';

/// One conversation with a seller: who it is with, the piece it is about, the
/// thread itself (newest at the bottom, grouped by sender and day) and a
/// floating composer with photo attach and suggested replies.
class BuyerChatDetailScreen extends ConsumerStatefulWidget {
  const BuyerChatDetailScreen({required this.chatId, super.key});

  final String chatId;

  @override
  ConsumerState<BuyerChatDetailScreen> createState() =>
      _BuyerChatDetailScreenState();
}

class _BuyerChatDetailScreenState extends ConsumerState<BuyerChatDetailScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focus = FocusNode();
  late final ChatThreadArgs? _args;

  /// Scrolled up, away from the newest message.
  bool _away = false;

  /// Messages that arrived while [_away].
  int _missed = 0;

  /// Ids present when the thread first loaded; later ones animate in once.
  Set<String>? _initialIds;
  final Set<String> _animated = {};

  static const _awayThreshold = 240.0;

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
    _scrollCtrl.addListener(_onScroll);
    _messageCtrl.addListener(_onText);
  }

  @override
  void dispose() {
    _messageCtrl
      ..removeListener(_onText)
      ..dispose();
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final away = _scrollCtrl.offset > _awayThreshold;
    if (away == _away) return;
    setState(() {
      _away = away;
      if (!away) _missed = 0;
    });
  }

  Future<void> _send() async {
    final args = _args;
    if (args == null) return;
    final text = _messageCtrl.text;
    if (text.trim().isEmpty) return;
    AppHaptics.light();
    _messageCtrl.clear();
    _scrollToEnd();
    await ref.read(chatThreadProvider(args).notifier).sendText(text);
    _scrollToEnd();
  }

  Future<void> _pickImage() async {
    final args = _args;
    if (args == null) return;
    if (ref.read(chatThreadProvider(args)).isSending) return;
    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
      );
    } catch (_) {
      if (!mounted) return;
      showAtelierToast(
        context,
        context.tr(RemainingL10n.couldNotOpenPhotos),
        tone: AtelierTone.ruby,
      );
      return;
    }
    if (file == null || !mounted) return;
    final send = ref.read(chatThreadProvider(args).notifier).sendImage(file);
    _scrollToEnd();
    await send;
    _scrollToEnd();
  }

  void _useSuggestion(String text) {
    _messageCtrl
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    _focus.requestFocus();
  }

  /// The list is reversed, so "latest" is offset 0.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        0,
        duration: AtelierMotion.slow,
        curve: AtelierMotion.emphasized,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final args = _args;
    if (args == null) {
      return ColoredBox(
        color: p.canvas,
        child: Center(
          child: AtelierEmptyState(
            icon: Icons.link_off_rounded,
            title: context.tr(RemainingL10n.conversationNotFound),
            message: context.tr(RemainingL10n.threadInvalid),
            actionLabel: context.tr(RemainingL10n.backToMessages),
            onAction: () => context.goBack(),
          ),
        ),
      );
    }

    ref.listen(chatThreadProvider(args), (prev, next) {
      final before = prev?.messages.length ?? 0;
      final grew = next.messages.length - before;
      if (grew > 0 && before > 0 && _away) setState(() => _missed += grew);
    });

    final state = ref.watch(chatThreadProvider(args));
    if (_initialIds == null && !(state.isLoading && state.messages.isEmpty)) {
      _initialIds = {for (final m in state.messages) m.id};
    }
    final peer = _peer(state.messages, args.peerUserId);
    final peerName =
        state.context?.sellerName.isNotEmpty == true && state.messages.isEmpty
        ? state.context!.sellerName
        : (peer?.name.isNotEmpty == true
              ? peer!.name
              : context.tr(RemainingL10n.conversation));
    final lastFromPeer = state.messages.isEmpty || !state.messages.last.isMine;
    final showSuggestions =
        _messageCtrl.text.isEmpty &&
        !state.isSending &&
        !state.isLoading &&
        state.errorMessage == null &&
        lastFromPeer;

    return ColoredBox(
      color: p.canvas,
      child: Column(
        children: [
          _ThreadHeader(
            peerName: peerName,
            peerAvatar: peer?.displayAvatar ?? '',
            productLabel:
                state.context?.productName ??
                '${args.productTypeApi} · ${args.productId}',
            contextData: state.context,
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _messagesBody(state, args)),
                Positioned(
                  right: 16,
                  bottom: 12,
                  child: _JumpToLatest(
                    visible: _away,
                    missed: _missed,
                    onTap: _scrollToEnd,
                  ),
                ),
              ],
            ),
          ),
          _Composer(
            controller: _messageCtrl,
            focusNode: _focus,
            isSending: state.isSending,
            sendError: state.sendError,
            showSuggestions: showSuggestions,
            onSuggestion: _useSuggestion,
            onSend: _send,
            onPickImage: _pickImage,
          ),
        ],
      ),
    );
  }

  Widget _messagesBody(ChatThreadState state, ChatThreadArgs args) {
    if (state.isLoading && state.messages.isEmpty) {
      return const _ThreadSkeleton();
    }
    if (state.errorMessage != null && state.messages.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: AtelierErrorState(
            title: 'Conversation unavailable',
            message: state.errorMessage!,
            onRetry: () =>
                ref.read(chatThreadProvider(args).notifier).refresh(),
          ),
        ),
      );
    }
    if (state.messages.isEmpty && state.pendingImage == null) {
      return Center(
        child: SingleChildScrollView(
          child: AtelierEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: context.tr(RemainingL10n.startConversation),
            message: context.tr(
              RemainingL10n.keepItShortAskAboutAvailabilitySpecs,
            ),
          ),
        ),
      );
    }

    final entries = _buildEntries(state).reversed.toList();
    final width = MediaQuery.sizeOf(context).width;
    final gutter = width >= 720 ? 28.0 : 14.0;

    return ListView.builder(
      controller: _scrollCtrl,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return switch (entry) {
          _DayEntry(:final day) => _DayDivider(date: day),
          _PendingEntry(:final bytes, :final progress) => _arrive(
            'pending',
            _PendingImageBubble(bytes: bytes, progress: progress),
            mine: true,
            always: true,
          ),
          _MessageEntry(:final message, :final start, :final end) => _arrive(
            message.id,
            _MessageBubble(message: message, groupStart: start, groupEnd: end),
            mine: message.isMine,
          ),
        };
      },
    );
  }

  /// Plays a soft "arrival" once for messages that weren't there on load.
  Widget _arrive(
    String id,
    Widget child, {
    required bool mine,
    bool always = false,
  }) {
    final initial = _initialIds;
    final fresh =
        always ||
        (initial != null && !initial.contains(id) && !_animated.contains(id));
    if (!fresh || context.reduceMotion) return child;
    if (!always) _animated.add(id);
    return child
        .animate()
        .fadeIn(duration: 260.ms, curve: AtelierMotion.emphasized)
        .scaleXY(
          begin: 0.94,
          end: 1,
          alignment: mine ? Alignment.bottomRight : Alignment.bottomLeft,
          duration: 420.ms,
          curve: AtelierMotion.settle,
        )
        .moveY(
          begin: 8,
          end: 0,
          duration: 360.ms,
          curve: AtelierMotion.emphasized,
        );
  }

  List<_Entry> _buildEntries(ChatThreadState state) {
    final out = <_Entry>[];
    final msgs = state.messages;
    for (var i = 0; i < msgs.length; i++) {
      final m = msgs[i];
      final prev = i > 0 ? msgs[i - 1] : null;
      final next = i + 1 < msgs.length ? msgs[i + 1] : null;
      final local = m.createdAt.toLocal();
      final newDay = prev == null || !_sameDay(prev.createdAt.toLocal(), local);
      if (newDay) out.add(_DayEntry(local));
      out.add(
        _MessageEntry(
          message: m,
          start: newDay || !_sameRun(prev, m),
          end:
              next == null ||
              !_sameDay(next.createdAt.toLocal(), local) ||
              !_sameRun(m, next),
        ),
      );
    }
    final pending = state.pendingImage;
    if (pending != null) {
      out.add(_PendingEntry(pending, state.uploadProgress));
    }
    return out;
  }

  /// Same sender, within five minutes: drawn as one cluster.
  static bool _sameRun(ChatMessage? a, ChatMessage b) =>
      a != null &&
      a.isMine == b.isMine &&
      b.createdAt.difference(a.createdAt).inMinutes.abs() < 5;

  ChatParticipant? _peer(List<ChatMessage> messages, String peerId) {
    for (final m in messages.reversed) {
      if (m.from?.id == peerId && (m.from?.name.isNotEmpty ?? false)) {
        return m.from;
      }
      if (m.to?.id == peerId && (m.to?.name.isNotEmpty ?? false)) {
        return m.to;
      }
    }
    return null;
  }
}

sealed class _Entry {
  const _Entry();
}

class _DayEntry extends _Entry {
  const _DayEntry(this.day);

  final DateTime day;
}

class _MessageEntry extends _Entry {
  const _MessageEntry({
    required this.message,
    required this.start,
    required this.end,
  });

  final ChatMessage message;
  final bool start;
  final bool end;
}

class _PendingEntry extends _Entry {
  const _PendingEntry(this.bytes, this.progress);

  final Uint8List bytes;
  final double? progress;
}

/// Who the thread is with, and the piece it concerns.
class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({
    required this.peerName,
    required this.peerAvatar,
    required this.productLabel,
    required this.contextData,
  });

  final String peerName;
  final String peerAvatar;
  final String productLabel;
  final ProductChatContext? contextData;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final ctx = contextData;
    final width = MediaQuery.sizeOf(context).width;
    final gutter = width >= 720 ? 28.0 : 16.0;
    final link = peerAvatar.trim();
    final monogram = AtelierMonogram(name: peerName, size: 42);

    return Container(
      decoration: BoxDecoration(
        color: p.canvas,
        border: Border(bottom: BorderSide(color: p.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              link.isEmpty
                  ? monogram
                  : ClipOval(
                      child: AppNetworkImage(
                        url: link,
                        width: 42,
                        height: 42,
                        memCacheWidth: 126,
                        error: monogram,
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: AtelierMotion.base,
                      child: Text(
                        peerName,
                        key: ValueKey(peerName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.display(p.ink, size: 22),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      productLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.caption(p.muted, size: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: AtelierMotion.slow,
            curve: AtelierMotion.emphasized,
            alignment: Alignment.topCenter,
            child: ctx == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Reveal(child: _PieceStrip(contextData: ctx)),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The listing under discussion; opens its product detail page.
class _PieceStrip extends ConsumerWidget {
  const _PieceStrip({required this.contextData});

  final ProductChatContext contextData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final price = contextData.productPrice;
    final stock = contextData.stockNumber;
    return Pressable(
      onTap: () => openChatProductDetail(context, ref, contextData),
      semanticLabel: 'Piece details, ${contextData.productName}',
      borderRadius: BorderRadius.circular(AtelierRadius.md),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.md),
          border: Border.all(color: p.hairline),
          boxShadow: p.softShadow,
        ),
        child: Row(
          children: [
            AtelierThumb(url: contextData.primaryImage, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contextData.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.label(p.ink, size: 13.5),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (stock != null && stock.isNotEmpty) ...[
                        Flexible(
                          child: Text(
                            stock,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.caption(p.muted, size: 11.5),
                          ),
                        ),
                        if (price != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '·',
                              style: AtelierType.caption(p.muted),
                            ),
                          ),
                      ],
                      if (price != null)
                        Text(
                          AppCurrency.format(price),
                          style: AtelierType.figure(p.gold, size: 12.5),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 20, color: p.muted),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.groupStart,
    required this.groupEnd,
  });

  final ChatMessage message;
  final bool groupStart;
  final bool groupEnd;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final mine = message.isMine;
    final time = message.createdAt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final fileUrl = message.fileUrl?.trim();
    final imageUrl =
        message.messageType == ChatMessageType.image &&
            fileUrl != null &&
            fileUrl.isNotEmpty
        ? fileUrl
        : null;
    final hasText = message.body.trim().isNotEmpty;

    final bg = mine ? (p.isDark ? p.lifted : p.onyx) : p.surface;
    final fg = mine ? (p.isDark ? p.ink : p.onOnyx) : p.ink;
    final meta = mine ? fg.withValues(alpha: 0.55) : p.muted;
    const big = Radius.circular(20);
    const small = Radius.circular(6);
    final radius = BorderRadius.only(
      topLeft: !mine && !groupStart ? small : big,
      bottomLeft: !mine && !groupEnd ? small : (mine ? big : small),
      topRight: mine && !groupStart ? small : big,
      bottomRight: mine && !groupEnd ? small : (mine ? small : big),
    );
    final maxWidth = (MediaQuery.sizeOf(context).width * 0.78).clamp(
      200.0,
      520.0,
    );

    final stamp = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${two(time.hour)}:${two(time.minute)}',
          style: AtelierType.figure(meta, size: 10, weight: FontWeight.w500),
        ),
        if (mine) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: message.isRead ? 'Read' : 'Delivered',
            child: Icon(
              message.isRead ? Icons.done_all_rounded : Icons.check_rounded,
              size: 13,
              color: message.isRead ? p.gold : meta,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: EdgeInsets.only(top: groupStart ? 10 : 2),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: imageUrl == null
                ? const EdgeInsets.fromLTRB(14, 10, 12, 8)
                : const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              border: mine ? null : Border.all(color: p.hairline),
              boxShadow: mine || p.isDark ? null : p.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageUrl != null)
                  _ChatImage(
                    url: imageUrl,
                    radius: BorderRadius.circular(16),
                    stamp: hasText ? null : stamp,
                  ),
                if (imageUrl == null || hasText)
                  Padding(
                    padding: imageUrl == null
                        ? EdgeInsets.zero
                        : const EdgeInsets.fromLTRB(10, 8, 8, 4),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 10,
                      runSpacing: 2,
                      children: [
                        SelectableText(
                          message.body.isEmpty
                              ? (message.messageType == ChatMessageType.image
                                    ? context.tr(RemainingL10n.photo)
                                    : context.tr(RemainingL10n.attachment))
                              : message.body,
                          style: AtelierType.body(
                            fg,
                            size: 14.5,
                          ).copyWith(height: 1.4),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: stamp,
                        ),
                      ],
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

/// Photo inside a message bubble; tap to view it full screen.
class _ChatImage extends StatelessWidget {
  const _ChatImage({required this.url, required this.radius, this.stamp});

  final String url;
  final BorderRadius radius;

  /// Time / receipt overlaid on photo-only messages.
  final Widget? stamp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(RemainingL10n.photo),
      child: Pressable(
        onTap: () => showChatImageViewer(context, url),
        scale: 0.98,
        borderRadius: radius,
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(
                  url: url,
                  width: 240,
                  height: 240,
                  memCacheWidth: 720,
                ),
                if (stamp != null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(AtelierRadius.pill),
                      ),
                      child: DefaultTextStyle.merge(
                        style: const TextStyle(color: Colors.white),
                        child: IconTheme.merge(
                          data: const IconThemeData(color: Colors.white),
                          child: stamp!,
                        ),
                      ),
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

/// Full-screen, zoomable view of a chat photo.
Future<void> showChatImageViewer(BuildContext context, String url) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).closeButtonTooltip,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: AtelierMotion.base,
      reverseTransitionDuration: AtelierMotion.quick,
      pageBuilder: (context, _, _) => _ImageViewer(url: url),
      transitionsBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AtelierMotion.emphasized,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({required this.url});

  final String url;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _zoom = AnimationController(
    vsync: this,
    duration: AtelierMotion.base,
  );
  Animation<Matrix4>? _zoomAnim;
  TapDownDetails? _doubleTap;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(() {
      final a = _zoomAnim;
      if (a != null) _transform.value = a.value;
    });
  }

  @override
  void dispose() {
    _zoom.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    final pos = _doubleTap?.localPosition ?? Offset.zero;
    final target = zoomed
        ? Matrix4.identity()
        : (Matrix4.identity()
            ..translateByDouble(-pos.dx * 1.5, -pos.dy * 1.5, 0, 1)
            ..scaleByDouble(2.5, 2.5, 1, 1));
    _zoomAnim = Matrix4Tween(
      begin: _transform.value,
      end: target,
    ).animate(CurvedAnimation(parent: _zoom, curve: AtelierMotion.emphasized));
    _zoom.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final close = MaterialLocalizations.of(context).closeButtonTooltip;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onDoubleTapDown: (d) => _doubleTap = d,
                onDoubleTap: _toggleZoom,
                child: InteractiveViewer(
                  transformationController: _transform,
                  maxScale: 5,
                  child: Center(
                    child: AppNetworkImage(
                      url: widget.url,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Tooltip(
                message: close,
                child: Pressable(
                  onTap: () => Navigator.of(context).pop(),
                  semanticLabel: close,
                  scale: 0.9,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: IgnorePointer(
                child: Text(
                  'Double-tap or pinch to zoom',
                  textAlign: TextAlign.center,
                  style: AtelierType.caption(
                    Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Local preview of a photo that is still uploading.
class _PendingImageBubble extends StatelessWidget {
  const _PendingImageBubble({required this.bytes, this.progress});

  final Uint8List bytes;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final value = progress;
    final determinate = value != null && value > 0 && value < 1;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: Semantics(
          label: context.tr(RemainingL10n.uploadingPhoto),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: p.isDark ? p.lifted : p.onyx,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(bytes, fit: BoxFit.cover, cacheWidth: 720),
                    const ColoredBox(color: Color(0x73000000)),
                    Center(
                      child: determinate
                          ? AtelierRing(
                              value: value,
                              size: 58,
                              stroke: 3,
                              color: p.gold,
                              child: Text(
                                '${(value * 100).round()}%',
                                style: AtelierType.figure(
                                  Colors.white,
                                  size: 12,
                                ),
                              ),
                            )
                          : SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: p.gold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: p.hairline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              _label(context, date).toUpperCase(),
              style: AtelierType.overline(p.muted),
            ),
          ),
          Expanded(child: Container(height: 1, color: p.hairline)),
        ],
      ),
    );
  }

  String _label(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return context.tr(RemainingL10n.today);
    if (day == today.subtract(const Duration(days: 1))) {
      return context.tr(RemainingL10n.yesterday);
    }
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

/// Bubble-shaped shimmer while the thread loads.
class _ThreadSkeleton extends StatelessWidget {
  const _ThreadSkeleton();

  @override
  Widget build(BuildContext context) {
    const rows = [
      (false, 210.0, 54.0),
      (false, 150.0, 40.0),
      (true, 230.0, 54.0),
      (false, 180.0, 40.0),
      (true, 120.0, 40.0),
      (true, 200.0, 70.0),
    ];
    return ListView(
      reverse: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        for (final (mine, w, h) in rows)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: SkeletonBox(width: w, height: h, radius: 18),
            ),
          ),
      ],
    );
  }
}

/// Floating "back to latest" control with a count of missed messages.
class _JumpToLatest extends StatelessWidget {
  const _JumpToLatest({
    required this.visible,
    required this.missed,
    required this.onTap,
  });

  final bool visible;
  final int missed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedScale(
        scale: visible ? 1 : 0.6,
        duration: AtelierMotion.base,
        curve: AtelierMotion.settle,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: AtelierMotion.quick,
          child: Tooltip(
            message: 'Jump to latest',
            child: Pressable(
              onTap: onTap,
              semanticLabel: missed > 0
                  ? 'Jump to latest, $missed new'
                  : 'Jump to latest',
              scale: 0.9,
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.raised,
                        border: Border.all(color: p.hairline),
                        boxShadow: p.floatShadow,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: p.ink,
                      ),
                    ),
                    if (missed > 0)
                      Positioned(
                        top: -4,
                        right: -2,
                        child: CountBubble(count: missed),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.showSuggestions,
    required this.onSuggestion,
    required this.onSend,
    required this.onPickImage,
    this.sendError,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool showSuggestions;
  final ValueChanged<String> onSuggestion;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final String? sendError;

  static const _suggestions = [
    'Is this piece still available?',
    'Could you share more photos?',
    'What’s your best price?',
    'Can we arrange a video viewing?',
    'Does it come with a certificate?',
  ];

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final focused = widget.focusNode.hasFocus;
    final hasText = widget.controller.text.trim().isNotEmpty;
    final canSend = hasText && !widget.isSending;
    final width = MediaQuery.sizeOf(context).width;
    final gutter = width >= 720 ? 28.0 : 12.0;

    return Container(
      decoration: BoxDecoration(
        color: p.canvas,
        border: Border(top: BorderSide(color: p.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSize(
                duration: AtelierMotion.base,
                curve: AtelierMotion.emphasized,
                alignment: Alignment.bottomCenter,
                child: widget.sendError == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AtelierNotice(
                          text: widget.sendError!,
                          tone: AtelierTone.ruby,
                          icon: Icons.error_outline_rounded,
                        ),
                      ),
              ),
              AnimatedSize(
                duration: AtelierMotion.base,
                curve: AtelierMotion.emphasized,
                alignment: Alignment.bottomCenter,
                child: !widget.showSuggestions
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SizedBox(
                          height: 34,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _Composer._suggestions.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final text = _Composer._suggestions[i];
                              return Reveal(
                                index: i,
                                horizontal: true,
                                offset: 12,
                                child: Pressable(
                                  onTap: () => widget.onSuggestion(text),
                                  semanticLabel: 'Suggested reply: $text',
                                  borderRadius: BorderRadius.circular(
                                    AtelierRadius.pill,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: p.surface,
                                      borderRadius: BorderRadius.circular(
                                        AtelierRadius.pill,
                                      ),
                                      border: Border.all(color: p.hairline),
                                    ),
                                    child: Text(
                                      text,
                                      style: AtelierType.label(
                                        p.inkSoft,
                                        size: 12.5,
                                        weight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AtelierIconButton(
                    icon: Icons.add_photo_alternate_outlined,
                    tooltip: context.tr(RemainingL10n.sendPhoto),
                    onPressed: widget.isSending ? null : widget.onPickImage,
                    filled: true,
                    size: 48,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedContainer(
                      duration: AtelierMotion.base,
                      curve: AtelierMotion.emphasized,
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: focused ? p.surface : p.sunken,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: focused
                              ? p.gold.withValues(alpha: 0.7)
                              : Colors.transparent,
                          width: 1.2,
                        ),
                        boxShadow: focused ? p.softShadow : null,
                      ),
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        scrollPadding: const EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          80,
                        ),
                        onSubmitted: (_) => widget.onSend(),
                        cursorColor: p.gold,
                        style: AtelierType.body(p.ink, size: 14.5),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          hintText: context.tr(RemainingL10n.writeMessage),
                          hintStyle: AtelierType.body(p.muted, size: 14.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SendButton(
                    enabled: canSend,
                    sending: widget.isSending,
                    onTap: widget.onSend,
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

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.sending,
    required this.onTap,
  });

  final bool enabled;
  final bool sending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Tooltip(
      message: 'Send',
      child: Pressable(
        onTap: sending ? null : onTap,
        semanticLabel: 'Send',
        scale: 0.88,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: enabled || sending ? p.goldGradient : null,
            color: enabled || sending ? null : p.sunken,
            boxShadow: enabled ? p.softShadow : null,
          ),
          child: AnimatedSwitcher(
            duration: AtelierMotion.quick,
            transitionBuilder: (c, a) => ScaleTransition(
              scale: CurvedAnimation(parent: a, curve: AtelierMotion.settle),
              child: c,
            ),
            child: sending
                ? SizedBox(
                    key: const ValueKey('sending'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: p.onGold,
                    ),
                  )
                : AnimatedRotation(
                    key: const ValueKey('idle'),
                    turns: enabled ? 0 : -0.125,
                    duration: AtelierMotion.slow,
                    curve: AtelierMotion.settle,
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 20,
                      color: enabled ? p.onGold : p.muted,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
