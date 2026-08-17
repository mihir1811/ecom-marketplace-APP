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
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ref.read(helpCenterMutationProvider.notifier).create(
          issueType: _issueType!,
          subject: subject,
          body: message,
        );
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
          const SnackBar(content: Text('Question submitted')),
        );
      case ResultFailure(failure: final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  Future<void> _closeQuestion(HelpQuestion question) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close question?'),
        content: const Text(
          'This will mark the ticket as closed. You can still read it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close'),
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
          const SnackBar(content: Text('Question closed')),
        );
      case ResultFailure(failure: final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.sandSurface,
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
                  'Help center',
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
                  'Ask our support team a question. Buyers and sellers can submit '
                  'tickets here: an admin will reply when your question is reviewed.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'New question',
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Include enough detail so we can help quickly — order IDs, '
                        'product links, or screenshots help.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Issue type', style: _labelStyle),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<HelpIssueType>(
                        key: ValueKey(_issueType?.name),
                        initialValue: _issueType,
                        hint: const Text('Select an issue type'),
                        items: [
                          for (final t in HelpIssueType.values)
                            DropdownMenuItem(value: t, child: Text(t.label)),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (v) => setState(() => _issueType = v),
                        decoration: _fieldDecoration('Select an issue type'),
                      ),
                      const SizedBox(height: 12),
                      Text('Subject', style: _labelStyle),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _subjectCtrl,
                        enabled: !_isSubmitting,
                        decoration: _fieldDecoration(
                          'e.g. Payment issue, account help',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Message', style: _labelStyle),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _messageCtrl,
                        enabled: !_isSubmitting,
                        maxLines: 4,
                        maxLength: 5000,
                        decoration: _fieldDecoration(
                          'Describe your issue or question in detail...',
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
                              : const Text('Submit question'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your questions',
                  style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
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
                    onRetry: () => ref
                        .read(helpQuestionListProvider.notifier)
                        .refresh(),
                  )
                else if (listState.items.isEmpty)
                  _Card(
                    child: Text(
                      'No questions yet. Submit one above and we will get back to you.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondaryLight,
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
                                child: const Text('Load more'),
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

  TextStyle get _labelStyle => AppTypography.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryLight,
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.warmBorder),
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
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
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
          AppColors.sandSurface,
          AppColors.textMutedLight,
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
                        color: AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ticket.issueType.label,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              color: AppColors.textSecondaryLight,
            ),
          ),
          if (ticket.hasAdminReply) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warmBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADMIN REPLY'
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
              'Awaiting admin review',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMutedLight,
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
                label: const Text('Close question'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
