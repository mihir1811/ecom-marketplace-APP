import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../help_center/application/help_center_provider.dart';
import '../../../help_center/domain/models/help_question.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_studio.dart';
import '../atelier/atelier_theme.dart';
import '../widgets/seller_layout.dart';

/// Seller concierge: pick a topic (or start blank) to ask support, then
/// follow every question from "awaiting review" to the team's reply.
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
  // Draft lives here so closing the composer never loses what was typed.
  HelpIssueType? _issueType;
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  HelpQuestionStatus? _filter;
  final Set<String> _expanded = {};
  final Set<String> _closing = {};

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(helpQuestionListProvider.notifier).refresh();

  Future<void> _compose([HelpIssueType? type]) async {
    if (type != null) setState(() => _issueType = type);
    final submitted = await showAtelierSheet<bool>(
      context: context,
      title: context.tr(RemainingL10n.newQuestion),
      subtitle: context.tr(RemainingL10n.includeEnoughDetailSoWeCan),
      builder: (_) => _QuestionComposer(
        initialType: _issueType,
        subjectCtrl: _subjectCtrl,
        messageCtrl: _messageCtrl,
        onTypeChanged: (t) => _issueType = t,
      ),
    );
    if (!mounted) return;
    if (submitted == true) {
      setState(() {
        _issueType = null;
        _subjectCtrl.clear();
        _messageCtrl.clear();
        _filter = null;
      });
      showAtelierToast(
        context,
        context.tr(RemainingL10n.questionSubmitted),
        tone: AtelierTone.emerald,
      );
    } else {
      setState(() {});
    }
  }

  Future<void> _closeQuestion(HelpQuestion question) async {
    final confirmed = await showAtelierConfirm(
      context: context,
      title: context.tr(RemainingL10n.closeQuestion),
      message: context.tr(RemainingL10n.thisWillMarkTheTicketAsClosed),
      confirmLabel: context.tr(RemainingL10n.close),
      cancelLabel: context.tr(RemainingL10n.cancel),
      icon: Icons.lock_outline_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() => _closing.add(question.id));
    final result = await ref
        .read(helpCenterMutationProvider.notifier)
        .close(id: question.id);
    if (!mounted) return;
    setState(() => _closing.remove(question.id));

    switch (result) {
      case Success():
        AppHaptics.success();
        showAtelierToast(context, context.tr(RemainingL10n.questionClosed));
      case ResultFailure(failure: final failure):
        AppHaptics.error();
        showAtelierToast(context, failure.message, tone: AtelierTone.ruby);
    }
  }

  void _toggle(String id) {
    AppHaptics.selection();
    setState(
      () => _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final listState = ref.watch(helpQuestionListProvider);
    final items = listState.items;
    int count(HelpQuestionStatus s) => items.where((q) => q.status == s).length;
    final openCount = count(HelpQuestionStatus.open);
    final answeredCount = count(HelpQuestionStatus.answered);
    final closedCount = count(HelpQuestionStatus.closed);
    final total = listState.total > items.length
        ? listState.total
        : items.length;
    final firstLoad = listState.isLoading && items.isEmpty;
    final visible = _filter == null
        ? items
        : items.where((q) => q.status == _filter).toList();
    final hasDraft =
        _subjectCtrl.text.trim().isNotEmpty ||
        _messageCtrl.text.trim().isNotEmpty;

    final page = AtelierPage(
      onRefresh: _refresh,
      maxWidth: 1080,
      onNearEnd: listState.errorMessage == null
          ? () => ref.read(helpQuestionListProvider.notifier).loadMore()
          : null,
      children: [
        AtelierHero(
          overline: 'Seller concierge',
          title: context.tr(RemainingL10n.helpCenter),
          subtitle: context.tr(RemainingL10n.askOurSupportTeamAQuestion),
          cut: GemCut.oval,
          action: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AtelierButton(
                label: hasDraft
                    ? 'Continue your draft'
                    : context.tr(RemainingL10n.newQuestion),
                icon: hasDraft
                    ? Icons.edit_note_rounded
                    : Icons.add_comment_outlined,
                variant: AtelierButtonVariant.gold,
                onPressed: _compose,
              ),
            ],
          ),
          footer: AtelierHeroStats(
            stats: [
              AtelierHeroStat(
                label: 'Awaiting reply',
                value: firstLoad ? '—' : '$openCount',
                caption: 'With our team',
                tone: openCount > 0 ? AtelierTone.amber : null,
              ),
              AtelierHeroStat(
                label: 'Answered',
                value: firstLoad ? '—' : '$answeredCount',
                caption: 'Replies to read',
                tone: answeredCount > 0 ? AtelierTone.emerald : null,
              ),
              AtelierHeroStat(
                label: 'All questions',
                value: firstLoad ? '—' : '$total',
                caption: 'Asked so far',
              ),
            ],
          ),
        ),
        const SizedBox(height: AtelierSpace.s32),
        const Reveal(
          index: 1,
          child: AtelierSectionHeader(
            overline: 'Start here',
            title: 'What do you need help with?',
            subtitle: 'Choose a topic and we’ll route it to the right team.',
          ),
        ),
        const SizedBox(height: AtelierSpace.s16),
        AtelierTileGrid(
          columns: 3,
          minTileWidth: 160,
          children: [
            for (final type in HelpIssueType.values)
              _TopicTile(type: type, onTap: () => _compose(type)),
          ],
        ),
        const SizedBox(height: AtelierSpace.s40),
        Reveal(
          index: 2,
          child: AtelierSectionHeader(
            overline: 'Your desk',
            title: context.tr(RemainingL10n.yourQuestions),
            subtitle: firstLoad
                ? null
                : total == 0
                ? 'Nothing asked yet.'
                : '$total ${total == 1 ? 'question' : 'questions'}'
                      '${openCount > 0 ? ' · $openCount awaiting reply' : ''}',
          ),
        ),
        const SizedBox(height: AtelierSpace.s16),
        if (items.isNotEmpty) ...[
          Reveal(
            index: 3,
            child: AtelierSegmented<HelpQuestionStatus?>(
              selected: _filter,
              onChanged: (v) => setState(() => _filter = v),
              dense: true,
              segments: [
                AtelierSegment(
                  value: null,
                  label: context.tr(RemainingL10n.all),
                  count: items.length,
                ),
                AtelierSegment(
                  value: HelpQuestionStatus.open,
                  label: HelpQuestionStatus.open.label,
                  icon: Icons.schedule_rounded,
                  count: openCount,
                ),
                AtelierSegment(
                  value: HelpQuestionStatus.answered,
                  label: HelpQuestionStatus.answered.label,
                  icon: Icons.mark_email_read_outlined,
                  count: answeredCount,
                ),
                AtelierSegment(
                  value: HelpQuestionStatus.closed,
                  label: HelpQuestionStatus.closed.label,
                  icon: Icons.lock_outline_rounded,
                  count: closedCount,
                ),
              ],
            ),
          ),
          const SizedBox(height: AtelierSpace.s16),
        ],
        ..._tickets(listState, visible),
      ],
    );

    if (!widget.showHeader) return ColoredBox(color: p.canvas, child: page);
    return ColoredBox(
      color: p.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 16, 4),
            child: Row(
              children: [
                AtelierIconButton(
                  icon: Icons.menu_rounded,
                  tooltip: context.tr(RemainingL10n.menu),
                  onPressed: () => openSellerDrawer(context),
                  filled: true,
                ),
                const SizedBox(width: 12),
                Text(
                  context.tr(RemainingL10n.helpCenter),
                  style: AtelierType.display(p.ink, size: 24),
                ),
              ],
            ),
          ),
          Expanded(child: page),
        ],
      ),
    );
  }

  List<Widget> _tickets(HelpQuestionListState s, List<HelpQuestion> visible) {
    if (s.isLoading && s.items.isEmpty) {
      return const [AtelierSkeletonList(count: 3, height: 112)];
    }
    if (s.errorMessage != null && s.items.isEmpty) {
      return [
        AtelierErrorState(
          compact: true,
          title: 'Couldn’t load your questions',
          message: s.errorMessage!,
          onRetry: _refresh,
        ),
      ];
    }
    if (s.items.isEmpty) {
      return [
        AtelierCard(
          child: AtelierEmptyState(
            compact: true,
            icon: Icons.forum_outlined,
            title: 'No questions yet',
            message: context.tr(RemainingL10n.noQuestionsYetSubmitOneAboveAnd),
            actionLabel: context.tr(RemainingL10n.newQuestion),
            onAction: _compose,
          ),
        ),
      ];
    }
    return [
      if (visible.isEmpty)
        AtelierEmptyState(
          compact: true,
          icon: Icons.filter_alt_off_outlined,
          title: 'Nothing here',
          message:
              'No ${_filter?.label.toLowerCase() ?? ''} questions right now.',
          actionLabel: 'Show all',
          onAction: () => setState(() => _filter = null),
        ),
      for (var i = 0; i < visible.length; i++)
        Padding(
          key: ValueKey(visible[i].id),
          padding: const EdgeInsets.only(bottom: AtelierSpace.s12),
          child: Reveal(
            index: i,
            child: _TicketCard(
              ticket: visible[i],
              expanded: _expanded.contains(visible[i].id),
              closing: _closing.contains(visible[i].id),
              onToggle: () => _toggle(visible[i].id),
              onClose: visible[i].canClose
                  ? () => _closeQuestion(visible[i])
                  : null,
            ),
          ),
        ),
      if (s.errorMessage != null) ...[
        const SizedBox(height: AtelierSpace.s4),
        AtelierNotice(
          text: s.errorMessage!,
          tone: AtelierTone.ruby,
          icon: Icons.cloud_off_rounded,
          actionLabel: context.tr(RemainingL10n.retry),
          onAction: () =>
              ref.read(helpQuestionListProvider.notifier).loadMore(),
        ),
      ],
      if (s.hasMore)
        Padding(
          padding: const EdgeInsets.only(top: AtelierSpace.s8),
          child: Center(
            child: AnimatedSwitcher(
              duration: AtelierMotion.base,
              child: s.isLoadingMore
                  ? Padding(
                      key: const ValueKey('loading'),
                      padding: const EdgeInsets.all(AtelierSpace.s12),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.atelier.gold,
                        ),
                      ),
                    )
                  : AtelierButton(
                      key: const ValueKey('more'),
                      label: context.tr(RemainingL10n.loadMore),
                      icon: Icons.expand_more_rounded,
                      variant: AtelierButtonVariant.secondary,
                      compact: true,
                      onPressed: () => ref
                          .read(helpQuestionListProvider.notifier)
                          .loadMore(),
                    ),
            ),
          ),
        ),
    ];
  }
}

