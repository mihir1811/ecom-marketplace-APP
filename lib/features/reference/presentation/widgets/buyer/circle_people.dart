import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/result.dart';
import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../application/reference_providers.dart';
import '../../../domain/models/reference_models.dart';

AtelierTone circleStatusTone(ReferenceStatus s) => switch (s) {
  ReferenceStatus.accepted => AtelierTone.emerald,
  ReferenceStatus.pending => AtelierTone.amber,
  ReferenceStatus.rejected => AtelierTone.ruby,
};

String _when(String label) => label.trim() == '—' ? '' : label.trim();

/// One person in the buyer's circle: monogram, name, email and date.
class CirclePersonRow extends StatelessWidget {
  const CirclePersonRow({required this.request, super.key});

  final ReferenceRequest request;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final party = request.party;
    final name = party?.displayName ?? request.partyLabel;
    final when = _when(request.acceptedAtLabel ?? request.createdAtLabel);
    final email = party?.email.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          AtelierMonogram(name: name, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.label(p.ink, size: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (email.isNotEmpty && email != name) email,
                    if (when.isNotEmpty) 'since $when',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.caption(p.muted, size: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AtelierPill(
            label: request.status.label,
            tone: circleStatusTone(request.status),
            dense: true,
          ),
        ],
      ),
    );
  }
}

/// A request waiting on the buyer: who asked, when, Decline / Accept.
class CircleRequestCard extends StatelessWidget {
  const CircleRequestCard({
    required this.request,
    required this.busy,
    required this.onDecide,
    super.key,
  });

