import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../data/repositories/interested_buyers_repository.dart';
import '../../domain/models/interested_buyer.dart';

/// What a contact sheet ended with; null when the seller closed it.
sealed class ContactOutcome {
  const ContactOutcome();
}

class ContactSent extends ContactOutcome {
  const ContactSent();
}

/// Failed in a way that changes the row (404, limit, reserved…): the sheet
/// closed so the list can reload.
class ContactFailed extends ContactOutcome {
  const ContactFailed(this.failure);
  final Failure failure;
}

const int interestedMessageMax = 1000;
const int interestedOfferNoteMax = 500;

/// Suggested opening line for a cart message.
String interestedMessageDraft(InterestedBuyer row) =>
    'Hi ${row.buyerName}, I saw ${row.product.displayTitle} in your cart. '
    'Can I help with anything?';

Future<ContactOutcome?> showInterestedMessageSheet(
  BuildContext context, {
  required InterestedBuyer row,
}) {
  return showAtelierSheet<ContactOutcome>(
    context: context,
    title: 'Message ${row.buyerName}',
    subtitle: row.product.displayTitle,
    builder: (_) => _MessageForm(row: row),
  );
}

Future<ContactOutcome?> showInterestedOfferSheet(
  BuildContext context, {
  required InterestedBuyer row,
}) {
  return showAtelierSheet<ContactOutcome>(
    context: context,
    title: 'Private offer for ${row.buyerName}',
    subtitle:
        '${row.product.displayTitle} · in cart at '
        '${atelierMoney(row.lineTotal, decimals: 2)}',
    builder: (_) => _OfferForm(row: row),
  );
}

/// Characters used / allowed, under a text area.
class _Counter extends StatelessWidget {
  const _Counter({required this.controller, required this.max});

  final TextEditingController controller;
  final int max;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Text(
        '${controller.text.trim().length} / $max',
        textAlign: TextAlign.end,
        style: AtelierType.caption(p.muted, size: 11),
      ),
    );
  }
}

class _MessageForm extends ConsumerStatefulWidget {
  const _MessageForm({required this.row});

  final InterestedBuyer row;

  @override
  ConsumerState<_MessageForm> createState() => _MessageFormState();
}

class _MessageFormState extends ConsumerState<_MessageForm> {
  late final _text = TextEditingController(
    text: interestedMessageDraft(widget.row),
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _text.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'Write a message first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(interestedBuyersRepositoryProvider)
        .sendMessage(cartId: widget.row.id, message: message);
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop(const ContactSent());
      case ResultFailure(:final failure):
        // Field errors (empty, too long) stay here to fix; anything else
        // means the row changed.
        if (failure is ValidationFailure && _isFieldError(failure.message)) {
          setState(() {
            _busy = false;
            _error = failure.message;
          });
          return;
        }
        Navigator.of(context).pop(ContactFailed(failure));
    }
  }

  static bool _isFieldError(String message) {
    final m = message.toLowerCase();
    return m.contains('message must') ||
        m.contains('message should') ||
        m.contains('characters');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtelierTextField(
          controller: _text,
          label: 'Message',
          minLines: 4,
          maxLines: 8,
          autofocus: true,
          error: _error,
          enabled: !_busy,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [
            LengthLimitingTextInputFormatter(interestedMessageMax),
          ],
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 4),
        _Counter(controller: _text, max: interestedMessageMax),
        const SizedBox(height: 6),
        Text(
          'It arrives as a chat message about this item. This uses your one '
          'contact with this buyer for 7 days, or until they reply.',
          style: AtelierType.caption(p.muted, size: 12),
        ),
        const SizedBox(height: 14),
        AtelierButton(
          label: 'Send message',
          icon: Icons.send_rounded,
          variant: AtelierButtonVariant.gold,
          expand: true,
          loading: _busy,
          onPressed: _busy ? null : _send,
        ),
      ],
    );
  }
}

class _OfferForm extends ConsumerStatefulWidget {
  const _OfferForm({required this.row});

  final InterestedBuyer row;

  @override
  ConsumerState<_OfferForm> createState() => _OfferFormState();
}

class _OfferFormState extends ConsumerState<_OfferForm> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  int? _percent;
  bool _busy = false;
  String? _error;

  static const _quick = [3, 5, 10];

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _usePercent(int percent) {
    final price = widget.row.lineTotal * (100 - percent) / 100;
    final text = price.toStringAsFixed(2);
    setState(() {
      _percent = percent;
      _error = null;
    });
    _amount
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
  }

  String? _validate(num? value) {
    if (value == null || value <= 0) {
      return 'Offer amount must be greater than zero';
    }
    final minimum = widget.row.product.minimumOfferPrice;
    if (minimum != null && value < minimum) {
      return 'Your private offer is below this product’s minimum offer '
          'price of ${atelierMoney(minimum, decimals: 2)}';
    }
    return null;
  }

  Future<void> _send() async {
    final value = num.tryParse(_amount.text.trim());
    final invalid = _validate(value);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(interestedBuyersRepositoryProvider)
        .sendOffer(
          cartId: widget.row.id,
          amount: value!.toStringAsFixed(2),
          message: _note.text,
        );
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop(const ContactSent());
      case ResultFailure(:final failure):
        // Price rules keep the dialog open to try another price.
        if (failure is ValidationFailure && _isPriceError(failure.message)) {
          setState(() {
            _busy = false;
            _error = failure.message;
          });
          return;
        }
        Navigator.of(context).pop(ContactFailed(failure));
    }
  }

  static bool _isPriceError(String message) {
    final m = message.toLowerCase();
    return m.contains('less than the listed price') ||
        m.contains('minimum offer price') ||
        m.contains('greater than zero') ||
        m.contains('decimal') ||
        m.contains('amount') ||
        (m.contains('message') && m.contains('characters'));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final row = widget.row;
    final minimum = row.product.minimumOfferPrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (row.lineTotal > 0) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final pct in _quick)
                AtelierChoiceChip(
                  label:
                      '$pct% off · '
                      '${atelierMoney(row.lineTotal * (100 - pct) / 100)}',
                  selected: _percent == pct,
                  onTap: () => _usePercent(pct),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        AtelierTextField(
          controller: _amount,
          label: 'Private price for the whole item (USD)',
          prefixText: '\$ ',
          autofocus: true,
          error: _error,
          enabled: !_busy,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {
            _percent = null;
            _error = null;
          }),
        ),
        if (minimum != null) ...[
          const SizedBox(height: 6),
          Text(
            'Your minimum offer price: ${atelierMoney(minimum, decimals: 2)}. '
            'Only you see this.',
            style: AtelierType.caption(p.muted, size: 12),
          ),
        ],
        const SizedBox(height: 10),
        AtelierTextField(
          controller: _note,
          label: 'Note (optional)',
          minLines: 2,
          maxLines: 4,
          enabled: !_busy,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [
            LengthLimitingTextInputFormatter(interestedOfferNoteMax),
          ],
        ),
        const SizedBox(height: 4),
        _Counter(controller: _note, max: interestedOfferNoteMax),
        const SizedBox(height: 6),
        Text(
          'Must be below the listed price. The buyer has 24 hours to accept, '
          'decline or counter; an accepted offer holds the item for 24 '
          'hours.',
          style: AtelierType.caption(p.muted, size: 12),
        ),
        const SizedBox(height: 14),
        AtelierButton(
          label: 'Send private offer',
          icon: Icons.sell_outlined,
          variant: AtelierButtonVariant.gold,
          expand: true,
          loading: _busy,
          onPressed: _busy ? null : _send,
        ),
      ],
    );
  }
}
