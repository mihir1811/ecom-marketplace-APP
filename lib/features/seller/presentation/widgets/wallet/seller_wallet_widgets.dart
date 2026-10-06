import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/result.dart';
import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/app_currency.dart';
import '../../../../wallet/application/wallet_top_up_provider.dart';
import '../../../../wallet/domain/models/wallet.dart';
import '../../atelier/atelier_components.dart';
import '../../atelier/atelier_feedback.dart';
import '../../atelier/atelier_motion.dart';
import '../../atelier/atelier_theme.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String walletDayLabel(DateTime? date) {
  if (date == null) return 'Undated';
  final d = date.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

String walletTime(DateTime? date) {
  if (date == null) return '';
  final d = date.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.hour)}:${two(d.minute)}';
}

/// Onyx balance card that tilts under the finger, with a slow gold sheen.
class WalletBalanceHero extends StatelessWidget {
  const WalletBalanceHero({required this.wallet, super.key});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final soft = p.onOnyx.withValues(alpha: 0.6);
    final id = wallet.id.replaceAll('-', '');
    final tail = id.length >= 4 ? id.substring(id.length - 4) : id;

    Widget card = AspectRatio(
      aspectRatio: 1.62,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AtelierRadius.xl),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF221E17), Color(0xFF0F0D0A)],
          ),
          border: Border.all(color: p.gold.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: p.isDark ? 0.6 : 0.28),
              blurRadius: 36,
              spreadRadius: -16,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GuillochePainter(
                  color: p.gold.withValues(alpha: 0.1),
                ),
              ),
            ),
            const Positioned.fill(child: AtelierAmbient(intensity: 0.9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('GEMWORLD', style: AtelierType.overline(p.gold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AtelierRadius.pill,
                          ),
                          border: Border.all(
                            color: p.gold.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          wallet.currency,
                          style: AtelierType.label(p.gold, size: 11),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    context.tr(RemainingL10n.availableBalance).toUpperCase(),
                    style: AtelierType.overline(soft),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: CountUpText(
                      AppCurrency.inr(wallet.balance),
                      duration: const Duration(milliseconds: 1500),
                      style: AtelierType.display(
                        p.onOnyx,
                        size: 46,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _ChipGlyph(color: p.gold),
                      const SizedBox(width: 12),
                      Text(
                        '••••  ${tail.toUpperCase()}',
                        style: AtelierType.figure(soft, size: 13),
                      ),
                      const Spacer(),
                      Text(
                        'Seller wallet',
                        style: AtelierType.caption(soft, size: 11.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!context.reduceMotion) {
      card = card
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            delay: 3200.ms,
            duration: 1800.ms,
            angle: 0.5,
            color: p.gold.withValues(alpha: 0.18),
          );
    }

    return Semantics(
      label: context.tr(RemainingL10n.walletBalanceAmount, {
        'amount': AppCurrency.inr(wallet.balance),
      }),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: TiltSurface(child: card),
      ),
    );
  }
}

class _ChipGlyph extends StatelessWidget {
  const _ChipGlyph({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.5)],
        ),
      ),
      child: CustomPaint(painter: _ChipLinesPainter()),
    );
  }
}

class _ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ChipLinesPainter old) => false;
}

/// Banknote-style rosette engraving.
class _GuillochePainter extends CustomPainter {
  _GuillochePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    final center = Offset(size.width * 0.86, size.height * 0.2);
    for (var k = 0; k < 18; k++) {
      final path = Path();
      final r = 40.0 + k * 9;
      for (var i = 0; i <= 180; i++) {
        final t = i / 180 * 2 * math.pi;
        final wobble = 1 + 0.06 * math.sin(12 * t + k * 0.5);
        final pt = center + Offset(math.cos(t), math.sin(t)) * r * wobble;
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_GuillochePainter old) => old.color != color;
}

/// Money in / out across the transactions loaded so far.
class WalletFlowSummary extends StatelessWidget {
  const WalletFlowSummary({required this.transactions, super.key});

  final List<WalletTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    var inflow = 0.0, outflow = 0.0;
    for (final t in transactions) {
      if (t.isCredit) {
        inflow += t.amount.abs();
      } else {
        outflow += t.amount.abs();
      }
    }
    final total = inflow + outflow;
    final inShare = total == 0 ? 0.5 : inflow / total;

