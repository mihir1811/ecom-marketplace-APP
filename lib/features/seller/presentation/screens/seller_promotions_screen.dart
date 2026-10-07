import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../promotions/application/promotions_providers.dart';
import '../../../promotions/domain/models/promotion.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_studio.dart';
import '../atelier/atelier_theme.dart';

enum _PromoTab { discounts, promoCodes }

enum _Kind { discount, code }

/// Promotions studio: storewide discounts and shareable promo codes, shown
/// as tickets with their schedule and usage at a glance.
class SellerPromotionsScreen extends ConsumerStatefulWidget {
  const SellerPromotionsScreen({super.key});

  @override
  ConsumerState<SellerPromotionsScreen> createState() =>
      _SellerPromotionsScreenState();
}

class _SellerPromotionsScreenState
    extends ConsumerState<SellerPromotionsScreen> {
  _PromoTab _tab = _PromoTab.discounts;
  final Set<String> _deleting = {};

  Future<void> _refresh() =>
      ref.read(sellerPromotionsProvider.notifier).refresh();

  Future<void> _create([_Kind? kind]) async {
    if (!AccountAccess.guard(context, ref)) return;
    final chosen =
        kind ??
        await showAtelierOptions<_Kind>(
          context: context,
          title: 'New promotion',
          subtitle: 'Choose how buyers will receive the saving.',
          options: [
            AtelierOption(
              value: _Kind.discount,
              label: context.tr(RemainingL10n.addDiscount),
              icon: Icons.percent_rounded,
              hint: 'Applied automatically for a date range',
            ),
            AtelierOption(
              value: _Kind.code,
              label: context.tr(RemainingL10n.addPromoCode),
              icon: Icons.confirmation_number_outlined,
              hint: 'A code buyers enter at checkout',
            ),
          ],
        );
    if (chosen == null || !mounted) return;
    setState(
      () => _tab = chosen == _Kind.discount
          ? _PromoTab.discounts
          : _PromoTab.promoCodes,
    );
    await showAtelierSheet<void>(
      context: context,
      title: chosen == _Kind.discount
          ? context.tr(RemainingL10n.addDiscount)
          : context.tr(RemainingL10n.addPromoCode),
      subtitle: chosen == _Kind.discount
          ? 'Runs automatically between the dates you set.'
          : 'Share the code; buyers redeem it at checkout.',
      builder: (_) => _PromotionForm(kind: chosen),
    );
  }

  Future<void> _delete({
    required String id,
    required String name,
    required bool isCode,
  }) async {
    final ok = await showAtelierConfirm(
      context: context,
      title: isCode ? 'Delete promo code?' : 'Delete discount?',
      message: '“$name” will stop applying immediately. This can’t be undone.',
      confirmLabel: context.tr(RemainingL10n.delete),
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _deleting.add(id));
    final notifier = ref.read(sellerPromotionsProvider.notifier);
    final Result<Object, Failure> result = isCode
        ? await notifier.deletePromoCode(id)
        : await notifier.deleteDiscount(id);
    if (!mounted) return;
    setState(() => _deleting.remove(id));
    switch (result) {
      case Success():
        AppHaptics.warning();
        showAtelierToast(context, '“$name” deleted');
      case ResultFailure(:final failure):
        AppHaptics.error();
        showAtelierToast(context, failure.message, tone: AtelierTone.ruby);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final state = ref.watch(sellerPromotionsProvider);
    final isDiscounts = _tab == _PromoTab.discounts;
    final liveDiscounts = state.discounts
        .where(
          (d) =>
              _Schedule.of(
                d.isActive,
                d.startDateLabel,
                d.endDateLabel,
              ).phase ==
              _Phase.live,
        )
        .length;
    final liveCodes = state.promoCodes
        .where(
          (c) =>
              _Schedule.of(
                c.isActive,
                c.startDateLabel,
                c.endDateLabel,
              ).phase ==
              _Phase.live,
        )
        .length;
    final redemptions = state.promoCodes.fold<int>(
      0,
      (s, c) => s + (c.usedCount ?? 0),
    );
    final loaded =
        !state.isLoading ||
        state.discounts.isNotEmpty ||
        state.promoCodes.isNotEmpty;

    return AtelierPage(
      onRefresh: _refresh,
      children: [
        AtelierHero(
          overline: 'Growth',
          title: context.tr(RemainingL10n.promotions),
          subtitle:
              'Storewide discounts and shareable codes — schedule them, '
              'watch them work.',
          cut: GemCut.pear,
          action: AtelierButton(
            label: 'New promotion',
            icon: Icons.add_rounded,
            variant: AtelierButtonVariant.gold,
            onPressed: state.isMutating ? null : _create,
          ),
          footer: AtelierHeroStats(
            stats: [
              AtelierHeroStat(
                label: 'Live discounts',
                value: loaded ? '$liveDiscounts' : '—',
                caption: '${state.discounts.length} in total',
                tone: liveDiscounts > 0 ? AtelierTone.emerald : null,
              ),
              AtelierHeroStat(
                label: 'Live codes',
                value: loaded ? '$liveCodes' : '—',
                caption: '${state.promoCodes.length} in total',
                tone: liveCodes > 0 ? AtelierTone.emerald : null,
              ),
              AtelierHeroStat(
                label: 'Redemptions',
                value: loaded ? '$redemptions' : '—',
                caption: 'Across all codes',
              ),
            ],
          ),
        ),
        const SizedBox(height: AtelierSpace.s24),
        Reveal(
          index: 2,
          child: AtelierSegmented<_PromoTab>(
            expand: true,
            segments: [
              AtelierSegment(
                value: _PromoTab.discounts,
                label: context.tr(RemainingL10n.discounts),
                icon: Icons.percent_rounded,
                count: state.discounts.length,
              ),
              AtelierSegment(
                value: _PromoTab.promoCodes,
                label: context.tr(RemainingL10n.promoCodes),
                icon: Icons.confirmation_number_outlined,
                count: state.promoCodes.length,
              ),
            ],
            selected: _tab,
            onChanged: (t) => setState(() => _tab = t),
          ),
        ),
        AnimatedSwitcher(
          duration: AtelierMotion.base,
          child: state.isMutating || (state.isLoading && loaded)
              ? Padding(
                  key: const ValueKey('busy'),
                  padding: const EdgeInsets.only(top: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: p.gold,
                      backgroundColor: p.sunken,
                    ),
                  ),
                )
              : const SizedBox(key: ValueKey('idle'), height: 12),
        ),
        if (state.errorMessage != null &&
            (state.discounts.isNotEmpty || state.promoCodes.isNotEmpty)) ...[
          const SizedBox(height: AtelierSpace.s8),
          AtelierNotice(
            text: state.errorMessage!,
            tone: AtelierTone.ruby,
            icon: Icons.error_outline_rounded,
            actionLabel: context.tr(RemainingL10n.retry),
            onAction: _refresh,
          ),
        ],
        const SizedBox(height: AtelierSpace.s12),
        AnimatedSwitcher(
          duration: AtelierMotion.base,
          switchInCurve: AtelierMotion.emphasized,
          child: KeyedSubtree(
            key: ValueKey('$_tab-${state.isLoading && !loaded}'),
            child: _body(context, state, isDiscounts),
          ),
        ),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    SellerPromotionsState state,
    bool isDiscounts,
  ) {
    if (state.isLoading &&
        state.discounts.isEmpty &&
        state.promoCodes.isEmpty) {
      return const AtelierSkeletonList(count: 3, height: 128);
    }
    if (state.errorMessage != null &&
        state.discounts.isEmpty &&
        state.promoCodes.isEmpty) {
      return AtelierErrorState(
        title: 'Promotions unavailable',
        message: state.errorMessage!,
        onRetry: _refresh,
      );
    }
    final tickets = <Widget>[
      if (isDiscounts)
        for (final d in state.discounts)
          _Ticket(
            key: ValueKey('d-${d.id}'),
            stubValue: _valueLabel(d.type, d.value),
            stubCaption: d.type == PromotionType.percentage
                ? 'off'
                : 'flat off',
            title: d.name,
            description: d.description,
            schedule: _Schedule.of(
              d.isActive,
              d.startDateLabel,
              d.endDateLabel,
            ),
            deleting: _deleting.contains(d.id),
            onDelete: () => _delete(id: d.id, name: d.name, isCode: false),
          )
      else
        for (final c in state.promoCodes)
          _Ticket(
            key: ValueKey('c-${c.id}'),
            stubValue: _valueLabel(c.type, c.value),
            stubCaption: c.type == PromotionType.percentage
                ? 'off'
                : 'flat off',
            title: c.code,
            code: c.code,
            description: c.description,
            schedule: _Schedule.of(
              c.isActive,
              c.startDateLabel,
              c.endDateLabel,
            ),
            usedCount: c.usedCount,
            maxUses: c.maxUses,
            deleting: _deleting.contains(c.id),
            onDelete: () => _delete(id: c.id, name: c.code, isCode: true),
          ),
    ];
    if (tickets.isEmpty) {
      return AtelierEmptyState(
        icon: isDiscounts
            ? Icons.percent_rounded
            : Icons.confirmation_number_outlined,
        title: isDiscounts ? 'No discounts running' : 'No promo codes yet',
        message: isDiscounts
            ? context.tr(RemainingL10n.noDiscountsFound)
            : context.tr(RemainingL10n.noPromoCodesFound),
        actionLabel: isDiscounts
            ? context.tr(RemainingL10n.addDiscount)
            : context.tr(RemainingL10n.addPromoCode),
        onAction: () => _create(isDiscounts ? _Kind.discount : _Kind.code),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 880 ? 2 : 1;
        const gap = AtelierSpace.s16;
        final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < tickets.length; i++)
              SizedBox(
                width: w,
                child: Reveal(index: i < 8 ? i : 0, child: tickets[i]),
              ),
          ],
        );
      },
    );
  }
}

