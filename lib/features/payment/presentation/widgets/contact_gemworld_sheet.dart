import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../cart/application/cart_provider.dart';
import '../../application/payment_checkout_provider.dart';

/// Contact GemWorld for a bag over the online-payment limit: asks for a
/// phone and an optional note, then hands the bag to GemWorld. Returns the
/// server's confirmation message once sent, or null when closed.
Future<String?> showContactGemworldSheet(BuildContext context) {
  return showLuxeSheet<String>(
    context,
    title: 'Contact GemWorld',
    subtitle:
        'This order is over the online payment limit. Our team will call '
        'you to arrange the payment; items stay reserved for you meanwhile.',
    builder: (context) => const _ContactGemworldForm(),
  );
}

class _ContactGemworldForm extends ConsumerStatefulWidget {
  const _ContactGemworldForm();

  @override
  ConsumerState<_ContactGemworldForm> createState() =>
      _ContactGemworldFormState();
}

class _ContactGemworldFormState extends ConsumerState<_ContactGemworldForm> {
  final _form = GlobalKey<FormState>();
  late final _phone = TextEditingController(
    text: ref.read(cartProvider).address?.phone ?? '',
  );
  final _note = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await ref
        .read(paymentCheckoutProvider.notifier)
        .contactGemworld(contactPhone: _phone.text, note: _note.text);
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        Navigator.of(context).pop(value);
      case ResultFailure(:final failure):
        // e.g. "Enter a valid phone number.": ask again in place.
        setState(() {
          _sending = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          TextFormField(
            controller: _phone,
            autofocus: true,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
            validator: (raw) =>
                (raw ?? '').replaceAll(RegExp(r'\D'), '').length < 7
                ? 'Enter a valid phone number.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _note,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: LuxeType.label(p.caution, size: 12.5)),
          ],
          const SizedBox(height: 22),
          LuxeButton(
            label: 'Send to GemWorld',
            expand: true,
            variant: LuxeButtonVariant.accent,
            icon: Icons.support_agent_outlined,
            loading: _sending,
            onPressed: _sending ? null : _submit,
          ),
        ],
      ),
    );
  }
}
