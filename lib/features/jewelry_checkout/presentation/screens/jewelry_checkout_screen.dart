import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../application/jewelry_bag_provider.dart';
import '../../application/jewelry_checkout_controller.dart';
import '../../domain/models/marketplace_order.dart';
import '../jewelry_checkout_format.dart';

/// Delivery address (India only), an optional note and the payable total.
/// "Pay" creates the order and opens Razorpay; only the API marks it paid.
class JewelryCheckoutScreen extends ConsumerStatefulWidget {
  const JewelryCheckoutScreen({super.key});

  @override
  ConsumerState<JewelryCheckoutScreen> createState() =>
      _JewelryCheckoutScreenState();
}

class _JewelryCheckoutScreenState extends ConsumerState<JewelryCheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pin = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final saved = await ref.read(jewelryBagStoreProvider).readAddress();
    if (!mounted) return;
    final user = ref.read(authProvider).user;
    void set(TextEditingController c, String? v) {
      if (c.text.isEmpty && v != null && v.trim().isNotEmpty) c.text = v;
    }

    set(_name, saved?.fullName ?? user?.fullName);
    set(_phone, saved?.phone ?? user?.phone);
    set(_line1, saved?.line1);
    set(_line2, saved?.line2);
    set(_city, saved?.city);
    set(_state, saved?.state);
    set(_pin, saved?.postalCode);
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _line1, _line2, _city, _state, _pin, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pay() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final lines = ref.read(jewelryBagProvider);
    if (lines.isEmpty) return;
    final outcome = await ref
        .read(jewelryCheckoutProvider.notifier)
        .placeOrder(
          lines: lines,
          address: MarketplaceAddress(
            fullName: _name.text,
            phone: _phone.text,
            line1: _line1.text,
            line2: _line2.text,
            city: _city.text,
            state: _state.text,
            postalCode: _pin.text,
          ),
          note: _note.text,
        );
    if (!mounted) return;
    switch (outcome) {
      case JewelryCheckoutPaid(:final order):
        showLuxeToast(
          context,
          context.tr(JewelryMarketL10n.orderPlaced, {
            'number': order.orderNumber,
          }),
          tone: LuxeTone.success,
        );
        context.pushReplacement(AppRouteNames.jewelryOrderDetailPath(order.id));
      case JewelryCheckoutNotPaid(:final message, :final orderId):
        showLuxeToast(context, message, tone: LuxeTone.info);
        context.pushReplacement(AppRouteNames.jewelryOrderDetailPath(orderId));
      case JewelryCheckoutFailed(:final message, :final bagChanged):
        showLuxeToast(context, message, tone: LuxeTone.error);
        if (bagChanged) {
          ref.invalidate(jewelryBagQuoteProvider);
          context.goBack();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _build));
  }

  Widget _build(BuildContext context) {
    final p = LuxePalette.of(context);
    final busy = ref.watch(jewelryCheckoutProvider);
    final quote = ref.watch(jewelryBagQuoteProvider).valueOrNull;
    final lines = ref.watch(jewelryBagProvider);
    final pieces = lines.fold(0, (s, l) => s + l.quantity);
    final ready = quote != null && quote.ready;

    String? required(String? v, int min, int max) {
      final t = v?.trim() ?? '';
      if (t.length < min) return context.tr(JewelryMarketL10n.fieldRequired);
      if (t.length > max) {
        return context.tr(JewelryMarketL10n.fieldTooLong, {'max': max});
      }
      return null;
    }

    InputDecoration field(String label) => InputDecoration(labelText: label);

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(title: context.tr(JewelryMarketL10n.checkout)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              context.tr(JewelryMarketL10n.deliverTo),
              style: LuxeType.display(26, p.ink),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr(JewelryMarketL10n.indiaOnly),
              style: LuxeType.body(p.inkMuted, size: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: field(context.tr(JewelryMarketL10n.fullName)),
              validator: (v) => required(v, 2, 100),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
              ],
              decoration: field(context.tr(JewelryMarketL10n.phone)),
              validator: (v) {
                final t = v?.trim() ?? '';
                return RegExp(r'^\+?[0-9\s-]{8,16}$').hasMatch(t)
                    ? null
                    : context.tr(JewelryMarketL10n.phoneInvalid);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _line1,
              autofillHints: const [AutofillHints.streetAddressLine1],
              decoration: field(context.tr(JewelryMarketL10n.addressLine1)),
              validator: (v) => required(v, 3, 200),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _line2,
              autofillHints: const [AutofillHints.streetAddressLine2],
              decoration: field(context.tr(JewelryMarketL10n.addressLine2)),
              validator: (v) => (v?.trim().length ?? 0) > 200
                  ? context.tr(JewelryMarketL10n.fieldTooLong, {'max': 200})
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.addressCity],
                    decoration: field(context.tr(JewelryMarketL10n.city)),
                    validator: (v) => required(v, 2, 80),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _state,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.addressState],
                    decoration: field(context.tr(JewelryMarketL10n.state)),
                    validator: (v) => required(v, 2, 80),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pin,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.postalCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: field(context.tr(JewelryMarketL10n.pinCode)),
              validator: (v) => RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '')
                  ? null
                  : context.tr(JewelryMarketL10n.pinInvalid),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              maxLines: 3,
              minLines: 2,
              maxLength: 500,
              decoration: field(context.tr(JewelryMarketL10n.orderNote)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(LuxeSpace.radius),
                border: Border.all(color: p.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(JewelryMarketL10n.piecesCount, {
                            'count': pieces,
                          }),
                          style: LuxeType.body(p.inkMuted, size: 14),
                        ),
                      ),
                      if (quote == null)
                        const LuxeSkeleton(width: 80, height: 16)
                      else
                        Text(
                          rupees(quote.total),
                          style: LuxeType.figure(
                            p.ink,
                            size: 17,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      ready
                          ? JewelryMarketL10n.payNote
                          : JewelryMarketL10n.fixBagFirst,
                    ),
                    style: LuxeType.body(
                      ready ? p.inkMuted : p.caution,
                      size: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: LuxeButton(
            label: quote == null
                ? context.tr(JewelryMarketL10n.pay)
                : context.tr(JewelryMarketL10n.payAmount, {
                    'amount': rupees(quote.total),
                  }),
            expand: true,
            variant: LuxeButtonVariant.accent,
            icon: Icons.lock_outline_rounded,
            loading: busy,
            onPressed: ready && !busy ? _pay : null,
          ),
        ),
      ),
    );
  }
}
