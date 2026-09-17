import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../help_center/application/help_center_provider.dart';
import '../../../help_center/domain/models/help_question.dart';
import '../widgets/seller_layout.dart';

class SellerHelpCenterScreen extends ConsumerStatefulWidget {
  const SellerHelpCenterScreen({super.key, this.showHeader = true});

  /// When false, the parent shell already provides the title/menu app bar.
  final bool showHeader;

  @override
  ConsumerState<SellerHelpCenterScreen> createState() =>
      _SellerHelpCenterScreenState();
}

class _SellerHelpCenterScreenState
    extends ConsumerState<SellerHelpCenterScreen> {
  HelpIssueType? _issueType;
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (_issueType == null || subject.isEmpty || message.isEmpty) {
      AppHaptics.warning();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(RemainingL10n.fillAllFields))),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ref
        .read(helpCenterMutationProvider.notifier)
        .create(issueType: _issueType!, subject: subject, body: message);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (result) {
      case Success():
        AppHaptics.success();
        setState(() {
          _issueType = null;
          _subjectCtrl.clear();
          _messageCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(RemainingL10n.questionSubmitted))),
        );
      case ResultFailure(failure: final failure):
        AppHaptics.error();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _closeQuestion(HelpQuestion question) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr(RemainingL10n.closeQuestion)),
        content: Text(context.tr(RemainingL10n.thisWillMarkTheTicketAsClosed)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr(RemainingL10n.cancel)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr(RemainingL10n.close)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(helpCenterMutationProvider.notifier)
        .close(id: question.id);
    if (!mounted) return;

    switch (result) {
      case Success():
        AppHaptics.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(RemainingL10n.questionClosed))),
        );
      case ResultFailure(failure: final failure):
        AppHaptics.error();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.r12),
      borderSide: BorderSide(color: AppColors.border(context)),
    );
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: AppColors.surface(context),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.bronze, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: maxLines > 1 ? AppSpacing.s16 : AppSpacing.s12,
      ),
    );
  }

  IconData _issueIcon(HelpIssueType type) {
    return switch (type) {
      HelpIssueType.accountIssues => Icons.manage_accounts_outlined,
      HelpIssueType.billingPayments => Icons.payments_outlined,
      HelpIssueType.technicalIssues => Icons.build_circle_outlined,
      HelpIssueType.featureRequests => Icons.lightbulb_outline,
      HelpIssueType.generalInquiry => Icons.help_outline,
      HelpIssueType.others => Icons.more_horiz,
    };
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(helpQuestionListProvider);
    final openCount = listState.items
        .where((q) => q.status == HelpQuestionStatus.open)
        .length;
    final answeredCount = listState.items
        .where((q) => q.status == HelpQuestionStatus.answered)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => openSellerDrawer(context),
                  icon: const Icon(Icons.menu),
                ),
                Text(
                  context.tr(RemainingL10n.helpCenter),
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(helpQuestionListProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s8,
                AppSpacing.s16,
                AppSpacing.s24,
              ),
              children: [
                _SupportHero(
                  title: context.tr(RemainingL10n.helpCenter),
                  subtitle: context.tr(
                    RemainingL10n.askOurSupportTeamAQuestion,
                  ),
                  openCount: openCount,
                  answeredCount: answeredCount,
                  totalCount: listState.items.length,
                ),
                const SizedBox(height: AppSpacing.s16),
                _SectionCard(
                  icon: Icons.edit_note_outlined,
                  title: context.tr(RemainingL10n.newQuestion),
                  subtitle: context.tr(
                    RemainingL10n.includeEnoughDetailSoWeCan,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<HelpIssueType>(
                        key: ValueKey(_issueType?.name),
                        initialValue: _issueType,
                        isExpanded: true,
                        hint: Text(context.tr(RemainingL10n.selectIssueType)),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: [
                          for (final type in HelpIssueType.values)
                            DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(
                                    _issueIcon(type),
                                    size: 18,
                                    color: AppColors.bronze,
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      type.label,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (value) {
                                if (value == null || value == _issueType) {
                                  return;
                                }
                                AppHaptics.selection();
                                setState(() => _issueType = value);
                              },
                        decoration: _fieldDecoration(
                          label: context.tr(RemainingL10n.issueType),
                          icon: Icons.category_outlined,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      TextField(
                        controller: _subjectCtrl,
                        enabled: !_isSubmitting,
                        decoration: _fieldDecoration(
                          label: context.tr(RemainingL10n.subject),
                          icon: Icons.subject_outlined,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      TextField(
                        controller: _messageCtrl,
                        enabled: !_isSubmitting,
                        maxLines: 5,
                        maxLength: 5000,
                        decoration: _fieldDecoration(
                          label: context.tr(RemainingL10n.message),
                          icon: Icons.chat_bubble_outline,
                          maxLines: 5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.warmWhite,
                                  ),
                                )
                              : const Icon(Icons.send_outlined, size: 18),
                          label: Text(
                            context.tr(RemainingL10n.submitQuestion),
                            style: AppTypography.label.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.warmWhite,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.charcoal,
                            foregroundColor: AppColors.warmWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.r12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.bronze.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.forum_outlined,
                        size: 18,
                        color: AppColors.bronze,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(
                        context.tr(RemainingL10n.yourQuestions),
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (listState.items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.border(context),
                          ),
                        ),
                        child: Text(
                          '${listState.items.length}',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                if (listState.isLoading && listState.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (listState.errorMessage != null &&
                    listState.items.isEmpty)
                  _ErrorCard(
                    message: listState.errorMessage!,
                    onRetry: () =>
                        ref.read(helpQuestionListProvider.notifier).refresh(),
                  )
                else if (listState.items.isEmpty)
                  _EmptyTicketsPanel(
                    message: context.tr(
                      RemainingL10n.noQuestionsYetSubmitOneAboveAnd,
                    ),
                  )
                else ...[
                  for (final ticket in listState.items) ...[
                    _TicketCard(
                      key: ValueKey(ticket.id),
                      ticket: ticket,
                      issueIcon: _issueIcon(ticket.issueType),
                      onClose: ticket.canClose
                          ? () => _closeQuestion(ticket)
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                  ],
                  if (listState.hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Center(
                        child: listState.isLoadingMore
                            ? const CircularProgressIndicator()
                            : OutlinedButton.icon(
                                onPressed: () => ref
                                    .read(helpQuestionListProvider.notifier)
                                    .loadMore(),
                                icon: const Icon(Icons.expand_more, size: 18),
                                label: Text(context.tr(RemainingL10n.loadMore)),
                              ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

}

class _SupportHero extends StatelessWidget {
  const _SupportHero({
    required this.title,
    required this.subtitle,
    required this.openCount,
    required this.answeredCount,
    required this.totalCount,
  });

  final String title;
  final String subtitle;
  final int openCount;
  final int answeredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: AppColors.isDark(context) ? [] : AppShadows.cardLight,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: const BoxDecoration(
                  color: AppColors.bronze,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.r16),
                    bottomLeft: Radius.circular(AppSpacing.r16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.bronze.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.support_agent_outlined,
                              color: AppColors.bronze,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: AppTypography.title.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary(context),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (totalCount > 0) ...[
                        const SizedBox(height: AppSpacing.s12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatChip(
                              icon: Icons.inbox_outlined,
                              label: '$totalCount',
                            ),
                            if (openCount > 0)
                              _StatChip(
                                icon: Icons.schedule,
                                label: '$openCount',
                                foreground: AppColors.warning,
                                background: AppColors.warning.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            if (answeredCount > 0)
                              _StatChip(
                                icon: Icons.check_circle_outline,
                                label: '$answeredCount',
                                foreground: AppColors.success,
                                background: AppColors.success.withValues(
                                  alpha: 0.12,
                                ),
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
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    this.foreground,
    this.background,
  });

  final IconData icon;
  final String label;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? AppColors.textSecondary(context);
    final bg = background ?? AppColors.surface(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: AppColors.isDark(context) ? [] : AppShadows.cardLight,
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bronze.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.bronze),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted(context),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          child,
        ],
      ),
    );
  }
}

class _EmptyTicketsPanel extends StatelessWidget {
  const _EmptyTicketsPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s24,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.bronze.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.bronze,
              size: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted(context),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.body.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(context.tr(RemainingL10n.retry)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    super.key,
    required this.ticket,
    required this.issueIcon,
    this.onClose,
  });

  final HelpQuestion ticket;
  final IconData issueIcon;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final status = ticket.status;
    final isOpen = status == HelpQuestionStatus.open;

    final (Color accent, Color bg, Color fg, IconData icon) = switch (status) {
      HelpQuestionStatus.open => (
        AppColors.warning,
        AppColors.warning.withValues(alpha: 0.12),
        AppColors.warning,
        Icons.schedule,
      ),
      HelpQuestionStatus.answered => (
        AppColors.success,
        AppColors.success.withValues(alpha: 0.12),
        AppColors.success,
        Icons.check_circle_outline,
      ),
      HelpQuestionStatus.closed => (
        AppColors.textMuted(context),
        AppColors.surface(context),
        AppColors.textMuted(context),
        Icons.lock_outline,
      ),
    };

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: AppColors.isDark(context) ? [] : AppShadows.cardLight,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.r16),
                    bottomLeft: Radius.circular(AppSpacing.r16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(issueIcon, color: accent, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.subject,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.label.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ticket.createdAtLabel,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textMuted(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 14, color: fg),
                                const SizedBox(width: 4),
                                Text(
                                  status.label,
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: fg,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(
                            icon: issueIcon,
                            label: ticket.issueType.label,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        ticket.body,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary(context),
                          height: 1.4,
                        ),
                      ),
                      if (ticket.hasAdminReply) ...[
                        const SizedBox(height: AppSpacing.s12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.s12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.r12,
                            ),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.support_agent,
                                    size: 16,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      [
                                        context.tr(RemainingL10n.adminReply),
                                        if (ticket.answeredAtLabel != null)
                                          ticket.answeredAtLabel!,
                                        if (ticket.answeredBy?.name != null)
                                          ticket.answeredBy!.name,
                                      ].join(' · '),
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.success,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ticket.answer!,
                                style: AppTypography.body.copyWith(
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (isOpen) ...[
                        const SizedBox(height: AppSpacing.s12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.r12,
                            ),
                            border: Border.all(
                              color: AppColors.border(context),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.hourglass_top_outlined,
                                size: 16,
                                color: AppColors.textMuted(context),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.tr(RemainingL10n.awaitingAdminReview),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textMuted(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (onClose != null) ...[
                        const SizedBox(height: AppSpacing.s12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: onClose,
                            icon: const Icon(Icons.close, size: 16),
                            label: Text(
                              context.tr(RemainingL10n.closeQuestionAction),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary(
                                context,
                              ),
                              side: BorderSide(
                                color: AppColors.border(context),
                              ),
                            ),
                          ),
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
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.bronze),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