    return AtelierCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Flow(
                  label: 'Money in',
                  value: AppCurrency.inr(inflow),
                  color: p.emerald,
                  icon: Icons.south_west_rounded,
                ),
              ),
              Container(width: 1, height: 44, color: p.hairline),
              const SizedBox(width: 16),
              Expanded(
                child: _Flow(
                  label: 'Money out',
                  value: AppCurrency.inr(outflow),
                  color: p.ruby,
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: inShare),
                duration: AtelierMotion.lazy,
                curve: AtelierMotion.emphasized,
                builder: (context, share, _) => Row(
                  children: [
                    Expanded(
                      flex: (share * 1000).round().clamp(1, 999),
                      child: Container(color: p.emerald),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: ((1 - share) * 1000).round().clamp(1, 999),
                      child: Container(color: p.ruby.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            transactions.isEmpty
                ? 'No activity yet'
                : 'Across your ${transactions.length} most recent transactions',
            style: AtelierType.caption(p.muted, size: 11.5),
          ),
        ],
      ),
    );
  }
}

class _Flow extends StatelessWidget {
  const _Flow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: AtelierType.caption(p.muted)),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: CountUpText(
            value,
            style: AtelierType.display(p.ink, size: 26),
          ),
        ),
      ],
    );
  }
}

/// One ledger row.
class WalletLedgerRow extends StatelessWidget {
  const WalletLedgerRow({
    required this.transaction,
    required this.onTap,
    super.key,
  });

  final WalletTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final credit = transaction.isCredit;
    final accent = credit ? p.emerald : p.ruby;
    final sign = credit ? '+' : '−';
    final subtitle = [
      if (walletTime(transaction.createdAt).isNotEmpty)
        walletTime(transaction.createdAt),
      ?transaction.note,
    ].join('  ·  ');