String _valueLabel(PromotionType type, String raw) {
  final n = num.tryParse(raw);
  final clean = n == null
      ? raw
      : (n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toString());
  return type == PromotionType.percentage ? '$clean%' : '\$$clean';
}

enum _Phase { scheduled, live, ended, paused }

class _Schedule {
  const _Schedule({
    required this.phase,
    required this.rangeLabel,
    this.progress,
    this.note,
  });

  final _Phase phase;
  final String rangeLabel;
  final double? progress;
  final String? note;

  static _Schedule of(bool isActive, String startLabel, String endLabel) {
    final start = atelierParseDateLabel(startLabel);
    final end = atelierParseDateLabel(endLabel);
    final range = start != null && end != null
        ? '${atelierDate(start)} → ${atelierDate(end)}'
        : '$startLabel → $endLabel';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (start == null || end == null) {
      return _Schedule(
        phase: isActive ? _Phase.live : _Phase.paused,
        rangeLabel: range,
      );
    }
    final endOfDay = end.add(const Duration(days: 1));
    if (!isActive) {
      return _Schedule(phase: _Phase.paused, rangeLabel: range);
    }
    if (today.isBefore(start)) {
      final days = start.difference(today).inDays;
      return _Schedule(
        phase: _Phase.scheduled,
        rangeLabel: range,
        progress: 0,
        note: 'Starts in $days day${days == 1 ? '' : 's'}',
      );
    }
    if (!now.isBefore(endOfDay)) {
      return _Schedule(
        phase: _Phase.ended,
        rangeLabel: range,
        progress: 1,
        note: 'Ended',
      );
    }
    final total = endOfDay.difference(start).inMinutes;
    final done = now.difference(start).inMinutes;
    final left = endOfDay.difference(now);
    return _Schedule(
      phase: _Phase.live,
      rangeLabel: range,
      progress: total <= 0 ? 1 : done / total,
      note: left.inDays >= 1
          ? '${left.inDays} day${left.inDays == 1 ? '' : 's'} left'
          : 'Ends today',
    );
  }