  final ReferenceRequest request;
  final bool busy;
  final void Function({required bool accept}) onDecide;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final party = request.party;
    final name = party?.displayName ?? request.partyLabel;
    final email = party?.email.trim() ?? '';
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(color: p.amber.withValues(alpha: 0.3)),
        boxShadow: p.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: p.amber.withValues(alpha: 0.7)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        AtelierMonogram(name: name, size: 42),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AtelierType.title(p.ink, size: 15),
                              ),
                              if (email.isNotEmpty && email != name) ...[
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AtelierType.caption(p.inkSoft),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const AtelierPulseDot(
                                    tone: AtelierTone.amber,
                                    size: 6,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      context.tr(RemainingL10n.requestedDate, {
                                        'date': request.createdAtLabel,
                                      }),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AtelierType.caption(
                                        p.muted,
                                        size: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Wants you as their reference. Accepting links their '
                      'qualifying orders to your commission.',
                      style: AtelierType.caption(p.inkSoft, size: 12),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AtelierButton(
                            label: context.tr(RemainingL10n.reject),
                            compact: true,
                            variant: AtelierButtonVariant.secondary,
                            onPressed: busy
                                ? null
                                : () => onDecide(accept: false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: AtelierButton(
                            label: context.tr(RemainingL10n.accept),
                            icon: Icons.check_rounded,
                            compact: true,
                            variant: AtelierButtonVariant.gold,
                            loading: busy,
                            onPressed: () => onDecide(accept: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact "who referred you" card; opens [showCircleSponsorSheet].
class CircleSponsorTile extends StatelessWidget {
  const CircleSponsorTile({
    required this.profile,
    required this.onOpen,
    super.key,
  });

  final ReferenceProfile? profile;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final active = profile?.activeOutbound;
    final earlier = profile?.outboundHistory.length ?? 0;
    final name = active?.party?.displayName ?? active?.partyLabel;

    return AtelierCard(
      onTap: onOpen,
      semanticLabel: active == null
          ? 'Add your reference'
          : 'Your reference, $name, ${active.status.label}',
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      child: Row(
        children: [
          if (active != null)
            AtelierMonogram(name: name!, size: 42)
          else
            const AtelierIconBadge(
              icon: Icons.person_add_alt_1_outlined,
              size: 42,
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active == null ? 'YOUR REFERENCE' : 'REFERRED BY',
                  style: AtelierType.overline(p.gold),
                ),
                const SizedBox(height: 5),
                Text(
                  active == null ? 'Who introduced you?' : name!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.title(p.ink, size: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  active == null
                      ? 'Link them with their email or code.'
                      : [
                          active.status == ReferenceStatus.pending
                              ? 'Awaiting their answer'
                              : active.status.label,
                          if (earlier > 0)
                            '$earlier earlier '
                                '${earlier == 1 ? 'request' : 'requests'}',
                        ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.caption(p.muted, size: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (active != null) ...[
            AtelierPill(
              label: active.status.label,
              tone: circleStatusTone(active.status),
              dense: true,
            ),
            const SizedBox(width: 6),
          ],
          Icon(Icons.chevron_right_rounded, color: p.muted, size: 20),
        ],
      ),
    );
  }
}

/// Sheet for the buyer's own reference: the link and its progress, or a
/// form to request one, plus every earlier request.
Future<void> showCircleSponsorSheet(BuildContext context) {
  return showAtelierSheet<void>(
    context: context,
    title: context.tr(RemainingL10n.myReference2),
    builder: (_) => const _SponsorSheetBody(),
  );
}

class _SponsorSheetBody extends ConsumerStatefulWidget {
  const _SponsorSheetBody();

  @override
  ConsumerState<_SponsorSheetBody> createState() => _SponsorSheetBodyState();
}

class _SponsorSheetBodyState extends ConsumerState<_SponsorSheetBody> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (_busy) return;
    if (value.isEmpty) {
      AppHaptics.error();
      setState(() => _error = 'Enter an email or referral code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(referenceHubProvider.notifier).request(value);
    if (!mounted) return;
    switch (result) {
      case Success():
        AppHaptics.success();
        _controller.clear();
        setState(() => _busy = false);
        showAtelierToast(
          context,
          context.tr(RemainingL10n.referenceSent),
          tone: AtelierTone.emerald,
        );
      case ResultFailure(:final failure):
        AppHaptics.error();
        setState(() {
          _busy = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final profile = ref.watch(referenceHubProvider.select((s) => s.profile));
    final active = profile?.activeOutbound;
    final history = profile?.outboundHistory ?? const <ReferenceRequest>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: AtelierMotion.base,
          child: active != null
              ? _SponsorJourney(key: ValueKey(active.id), request: active)
              : Column(
                  key: const ValueKey('form'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr(
                        RemainingL10n.addSomeoneAsYourReferenceUsingTheir,
                      ),
                      style: AtelierType.body(p.inkSoft, size: 13),
                    ),
                    const SizedBox(height: 16),
                    AtelierTextField(
                      controller: _controller,
                      label: 'Email or referral code',
                      hint: context.tr(RemainingL10n.emailReferralCode),
                      enabled: !_busy,
                      autofocus: true,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.send,
                      error: _error,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 14),
                    AtelierButton(
                      label: context.tr(RemainingL10n.request),
                      icon: Icons.send_rounded,
                      expand: true,
                      loading: _busy,
                      onPressed: _submit,
                    ),
                  ],
                ),
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 26),
          Row(
            children: [
              Text(
                context.tr(RemainingL10n.requestHistory).toUpperCase(),
                style: AtelierType.overline(p.inkSoft),
              ),
              const SizedBox(width: 8),
              Text(
                '${history.length}',
                style: AtelierType.figure(p.muted, size: 11),
              ),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 1, color: p.hairline)),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < history.length; i++) ...[
            if (i > 0) const AtelierHairline(),
            Reveal(
              index: i < 6 ? i : 0,
              offset: 6,
              child: CirclePersonRow(request: history[i]),
            ),
          ],
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Requested → answered, as two stations on a fine rule.
class _SponsorJourney extends StatelessWidget {
  const _SponsorJourney({required this.request, super.key});

  final ReferenceRequest request;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final party = request.party;
    final name = party?.displayName ?? request.partyLabel;
    final tone = circleStatusTone(request.status);
    final pending = request.status == ReferenceStatus.pending;
    final answered = _when(request.acceptedAtLabel ?? '');

    Widget station({
      required String title,
      required String caption,
      required Color color,
      bool pulse = false,
    }) {
      return Row(
        children: [
          SizedBox(
            width: 18,
            child: Center(
              child: pulse
                  ? AtelierPulseDot(tone: tone, size: 9)
                  : Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AtelierType.label(p.ink, size: 13)),
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    style: AtelierType.caption(p.muted, size: 11.5),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.sunken.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AtelierMonogram(name: name, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(RemainingL10n.referrer).trim().toUpperCase(),
                      style: AtelierType.overline(p.gold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.display(p.ink, size: 22),
                    ),
                    if ((party?.email.trim() ?? '').isNotEmpty &&
                        party!.email != name)
                      Text(
                        party.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.caption(p.muted),
                      ),
                  ],
                ),
              ),
              AtelierPill(label: request.status.label, tone: tone, dense: true),
            ],
          ),
          const SizedBox(height: 18),
          station(
            title: 'Request sent',
            caption: _when(request.createdAtLabel),
            color: p.gold,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 1, height: 16, color: p.hairline),
            ),
          ),
          station(
            title: switch (request.status) {
              ReferenceStatus.pending => 'Awaiting their answer',
              ReferenceStatus.accepted => 'Accepted',
              ReferenceStatus.rejected => 'Declined',
            },
            caption: pending
                ? 'We’ll let you know when they respond.'
                : answered,
            color: p.tone(tone),
            pulse: pending,
          ),
        ],
      ),
    );
  }
}
