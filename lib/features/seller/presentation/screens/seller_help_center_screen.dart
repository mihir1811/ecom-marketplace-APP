import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/seller_layout.dart';

enum _IssueType {
  accountIssues('Account issues'),
  billing('Billing and payments'),
  technical('Technical issue'),
  featureRequest('Feature request'),
  general('General inquiry'),
  other('Other');

  const _IssueType(this.label);
  final String label;
}

enum _TicketStatus { open, closed }

class _HelpTicket {
  _HelpTicket({
    required this.subject,
    required this.message,
    required this.createdAt,
    required this.status,
    this.adminReply,
    this.adminReplyAt,
  });

  final String subject;
  final String message;
  final String createdAt;
  _TicketStatus status;
  final String? adminReply;
  final String? adminReplyAt;
}

class SellerHelpCenterScreen extends StatefulWidget {
  const SellerHelpCenterScreen({super.key});

  @override
  State<SellerHelpCenterScreen> createState() => _SellerHelpCenterScreenState();
}

class _SellerHelpCenterScreenState extends State<SellerHelpCenterScreen> {
  _IssueType? _issueType;
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  final _tickets = <_HelpTicket>[
    _HelpTicket(
      subject: 'test',
      message: 'Need help verifying my seller account documents.',
      createdAt: '20/07/2026, 14:22:10',
      status: _TicketStatus.open,
    ),
    _HelpTicket(
      subject: 'sdfg',
      message: 'Payment settlement delay for order 9D38AA35.',
      createdAt: '18/07/2026, 09:41:03',
      status: _TicketStatus.closed,
      adminReply: 'Refund settlement completed. Please check your payouts.',
      adminReplyAt: '19/07/2026, 11:05:00',
    ),
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (_issueType == null || subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    setState(() {
      _tickets.insert(
        0,
        _HelpTicket(
          subject: subject,
          message: message,
          createdAt:
              '${two(now.day)}/${two(now.month)}/${now.year}, ${two(now.hour)}:${two(now.minute)}:${two(now.second)}',
          status: _TicketStatus.open,
        ),
      );
      _issueType = null;
      _subjectCtrl.clear();
      _messageCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question submitted')),
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                    DropdownButtonFormField<_IssueType>(
                      key: ValueKey(_issueType?.name),
                      initialValue: _issueType,
                      hint: const Text('Select an issue type'),
                      items: [
                        for (final t in _IssueType.values)
                          DropdownMenuItem(value: t, child: Text(t.label)),
                      ],
                      onChanged: (v) => setState(() => _issueType = v),
                      decoration: _fieldDecoration('Select an issue type'),
                    ),
                    const SizedBox(height: 12),
                    Text('Subject', style: _labelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _subjectCtrl,
                      decoration: _fieldDecoration(
                        'e.g. Payment issue, account help',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Message', style: _labelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _messageCtrl,
                      maxLines: 4,
                      decoration: _fieldDecoration(
                        'Describe your issue or question in detail...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: AppColors.warmWhite,
                        ),
                        child: const Text('Submit question'),
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
              for (final ticket in _tickets) ...[
                _TicketCard(
                  ticket: ticket,
                  onResolve: () {
                    setState(() => ticket.status = _TicketStatus.closed);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
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

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onResolve});

  final _HelpTicket ticket;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final isOpen = ticket.status == _TicketStatus.open;
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
                      ticket.createdAt,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen
                      ? AppColors.warning.withValues(alpha: 0.12)
                      : AppColors.sandSurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOpen ? Icons.schedule : Icons.lock_outline,
                      size: 14,
                      color: isOpen
                          ? AppColors.warning
                          : AppColors.textMutedLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOpen ? 'Open' : 'Closed',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isOpen
                            ? AppColors.warning
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ticket.message,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          if (ticket.adminReply != null) ...[
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
                    'ADMIN REPLY - ${ticket.adminReplyAt}',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(ticket.adminReply!),
                ],
              ),
            ),
          ],
          if (isOpen) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onResolve,
                child: const Text('Mark as resolved'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