  (String, AtelierTone) get pill => switch (phase) {
    _Phase.live => ('Live', AtelierTone.emerald),
    _Phase.scheduled => ('Scheduled', AtelierTone.sapphire),
    _Phase.ended => ('Ended', AtelierTone.neutral),
    _Phase.paused => ('Inactive', AtelierTone.amber),
  };
}

/// Coupon-shaped card: value stub, perforation, details and actions.
class _Ticket extends StatelessWidget {
  const _Ticket({
    required this.stubValue,
    required this.stubCaption,
    required this.title,
    required this.description,
    required this.schedule,
    required this.deleting,
    required this.onDelete,
    this.code,
    this.usedCount,
    this.maxUses,
    super.key,
  });

  final String stubValue;
  final String stubCaption;
  final String title;
  final String description;
  final _Schedule schedule;
  final bool deleting;
  final VoidCallback onDelete;
  final String? code;
  final int? usedCount;
  final int? maxUses;

  static const _stub = 104.0;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final (pillLabel, pillTone) = schedule.pill;
    final dim =
        schedule.phase == _Phase.ended || schedule.phase == _Phase.paused;
    return AnimatedOpacity(
      duration: AtelierMotion.base,
      opacity: deleting ? 0.45 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AtelierRadius.lg),
          boxShadow: p.softShadow,
        ),
        child: ClipPath(
          clipper: const _TicketClipper(stub: _stub),
          child: Container(
            decoration: BoxDecoration(color: p.surface),
            foregroundDecoration: _TicketBorder(stub: _stub, color: p.hairline),
            // A Stack, not IntrinsicHeight: the details hold LayoutBuilders.
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _stub,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: dim
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                p.goldSoft,
                                p.goldSoft.withValues(alpha: 0.4),
                              ],
                            ),
                      color: dim ? p.sunken : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            stubValue,
                            style: AtelierType.display(
                              dim ? p.muted : p.gold,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stubCaption.toUpperCase(),
                          style: AtelierType.overline(
                            dim ? p.muted : p.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: _stub,
                  top: 0,
                  bottom: 0,
                  width: 1,
                  child: CustomPaint(painter: _DashPainter(color: p.hairline)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(_stub + 17, 14, 8, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: AtelierPill(
                              label: pillLabel,
                              tone: pillTone,
                              dense: true,
                            ),
                          ),
                          const Spacer(),
                          AtelierIconButton(
                            icon: Icons.delete_outline_rounded,
                            tooltip: context.tr(RemainingL10n.delete),
                            size: 34,
                            onPressed: deleting ? null : onDelete,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (code != null)
                        _CodeChip(code: code!)
                      else
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.display(p.ink, size: 20),
                        ),
                      if (description.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.caption(p.inkSoft, size: 12),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.event_outlined, size: 13, color: p.muted),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              schedule.rangeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AtelierType.caption(p.muted, size: 11),
                            ),
                          ),
                          if (schedule.note != null)
                            Text(
                              schedule.note!,
                              style: AtelierType.label(p.inkSoft, size: 11),
                            ),
                        ],
                      ),
                      if (schedule.progress != null) ...[
                        const SizedBox(height: 6),
                        AtelierMeter(
                          value: schedule.progress!,
                          height: 4,
                          color: dim ? p.muted : null,
                        ),
                      ],
                      if (code != null) ...[
                        const SizedBox(height: 10),
                        _Usage(used: usedCount ?? 0, max: maxUses),
                      ],
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

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Pressable(
      onTap: () async {
        await atelierCopy(code);
        if (context.mounted) showAtelierToast(context, '$code copied');
      },
      semanticLabel: 'Copy code $code',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              code.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtelierType.title(
                p.ink,
                size: 18,
              ).copyWith(letterSpacing: 2.6),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.copy_rounded, size: 15, color: p.gold),
        ],
      ),
    );
  }
}