IconData _issueIcon(HelpIssueType type) => switch (type) {
  HelpIssueType.accountIssues => Icons.manage_accounts_outlined,
  HelpIssueType.billingPayments => Icons.payments_outlined,
  HelpIssueType.technicalIssues => Icons.build_circle_outlined,
  HelpIssueType.featureRequests => Icons.lightbulb_outline_rounded,
  HelpIssueType.generalInquiry => Icons.help_outline_rounded,
  HelpIssueType.others => Icons.more_horiz_rounded,
};

String _issueHint(HelpIssueType type) => switch (type) {
  HelpIssueType.accountIssues => 'Sign-in, verification, profile',
  HelpIssueType.billingPayments => 'Payouts, invoices, charges',
  HelpIssueType.technicalIssues => 'Errors, bugs, odd behaviour',
  HelpIssueType.featureRequests => 'Ideas to improve your studio',
  HelpIssueType.generalInquiry => 'Anything about selling here',
  HelpIssueType.others => 'Something else entirely',
};

(AtelierTone, IconData) _statusLook(HelpQuestionStatus s) => switch (s) {
  HelpQuestionStatus.open => (AtelierTone.amber, Icons.schedule_rounded),
  HelpQuestionStatus.answered => (
    AtelierTone.emerald,
    Icons.mark_email_read_outlined,
  ),
  HelpQuestionStatus.closed => (
    AtelierTone.neutral,
    Icons.lock_outline_rounded,
  ),
};

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.type, required this.onTap});

  final HelpIssueType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return AtelierCard(
      onTap: onTap,
      semanticLabel: 'Ask about ${type.label}',
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      child: Row(
        children: [
          AtelierIconBadge(icon: _issueIcon(type), size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.title(p.ink, size: 14.5),
                ),
                const SizedBox(height: 3),
                Text(
                  _issueHint(type),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.caption(p.muted, size: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 17, color: p.gold),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.expanded,
    required this.closing,
    required this.onToggle,
    this.onClose,
  });

  final HelpQuestion ticket;
  final bool expanded;
  final bool closing;
  final VoidCallback onToggle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final (tone, statusIcon) = _statusLook(ticket.status);
    final isOpen = ticket.status == HelpQuestionStatus.open;
    final replied = ticket.hasAdminReply;
    final answer = ticket.answer?.trim() ?? '';

    return AtelierCard(
      padding: EdgeInsets.zero,
      borderColor: expanded ? p.gold.withValues(alpha: 0.45) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            onTap: onToggle,
            scale: 0.99,
            semanticLabel:
                '${ticket.subject}, ${ticket.status.label}. '
                '${expanded ? 'Collapse' : 'Expand'}',
            borderRadius: BorderRadius.circular(AtelierRadius.lg),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AtelierIconBadge(
                    icon: _issueIcon(ticket.issueType),
                    tone: tone == AtelierTone.neutral ? AtelierTone.gold : tone,
                    size: 40,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.subject,
                          maxLines: expanded ? 4 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.title(p.ink, size: 15),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${ticket.issueType.label}  ·  ${ticket.createdAtLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.caption(p.muted, size: 11.5),
                        ),
                        AnimatedSize(
                          duration: AtelierMotion.base,
                          curve: AtelierMotion.emphasized,
                          alignment: Alignment.topLeft,
                          child: expanded
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    ticket.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AtelierType.body(
                                      p.inkSoft,
                                      size: 13,
                                    ),
                                  ),
                                ),
                        ),
                        if (!expanded && replied) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.support_agent_rounded,
                                size: 14,
                                color: p.emerald,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Support replied — tap to read',
                                  style: AtelierType.label(p.emerald, size: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AtelierPill(
                        label: ticket.status.label,
                        tone: tone,
                        icon: statusIcon,
                        dense: true,
                      ),
                      const SizedBox(height: 10),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: AtelierMotion.base,
                        curve: AtelierMotion.emphasized,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: p.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AtelierMotion.slow,
            curve: AtelierMotion.emphasized,
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AtelierHairline(),
                        const SizedBox(height: 16),
                        Text(
                          'YOUR QUESTION',
                          style: AtelierType.overline(p.muted),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          ticket.body,
                          style: AtelierType.body(p.inkSoft, size: 13.5),
                        ),
                        const SizedBox(height: 16),
                        if (replied)
                          Reveal(
                            child: _ReplyPanel(
                              answer: answer,
                              meta: [
                                context.tr(RemainingL10n.adminReply),
                                if (ticket.answeredAtLabel != null)
                                  ticket.answeredAtLabel!,
                                if (ticket.answeredBy?.name != null)
                                  ticket.answeredBy!.name,
                              ].join(' · '),
                            ),
                          )
                        else if (isOpen)
                          Row(
                            children: [
                              const AtelierPulseDot(tone: AtelierTone.amber),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  context.tr(RemainingL10n.awaitingAdminReview),
                                  style: AtelierType.caption(
                                    p.inkSoft,
                                    size: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (onClose != null) ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AtelierButton(
                              label: context.tr(
                                RemainingL10n.closeQuestionAction,
                              ),
                              icon: Icons.lock_outline_rounded,
                              variant: AtelierButtonVariant.secondary,
                              compact: true,
                              loading: closing,
                              onPressed: onClose,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReplyPanel extends StatelessWidget {
  const _ReplyPanel({required this.answer, required this.meta});

  final String answer;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.emerald.withValues(alpha: p.isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(AtelierRadius.md),
        border: Border.all(color: p.emerald.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AtelierIconBadge(
                icon: Icons.support_agent_rounded,
                tone: AtelierTone.emerald,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  meta,
                  style: AtelierType.label(p.emerald, size: 12),
                ),
              ),
            ],
          ),
          if (answer.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(answer, style: AtelierType.body(p.ink, size: 14)),
          ],
        ],
      ),
    );
  }
}

/// New-question form shown in a sheet. Writes straight into the screen's
/// controllers so a dismissed sheet keeps its draft.
class _QuestionComposer extends ConsumerStatefulWidget {
  const _QuestionComposer({
    required this.initialType,
    required this.subjectCtrl,
    required this.messageCtrl,
    required this.onTypeChanged,
  });

  final HelpIssueType? initialType;
  final TextEditingController subjectCtrl;
  final TextEditingController messageCtrl;
  final ValueChanged<HelpIssueType?> onTypeChanged;

  @override
  ConsumerState<_QuestionComposer> createState() => _QuestionComposerState();
}

class _QuestionComposerState extends ConsumerState<_QuestionComposer> {
  static const _maxLength = 5000;

  late HelpIssueType? _type = widget.initialType;
  bool _submitting = false;
  bool _tried = false;
  String? _failure;

  @override
  void initState() {
    super.initState();
    widget.messageCtrl.addListener(_onText);
    widget.subjectCtrl.addListener(_onText);
  }

  @override
  void dispose() {
    widget.messageCtrl.removeListener(_onText);
    widget.subjectCtrl.removeListener(_onText);
    super.dispose();
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  bool get _valid =>
      _type != null &&
      widget.subjectCtrl.text.trim().isNotEmpty &&
      widget.messageCtrl.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final subject = widget.subjectCtrl.text.trim();
    final message = widget.messageCtrl.text.trim();
    if (!_valid) {
      AppHaptics.warning();
      setState(() => _tried = true);
      return;
    }

    setState(() {
      _submitting = true;
      _failure = null;
    });
    final result = await ref
        .read(helpCenterMutationProvider.notifier)
        .create(issueType: _type!, subject: subject, body: message);
    if (!mounted) return;

    switch (result) {
      case Success():
        AppHaptics.success();
        Navigator.of(context).pop(true);
      case ResultFailure(failure: final failure):
        AppHaptics.error();
        setState(() {
          _submitting = false;
          _failure = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final length = widget.messageCtrl.text.length;
    final typeError = _tried && _type == null
        ? context.tr(RemainingL10n.selectIssueType)
        : null;
    final subjectError = _tried && widget.subjectCtrl.text.trim().isEmpty
        ? '${context.tr(RemainingL10n.subject)} is required'
        : null;
    final messageError = _tried && widget.messageCtrl.text.trim().isEmpty
        ? '${context.tr(RemainingL10n.message)} is required'
        : null;

    return PopScope(
      canPop: !_submitting,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Reveal(
            child: Text(
              context.tr(RemainingL10n.issueType).toUpperCase(),
              style: AtelierType.overline(typeError != null ? p.ruby : p.muted),
            ),
          ),
          const SizedBox(height: 10),
          Reveal(
            index: 1,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in HelpIssueType.values)
                  AtelierChoiceChip(
                    label: type.label,
                    icon: _issueIcon(type),
                    selected: _type == type,
                    onTap: _submitting
                        ? () {}
                        : () {
                            setState(() => _type = type);
                            widget.onTypeChanged(type);
                          },
                  ),
              ],
            ),
          ),
          AtelierFieldError(error: typeError),
          const SizedBox(height: 20),
          Reveal(
            index: 2,
            child: AtelierTextField(
              controller: widget.subjectCtrl,
              label: context.tr(RemainingL10n.subject),
              hint: 'A short summary, e.g. “Payout not received”',
              error: subjectError,
              enabled: !_submitting,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(200)],
            ),
          ),
          const SizedBox(height: 18),
          Reveal(
            index: 3,
            child: AtelierTextField(
              controller: widget.messageCtrl,
              label: context.tr(RemainingL10n.message),
              hint:
                  'What happened, what you expected, and any order or '
                  'stock numbers involved.',
              error: messageError,
              enabled: !_submitting,
              maxLines: 7,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(_maxLength)],
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$length / $_maxLength',
              style: AtelierType.figure(
                length > _maxLength * 0.9 ? p.amber : p.muted,
                size: 11,
                weight: FontWeight.w500,
              ),
            ),
          ),
          AnimatedSize(
            duration: AtelierMotion.base,
            curve: AtelierMotion.emphasized,
            child: _failure == null && !(_tried && !_valid)
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: AtelierNotice(
                      text: _failure ?? context.tr(RemainingL10n.fillAllFields),
                      tone: _failure != null
                          ? AtelierTone.ruby
                          : AtelierTone.amber,
                      icon: _failure != null
                          ? Icons.cloud_off_rounded
                          : Icons.info_outline_rounded,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Reveal(
            index: 4,
            child: AtelierButton(
              label: context.tr(RemainingL10n.submitQuestion),
              icon: Icons.send_rounded,
              variant: AtelierButtonVariant.gold,
              loading: _submitting,
              expand: true,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