    return Pressable(
      onTap: onTap,
      semanticLabel:
          '${transaction.typeLabel}, $sign${AppCurrency.inr(transaction.amount.abs())}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.md),
          border: Border.all(color: p.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: p.isDark ? 0.14 : 0.08),
              ),
              child: Icon(
                credit ? Icons.south_west_rounded : Icons.north_east_rounded,
                size: 18,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.typeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.label(p.ink, size: 14),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.caption(p.muted, size: 11.5),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${AppCurrency.inr(transaction.amount.abs())}',
                  style: AtelierType.figure(
                    credit ? p.emerald : p.ink,
                    size: 14.5,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr(RemainingL10n.balanceAfterAmount, {
                    'amount': AppCurrency.inr(transaction.balanceAfter),
                  }),
                  style: AtelierType.caption(p.muted, size: 10.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full detail of a ledger entry with copyable references.
Future<void> showWalletTransactionSheet(
  BuildContext context,
  WalletTransaction t,
) {
  return showAtelierSheet<void>(
    context: context,
    title: t.typeLabel,
    subtitle: [
      walletDayLabel(t.createdAt),
      walletTime(t.createdAt),
    ].where((e) => e.isNotEmpty).join(' · '),
    builder: (sheetContext) {
      final p = sheetContext.atelier;
      final credit = t.isCredit;
      final refs = <(String, String)>[
        ('Transaction ID', t.id),
        if (t.orderId != null && t.orderId!.isNotEmpty)
          ('Order ID', t.orderId!),
        if (t.razorpayOrderId != null && t.razorpayOrderId!.isNotEmpty)
          ('Razorpay order', t.razorpayOrderId!),
        if (t.razorpayPaymentId != null && t.razorpayPaymentId!.isNotEmpty)
          ('Razorpay payment', t.razorpayPaymentId!),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${credit ? '+' : '−'}${AppCurrency.inr(t.amount.abs())}',
            style: AtelierType.display(credit ? p.emerald : p.ink, size: 40),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              AtelierPill(
                label: credit ? 'Credit' : 'Debit',
                tone: credit ? AtelierTone.emerald : AtelierTone.ruby,
                dense: true,
              ),
              const SizedBox(width: 8),
              Text(
                sheetContext.tr(RemainingL10n.balanceAfterAmount, {
                  'amount': AppCurrency.inr(t.balanceAfter),
                }),
                style: AtelierType.caption(p.muted),
              ),
            ],
          ),
          if (t.note != null && t.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            AtelierKeyValue(label: 'Note', value: t.note!),
          ],
          const SizedBox(height: 20),
          for (final (label, value) in refs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                decoration: BoxDecoration(
                  color: p.sunken,
                  borderRadius: BorderRadius.circular(AtelierRadius.sm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AtelierKeyValue(
                        label: label,
                        value: value,
                        valueWidget: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.figure(p.ink, size: 12.5),
                        ),
                      ),
                    ),
                    AtelierIconButton(
                      icon: Icons.copy_rounded,
                      tooltip: 'Copy $label',
                      size: 34,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: value));
                        if (!sheetContext.mounted) return;
                        AppHaptics.selection();
                        showAtelierToast(sheetContext, '$label copied');
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

const _presets = <double>[500, 1000, 2000, 5000];

/// Amount form that starts Razorpay wallet top-up, with live phase feedback.
class SellerTopUpSheet extends ConsumerStatefulWidget {
  const SellerTopUpSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showAtelierSheet<void>(
      context: context,
      title: context.tr(RemainingL10n.topUpWallet),
      subtitle: context.tr(RemainingL10n.topUpMinimum),
      builder: (_) => const SellerTopUpSheet(),
    );
  }

  @override
  ConsumerState<SellerTopUpSheet> createState() => _SellerTopUpSheetState();
}

class _SellerTopUpSheetState extends ConsumerState<SellerTopUpSheet> {
  final _controller = TextEditingController();
  String? _fieldError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _parsedAmount {
    final raw = _controller.text.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final amount = _parsedAmount;
    if (amount == null) {
      AppHaptics.error();
      setState(() => _fieldError = context.tr(RemainingL10n.enterAmountInr));
      return;
    }
    final invalid = ref
        .read(walletTopUpProvider.notifier)
        .validateAmount(amount);
    if (invalid != null) {
      AppHaptics.error();
      setState(() => _fieldError = invalid.message);
      return;
    }
    setState(() => _fieldError = null);

    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final successText = context.tr(RemainingL10n.walletTopUpSuccess);
    final result = await ref.read(walletTopUpProvider.notifier).topUp(amount);
    if (!mounted) return;
    switch (result) {
      case Success():
        AppHaptics.success();
        Navigator.of(context).maybePop();
        showAtelierToastOn(
          messenger,
          palette,
          successText,
          tone: AtelierTone.emerald,
        );
      case ResultFailure(:final failure):
        AppHaptics.error();
        setState(() => _fieldError = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final topUp = ref.watch(walletTopUpProvider);
    final busy = topUp.isBusy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: p.sunken,
            borderRadius: BorderRadius.circular(AtelierRadius.lg),
            border: Border.all(
              color: _fieldError != null
                  ? p.ruby.withValues(alpha: 0.6)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('₹', style: AtelierType.display(p.gold, size: 40)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !busy,
                  autofocus: true,
                  cursorColor: p.gold,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) {
                    if (_fieldError != null) setState(() => _fieldError = null);
                  },
                  onSubmitted: (_) => busy ? null : _submit(),
                  style: AtelierType.display(p.ink, size: 40),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: '0',
                    hintStyle: AtelierType.display(p.muted, size: 40),
                    semanticCounterText: context.tr(RemainingL10n.amountInr),
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          child: _fieldError == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    _fieldError!,
                    style: AtelierType.caption(p.ruby, size: 12),
                  ),
                ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _presets)
              AtelierChoiceChip(
                label: '₹${preset.toStringAsFixed(0)}',
                selected: _parsedAmount == preset,
                onTap: busy
                    ? () {}
                    : () {
                        _controller.text = preset.toStringAsFixed(0);
                        setState(() => _fieldError = null);
                      },
              ),
          ],
        ),
        AnimatedSize(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          child: busy
              ? Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _TopUpProgress(phase: topUp.phase),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 22),
        AtelierButton(
          label: context.tr(RemainingL10n.continuePayment),
          icon: Icons.lock_outline_rounded,
          variant: AtelierButtonVariant.gold,
          loading: busy,
          expand: true,
          onPressed: busy ? null : _submit,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 13, color: p.muted),
            const SizedBox(width: 6),
            Text(
              'Secured by Razorpay',
              style: AtelierType.caption(p.muted, size: 11.5),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopUpProgress extends StatelessWidget {
  const _TopUpProgress({required this.phase});

  final WalletTopUpPhase phase;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    const steps = [
      (WalletTopUpPhase.creating, 'Preparing'),
      (WalletTopUpPhase.awaitingPayment, 'Payment'),
      (WalletTopUpPhase.verifying, 'Verifying'),
    ];
    final current = steps.indexWhere((s) => s.$1 == phase);
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: AnimatedContainer(
                duration: AtelierMotion.slow,
                height: 1.5,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: i <= current ? p.gold : p.hairline,
              ),
            ),
          Column(
            children: [
              AnimatedContainer(
                duration: AtelierMotion.slow,
                curve: AtelierMotion.settle,
                width: i == current ? 26 : 20,
                height: i == current ? 26 : 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < current
                      ? p.gold
                      : i == current
                      ? p.goldSoft
                      : p.sunken,
                  border: Border.all(color: i <= current ? p.gold : p.hairline),
                ),
                child: i < current
                    ? Icon(Icons.check_rounded, size: 13, color: p.onGold)
                    : i == current
                    ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: p.gold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                steps[i].$2,
                style: AtelierType.caption(
                  i <= current ? p.ink : p.muted,
                  size: 11,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
