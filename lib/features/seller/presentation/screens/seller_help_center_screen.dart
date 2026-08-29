import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../help_center/application/help_center_provider.dart';
import '../../../help_center/domain/models/help_question.dart';
import '../widgets/seller_layout.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/remaining_messages.dart';

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
        setState(() {
          _issueType = null;
          _subjectCtrl.clear();
          _messageCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(RemainingL10n.questionSubmitted))),
        );
      case ResultFailure(failure: final failure):
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(RemainingL10n.questionClosed))),
        );
      case ResultFailure(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.field(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(helpQuestionListProvider);

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
              padding: const EdgeInsets.all(AppSpacing.s16),
              children: [
                Text(
                  context.tr(RemainingL10n.askOurSupportTeamAQuestion),
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.tr(RemainingL10n.newQuestion),
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr(RemainingL10n.includeEnoughDetailSoWeCan),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.tr(RemainingL10n.issueType),
                        style: _labelStyle(context),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<HelpIssueType>(
                        key: ValueKey(_issueType?.name),
                        initialValue: _issueType,
                        hint: Text(context.tr(RemainingL10n.selectIssueType)),
                        items: [
                          for (final t in HelpIssueType.values)
                            DropdownMenuItem(value: t, child: Text(t.label)),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (v) => setState(() => _issueType = v),
                        decoration: _fieldDecoration(
                          context.tr(RemainingL10n.selectIssueType),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr(RemainingL10n.subject),
                        style: _labelStyle(context),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _subjectCtrl,
                        enabled: !_isSubmitting,
                        decoration: _fieldDecoration(
                          context.tr(RemainingL10n.helpSubjectHint),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr(RemainingL10n.message),
                        style: _labelStyle(context),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _messageCtrl,
                        enabled: !_isSubmitting,
                        maxLines: 4,
                        maxLength: 5000,
                        decoration: _fieldDecoration(
                          context.tr(RemainingL10n.helpDescriptionHint),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.info,
                            foregroundColor: AppColors.warmWhite,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.warmWhite,
                                  ),
                                )
                              : Text(context.tr(RemainingL10n.submitQuestion)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr(RemainingL10n.yourQuestions),
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (listState.isLoading && listState.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
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
                  _Card(
                    child: Text(
                      context.tr(RemainingL10n.noQuestionsYetSubmitOneAboveAnd),
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  )
                else ...[
                  for (final ticket in listState.items) ...[
                    _TicketCard(
                      ticket: ticket,
                      onClose: ticket.canClose
                          ? () => _closeQuestion(ticket)
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (listState.hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 16),
                      child: Center(
                        child: listState.isLoadingMore
                            ? const CircularProgressIndicator()
                            : OutlinedButton(
                                onPressed: () => ref
                                    .read(helpQuestionListProvider.notifier)
                                    .loadMore(),
                                child: Text(context.tr(RemainingL10n.loadMore)),
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

  TextStyle _labelStyle(BuildContext context) => AppTypography.caption.copyWith(
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary(context),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: child,
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
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: AppTypography.body.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.tr(RemainingL10n.retry)),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, this.onClose});

  final HelpQuestion ticket;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final status = ticket.status;
    final isOpen = status == HelpQuestionStatus.open;

    final (Color bg, Color fg, IconData icon) = switch (status) {
      HelpQuestionStatus.open => (
        AppColors.warning.withValues(alpha: 0.12),
        AppColors.warning,
        Icons.schedule,
      ),
      HelpQuestionStatus.answered => (
        AppColors.success.withValues(alpha: 0.12),
        AppColors.success,
        Icons.check_circle_outline,
      ),
      HelpQuestionStatus.closed => (
        AppColors.surface(context),
        AppColors.textMuted(context),
        Icons.lock_outline,
      ),
    };

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.subject,
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.createdAtLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ticket.issueType.label,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
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
          const SizedBox(height: 10),
          Text(
            ticket.body,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          if (ticket.hasAdminReply) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(RemainingL10n.adminReply) +
                        '${ticket.answeredAtLabel != null ? ' · ${ticket.answeredAtLabel}' : ''}'
                            '${ticket.answeredBy?.name != null ? ' · ${ticket.answeredBy!.name}' : ''}',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(ticket.answer!),
                ],
              ),
            ),
          ] else if (isOpen) ...[
            const SizedBox(height: 8),
            Text(
              context.tr(RemainingL10n.awaitingAdminReview),
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (onClose != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 18),
                label: Text(context.tr(RemainingL10n.closeQuestionAction)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
