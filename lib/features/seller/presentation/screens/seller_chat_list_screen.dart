import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/account_nav.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../../buyer/presentation/widgets/buyer_layout.dart';
import '../../../chat/application/chat_providers.dart';
import '../../../chat/domain/models/chat_thread.dart';
import '../widgets/seller_layout.dart';

class SellerChatListScreen extends ConsumerStatefulWidget {
  const SellerChatListScreen({super.key});

  @override
  ConsumerState<SellerChatListScreen> createState() =>
      _SellerChatListScreenState();
}

class _SellerChatListScreenState extends ConsumerState<SellerChatListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatInboxProvider);
    final threads = state.threads.where((t) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return t.peerName.toLowerCase().contains(q) ||
          t.lastMessage.toLowerCase().contains(q) ||
          t.productId.toLowerCase().contains(q) ||
          t.productType.label.toLowerCase().contains(q);
    }).toList();

    return ColoredBox(
      color: AppColors.bg(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s8,
              AppSpacing.s12,
              AppSpacing.s16,
              AppSpacing.s8,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    final path = GoRouterState.of(context).uri.path;
                    if (isBuyerPath(path)) {
                      openBuyerDrawer(context);
                    } else {
                      openSellerDrawer(context);
                    }
                  },
                  icon: const Icon(Icons.menu_rounded),
                  tooltip: 'Menu',
                ),
                Expanded(
                  child: Text(
                    'Messages',
                    style: AppTypography.headline.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (state.threads.isNotEmpty)
                  Text(
                    '${state.threads.length}',
                  style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: 'Search conversations',
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.textMuted(context),
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: AppColors.field(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r12),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r12),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r12),
                  borderSide: const BorderSide(color: AppColors.bronze),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
            const SizedBox(height: AppSpacing.s12),
            Expanded(child: _body(state, threads)),
        ],
      ),
    );
  }

  Widget _body(ChatInboxState state, List<ChatThread> threads) {
    if (state.isLoading && state.threads.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (state.errorMessage != null && state.threads.isEmpty) {
      return CatalogErrorState(
        message: state.errorMessage!,
        onRetry: () => ref.read(chatInboxProvider.notifier).refresh(),
      );
    }
    if (threads.isEmpty) {
      return CatalogEmptyState(
        icon: Icons.forum_outlined,
        title: _query.isEmpty ? 'No messages yet' : 'No matches',
        message: _query.isEmpty
            ? 'Conversations about products will appear here.'
            : 'Try a different name or product.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(chatInboxProvider.notifier).refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s4,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        itemCount: threads.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (context, index) {
          final thread = threads[index];
          return _ThreadTile(
            thread: thread,
            onTap: () => context.openRoute(
              chatDetailPathFor(
                GoRouterState.of(context).uri.path,
                thread.id,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.onTap});

  final ChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = thread.peerName.trim().isEmpty
        ? '?'
        : thread.peerName.trim().characters.first.toUpperCase();
    final unread = thread.unreadCount > 0;
    final borderColor = unread
        ? AppColors.bronze.withValues(alpha: AppColors.isDark(context) ? 0.7 : 0.45)
        : AppColors.border(context);

    return Material(
      color: AppColors.card(context),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        side: BorderSide(color: borderColor, width: unread ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surface(context),
                child: Text(
                  initial,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.peerName,
                            style: AppTypography.label.copyWith(
                              color: AppColors.textPrimary(context),
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          _relativeTime(thread.lastMessageAt),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      thread.listingLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.bronze,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.lastMessage.isEmpty ? '—' : thread.lastMessage,
                            style: AppTypography.body.copyWith(
                              color: unread
                                  ? AppColors.textPrimary(context)
                                  : AppColors.textSecondary(context),
                              fontWeight:
                                  unread ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: AppSpacing.s8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bronze,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.r16),
                            ),
                            child: Text(
                              thread.unreadCount > 99
                                  ? '99+'
                                  : '${thread.unreadCount}',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.warmWhite,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
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

String _relativeTime(DateTime date) {
  final local = date.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) return 'Now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}';
}