class _Usage extends StatelessWidget {
  const _Usage({required this.used, required this.max});

  final int used;
  final int? max;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final limited = max != null && max! > 0;
    return Row(
      children: [
        AtelierRing(
          value: limited ? used / max! : 0,
          size: 28,
          stroke: 3,
          color: limited && used >= max! ? p.ruby : p.gold,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            limited
                ? '$used of $max redeemed · ${(max! - used).clamp(0, max!)} left'
                : '$used redeemed · unlimited uses',
            style: AtelierType.caption(p.inkSoft, size: 11.5),
          ),
        ),
      ],
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper({required this.stub});

  final double stub;

  @override
  Path getClip(Size size) => _ticketPath(size, stub);

  @override
  bool shouldReclip(_TicketClipper old) => old.stub != stub;
}

Path _ticketPath(Size size, double stub) {
  const r = AtelierRadius.lg;
  const notch = 9.0;
  final path = Path()
    ..addRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(r)),
    );
  final notches = Path()
    ..addOval(Rect.fromCircle(center: Offset(stub, 0), radius: notch))
    ..addOval(
      Rect.fromCircle(center: Offset(stub, size.height), radius: notch),
    );
  return Path.combine(PathOperation.difference, path, notches);
}

class _TicketBorder extends Decoration {
  const _TicketBorder({required this.stub, required this.color});

