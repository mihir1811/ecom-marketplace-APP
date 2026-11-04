import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../domain/models/product_offer.dart';

/// Amount (decimal string, two places) and optional note for a counter-offer.
typedef OfferCounterInput = ({String amount, String? message});

/// Counter-offer form in an Atelier sheet.
///
/// Seller: [above] = the buyer's offer, [atMost] = the listed price.
/// Buyer: [below] = the seller's price.
Future<OfferCounterInput?> showOfferCounterSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  double? above,
  double? below,
  double? atMost,
  String? note,
  String submitLabel = 'Send counter-offer',
}) {
  return showAtelierSheet<OfferCounterInput>(
    context: context,
    title: title,
    subtitle: subtitle,
    builder: (_) => _CounterForm(
      above: above,
      below: below,
      atMost: atMost,
      note: note,
      submitLabel: submitLabel,
    ),
  );
}

class _CounterForm extends StatefulWidget {
  const _CounterForm({
    required this.submitLabel,
    this.above,
    this.below,
    this.atMost,
    this.note,
  });

  final double? above;
  final double? below;
  final double? atMost;
  final String? note;
  final String submitLabel;

  @override
  State<_CounterForm> createState() => _CounterFormState();
}

class _CounterFormState extends State<_CounterForm> {
  final _amount = TextEditingController();
  final _message = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  /// Same rules as the backend, so the user rarely sees a 400.
  String? _validate(double? value) {
    if (value == null || value <= 0) {
      return 'Counter-offer amount must be greater than zero';
    }
    final above = widget.above;
    if (above != null && value <= above) {
      return 'Your counter-offer must be more than the buyer’s offer of '
          '${atelierMoney(above, decimals: 2)}. To sell at that price, '
          'accept the offer.';
    }
    final below = widget.below;
    if (below != null && value >= below) {
      return 'Your counter-offer must be less than the seller’s price of '
          '${atelierMoney(below, decimals: 2)}. To buy at that price, '
          'accept the counter-offer.';
    }
    final max = widget.atMost;
    if (max != null && value > max) {
      return 'Counter-offer can’t be more than the listed price of '
          '${atelierMoney(max, decimals: 2)}';
    }
    return null;
  }

  void _submit() {
    final value = double.tryParse(_amount.text.trim());
    final error = _validate(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final message = _message.text.trim();
    Navigator.of(context).pop((
      amount: value!.toStringAsFixed(2),
      message: message.isEmpty ? null : message,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtelierTextField(
          controller: _amount,
          label: 'Your price (USD)',
          prefixText: '\$ ',
          autofocus: true,
          error: _error,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 10),
        AtelierTextField(
          controller: _message,
          label: 'Message (optional)',
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        if (widget.note != null) ...[
          const SizedBox(height: 8),
          Text(widget.note!, style: AtelierType.caption(p.muted, size: 12)),
        ],
        const SizedBox(height: 14),
        AtelierButton(
          label: widget.submitLabel,
          icon: Icons.swap_horiz_rounded,
          variant: AtelierButtonVariant.gold,
          expand: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// The negotiation so far, oldest first, e.g. "Buyer $800 → You $950".
/// [asSeller] picks who "You" is.
class OfferExchangeLine extends StatelessWidget {
  const OfferExchangeLine({
    required this.offer,
    required this.asSeller,
    super.key,
  });

  final ProductOffer offer;
  final bool asSeller;

  @override
  Widget build(BuildContext context) {
    if (offer.history.isEmpty) return const SizedBox.shrink();
    final p = context.atelier;
    String who(bool fromSeller) =>
        fromSeller == asSeller ? 'You' : (fromSeller ? 'Seller' : 'Buyer');
    final moves = [
      for (final m in offer.history)
        '${who(m.fromSeller)} ${atelierMoney(m.amount, decimals: 2)}',
      '${who(offer.fromSeller)} ${atelierMoney(offer.amount, decimals: 2)}',
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.swap_horiz_rounded, size: 15, color: p.gold),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            moves.join('  →  '),
            style: AtelierType.caption(p.inkSoft, size: 12),
          ),
        ),
      ],
    );
  }
}

/// "N of M attempts left" for a negotiation row, or null when unknown.
String? offerAttemptsCaption(ProductOffer offer) {
  final used = offer.attemptsUsed;
  final max = offer.maxAttempts;
  if (used == null || max == null) return null;
  final left = (max - used).clamp(0, max);
  return left == 0
      ? 'No attempts left on this stone (counter-offers count too)'
      : '$left of $max attempts left (counter-offers count too)';
}