  final double stub;
  final Color color;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _TicketBorderPainter(stub, color);
}

class _TicketBorderPainter extends BoxPainter {
  _TicketBorderPainter(this.stub, this.color);

  final double stub;
  final Color color;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.drawPath(
      _ticketPath(size, stub),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color,
    );
    canvas.restore();
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    for (var y = 14.0; y < size.height - 14; y += 7) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 3.5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// Create form for a discount or promo code with a live ticket preview.
class _PromotionForm extends ConsumerStatefulWidget {
  const _PromotionForm({required this.kind});

  final _Kind kind;

  @override
  ConsumerState<_PromotionForm> createState() => _PromotionFormState();
}

class _PromotionFormState extends ConsumerState<_PromotionForm> {
  late final _name = TextEditingController();
  final _desc = TextEditingController();
  late final _value = TextEditingController(
    text: widget.kind == _Kind.discount ? '10' : '20',
  );
  final _maxUses = TextEditingController(text: '100');
  PromotionType _type = PromotionType.percentage;
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;
  bool _submitted = false;
  String? _serverError;

  bool get _isCode => widget.kind == _Kind.code;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _value.dispose();
    _maxUses.dispose();
    super.dispose();
  }

  String? get _nameError {
    if (!_submitted) return null;
    if (_name.text.trim().isEmpty) {
      return _isCode ? 'Enter a code.' : 'Give the discount a name.';
    }
    return null;
  }

  String? get _valueError {
    if (!_submitted) return null;
    final v = num.tryParse(_value.text.trim());
    if (v == null || v <= 0) return 'Enter a value above zero.';
    if (_type == PromotionType.percentage && v > 100) {
      return 'A percentage can’t exceed 100.';
    }
    return null;
  }

  String? get _dateError {
    if (!_submitted) return null;
    if (_start == null || _end == null) return 'Choose a start and end date.';
    if (_end!.isBefore(_start!)) return 'End date must be after the start.';
    return null;
  }

  String? get _maxUsesError {
    if (!_submitted || !_isCode) return null;
    final t = _maxUses.text.trim();
    if (t.isEmpty) return null;
    final v = int.tryParse(t);
    if (v == null || v <= 0) return 'Use a whole number, or leave it empty.';
    return null;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? _start : _end) ?? _start ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) _end = null;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    if (_nameError != null ||
        _valueError != null ||
        _dateError != null ||
        _maxUsesError != null) {
      AppHaptics.error();
      return;
    }
    setState(() => _saving = true);
    final notifier = ref.read(sellerPromotionsProvider.notifier);
    final value = num.tryParse(_value.text.trim()) ?? 0;
    final Result<Object, Failure> result = _isCode
        ? await notifier.createPromoCode(
            PromoCodeInput(
              code: _name.text.trim(),
              description: _desc.text.trim(),
              type: _type,
              value: value,
              startDate: _start!,
              endDate: _end!,
              maxUses: int.tryParse(_maxUses.text.trim()),
            ),
          )
        : await notifier.createDiscount(
            DiscountInput(
              name: _name.text.trim(),
              description: _desc.text.trim(),
              type: _type,
              value: value,
              startDate: _start!,
              endDate: _end!,
            ),
          );
    if (!mounted) return;
    switch (result) {
      case Success():
        AppHaptics.success();
        final messenger = ScaffoldMessenger.maybeOf(context);
        final p = context.atelier;
        final message = _isCode
            ? context.tr(RemainingL10n.promoCodeCreated)
            : context.tr(RemainingL10n.discountCreated);
        Navigator.of(context).pop();
        if (messenger != null) {
          showAtelierToastOn(messenger, p, message, tone: AtelierTone.emerald);
        }
      case ResultFailure(:final failure):
        AppHaptics.error();
        setState(() {
          _saving = false;
          _serverError = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _Ticket(
      stubValue: _valueLabel(
        _type,
        _value.text.trim().isEmpty ? '0' : _value.text.trim(),
      ),
      stubCaption: _type == PromotionType.percentage ? 'off' : 'flat off',
      title: _name.text.trim().isEmpty
          ? (_isCode ? 'CODE' : 'Your discount')
          : _name.text.trim(),
      code: _isCode
          ? (_name.text.trim().isEmpty ? 'CODE' : _name.text.trim())
          : null,
      description: _desc.text,
      schedule: _start != null && _end != null
          ? _Schedule.of(
              true,
              '${_start!.month}/${_start!.day}/${_start!.year}',
              '${_end!.month}/${_end!.day}/${_end!.year}',
            )
          : const _Schedule(phase: _Phase.scheduled, rangeLabel: 'Set dates'),
      maxUses: int.tryParse(_maxUses.text.trim()),
      usedCount: 0,
      deleting: false,
      onDelete: () {},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IgnorePointer(child: preview),
        const SizedBox(height: 24),
        AtelierTextField(
          controller: _name,
          label: _isCode
              ? context.tr(RemainingL10n.promoCode)
              : context.tr(RemainingL10n.discountName),
          hint: _isCode ? 'e.g., SUMMER20' : 'e.g., Summer Sale',
          mono: _isCode,
          textCapitalization: _isCode
              ? TextCapitalization.characters
              : TextCapitalization.words,
          inputFormatters: _isCode
              ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
              : null,
          error: _nameError,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AtelierTextField(
          controller: _desc,
          label: context.tr(RemainingL10n.description),
          hint: 'What buyers should know',
          maxLines: 2,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr(RemainingL10n.discountType).toUpperCase(),
          style: AtelierType.overline(context.atelier.muted),
        ),
        const SizedBox(height: 8),
        AtelierSegmented<PromotionType>(
          expand: true,
          dense: true,
          segments: [
            AtelierSegment(
              value: PromotionType.percentage,
              label: context.tr(RemainingL10n.percentage),
              icon: Icons.percent_rounded,
            ),
            AtelierSegment(
              value: PromotionType.fixedAmount,
              label: context.tr(RemainingL10n.fixedAmount),
              icon: Icons.attach_money_rounded,
            ),
          ],
          selected: _type,
          onChanged: (t) => setState(() => _type = t),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AtelierTextField(
                controller: _value,
                label: context.tr(RemainingL10n.value),
                hint: '10',
                prefixText: _type == PromotionType.fixedAmount ? '\$' : null,
                suffixText: _type == PromotionType.percentage ? '%' : null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                error: _valueError,
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (_isCode) ...[
              const SizedBox(width: 12),
              Expanded(
                child: AtelierTextField(
                  controller: _maxUses,
                  label: context.tr(RemainingL10n.maxUsesOptional),
                  hint: '100',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  error: _maxUsesError,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AtelierDateTile(
                label: context.tr(RemainingL10n.startDate2),
                value: _start == null ? null : atelierDate(_start!),
                error: _dateError != null && _start == null,
                onTap: () => _pickDate(isStart: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AtelierDateTile(
                label: context.tr(RemainingL10n.endDate2),
                value: _end == null ? null : atelierDate(_end!),
                icon: Icons.event_available_rounded,
                error:
                    _dateError != null &&
                    (_end == null ||
                        (_start != null && _end!.isBefore(_start!))),
                onTap: () => _pickDate(isStart: false),
              ),
            ),
          ],
        ),
        AtelierFieldError(error: _dateError),
        AnimatedSize(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          child: _serverError == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: AtelierNotice(
                    text: _serverError!,
                    tone: AtelierTone.ruby,
                    icon: Icons.error_outline_rounded,
                  ),
                ),
        ),
        const SizedBox(height: 24),
        AtelierButton(
          label: _isCode
              ? context.tr(RemainingL10n.savePromoCode)
              : context.tr(RemainingL10n.saveDiscount),
          icon: Icons.check_rounded,
          variant: AtelierButtonVariant.gold,
          expand: true,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
