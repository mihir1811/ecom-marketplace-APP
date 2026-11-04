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
import '../../application/jewelry_orders_provider.dart';
import '../../domain/models/marketplace_order.dart';
import '../jewelry_checkout_format.dart';
import '../widgets/jewelry_location_picker.dart';

/// Delivery address, an optional note and the payable total (taxes shown
/// row by row). Country, then state, then city are picked from the
/// storefront's lists (India preselected), with typed fields when a list
/// is missing or the city isn't listed. "Pay" creates the order and opens
/// Razorpay; only the API marks it paid.
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

  /// 2-letter ISO code.
  String _country = 'IN';

  /// Code of the picked state (for its city list); null when typed.
  String? _stateCode;

  /// The buyer chose "My city isn't listed".
  bool _cityTyped = false;

  bool get _india => _country == 'IN';

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
    final country = saved?.country.trim().toUpperCase() ?? '';
    if (country.length == 2) setState(() => _country = country);
  }

  Future<void> _pickCountry(List<JewelryLocation> countries) async {
    final picked = await showJewelryLocationSheet(
      context,
      title: context.tr(JewelryMarketL10n.country),
      items: countries,
      selectedCode: _country,
    );
    if (picked == null || picked.code.isEmpty || !mounted) return;
    if (picked.code == _country) return;
    setState(() {
      _country = picked.code;
      _stateCode = null;
      _cityTyped = false;
      _state.clear();
      _city.clear();
      _pin.clear();
    });
  }

  Future<void> _pickState(List<JewelryLocation> states, String? current) async {
    final picked = await showJewelryLocationSheet(
      context,
      title: context.tr(JewelryMarketL10n.state),
      items: states,
      selectedCode: current,
    );
    if (picked == null || picked.code.isEmpty || !mounted) return;
    if (picked.code == current) return;
    setState(() {
      _stateCode = picked.code;
      _state.text = picked.name;
      _cityTyped = false;
      _city.clear();
    });
  }

  Future<void> _pickCity(List<JewelryLocation> cities) async {
    final picked = await showJewelryLocationSheet(
      context,
      title: context.tr(JewelryMarketL10n.city),
      items: cities,
      selectedCode: _city.text,
      notListedLabel: context.tr(JewelryMarketL10n.cityNotListed),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (picked == jewelryLocationNotListed) {
        _cityTyped = true;
        _city.clear();
      } else {
        _city.text = picked.name;
      }
    });
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _line1,
      _line2,
      _city,
      _state,
      _pin,
      _note,
    ]) {
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
            country: _country,
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
    final quote = ref.watch(jewelryBagQuoteProvider).value;
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

    // Location lists: empty while loading or when unavailable, which
    // leaves the typed fields in place.
    final countriesAsync = ref.watch(
      jewelryLocationsProvider((country: null, state: null)),
    );
    final loadedCountries = countriesAsync.value ?? const [];
    final countries = loadedCountries.isEmpty
        ? const <JewelryLocation>[(code: 'IN', name: 'India')]
        : loadedCountries;
    final countryName =
        countries.where((c) => c.code == _country).firstOrNull?.name ??
        _country;
    final statesAsync = ref.watch(
      jewelryLocationsProvider((country: _country, state: null)),
    );
    final states = statesAsync.value ?? const <JewelryLocation>[];
    final typedState = _state.text.trim().toLowerCase();
    final stateCode =
        _stateCode ??
        states
            .where((s) => s.name.toLowerCase() == typedState)
            .firstOrNull
            ?.code;
    final citiesAsync = stateCode == null
        ? null
        : ref.watch(
            jewelryLocationsProvider((country: _country, state: stateCode)),
          );
    final cities = citiesAsync?.value ?? const <JewelryLocation>[];
    final pickCity = cities.isNotEmpty && !_cityTyped;

    String? stateCheck(String? v) {
      final t = v?.trim() ?? '';
      if (t.isEmpty) {
        return _india ? context.tr(JewelryMarketL10n.stateRequired) : null;
      }
      return required(v, 2, 80);
    }

    String? postalCheck(String? v) {
      final t = v?.trim() ?? '';
      if (_india) {
        return RegExp(r'^\d{6}$').hasMatch(t)
            ? null
            : context.tr(JewelryMarketL10n.pinInvalid);
      }
      if (t.isEmpty) return null;
      return RegExp(r'^[A-Za-z0-9 -]{2,10}$').hasMatch(t)
          ? null
          : context.tr(JewelryMarketL10n.postalInvalid);
    }

    Widget summaryRow(String label, String value, {bool strong = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: strong
                      ? LuxeType.label(p.ink, size: 15)
                      : LuxeType.body(p.inkMuted, size: 14),
                ),
              ),
              Text(
                value,
                style: LuxeType.figure(p.ink, size: strong ? 17 : 14).copyWith(
                  fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(title: context.tr(JewelryMarketL10n.checkout)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
          children: [
            Text(
              context.tr(JewelryMarketL10n.deliverTo),
              style: LuxeType.display(26, p.ink),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: field(context.tr(JewelryMarketL10n.fullName)),
              validator: (v) => required(v, 2, 100),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            TextFormField(
              controller: _line1,
              autofillHints: const [AutofillHints.streetAddressLine1],
              decoration: field(context.tr(JewelryMarketL10n.addressLine1)),
              validator: (v) => required(v, 3, 200),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _line2,
              autofillHints: const [AutofillHints.streetAddressLine2],
              decoration: field(context.tr(JewelryMarketL10n.addressLine2)),
              validator: (v) => (v?.trim().length ?? 0) > 200
                  ? context.tr(JewelryMarketL10n.fieldTooLong, {'max': 200})
                  : null,
            ),
            const SizedBox(height: 8),
            JewelryPickerField(
              label: context.tr(JewelryMarketL10n.country),
              value: countryName,
              loading: countriesAsync.isLoading,
              onTap: () => _pickCountry(countries),
              validator: (_) => _country.length == 2
                  ? null
                  : context.tr(JewelryMarketL10n.chooseCountry),
            ),
            const SizedBox(height: 8),
            if (states.isNotEmpty)
              JewelryPickerField(
                label: context.tr(JewelryMarketL10n.state),
                value: _state.text,
                onTap: () => _pickState(states, stateCode),
                validator: (_) => stateCheck(_state.text),
              )
            else
              TextFormField(
                controller: _state,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.addressState],
                decoration: field(context.tr(JewelryMarketL10n.state)),
                validator: stateCheck,
              ),
            const SizedBox(height: 8),
            if (pickCity)
              JewelryPickerField(
                label: context.tr(JewelryMarketL10n.city),
                value: _city.text,
                onTap: () => _pickCity(cities),
                validator: (_) => required(_city.text, 2, 80),
              )
            else
              TextFormField(
                controller: _city,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.addressCity],
                decoration: field(context.tr(JewelryMarketL10n.city)),
                validator: (v) => required(v, 2, 80),
              ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('postal-$_india'),
              controller: _pin,
              keyboardType: _india ? TextInputType.number : TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              autofillHints: const [AutofillHints.postalCode],
              inputFormatters: _india
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ]
                  : [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9 -]'),
                      ),
                      LengthLimitingTextInputFormatter(10),
                    ],
              decoration: field(
                context.tr(
                  _india
                      ? JewelryMarketL10n.pinCode
                      : JewelryMarketL10n.postalCode,
                ),
              ),
              validator: postalCheck,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _note,
              maxLines: 3,
              minLines: 2,
              maxLength: 500,
              decoration: field(context.tr(JewelryMarketL10n.orderNote)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(LuxeSpace.radius),
                border: Border.all(color: p.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (quote == null)
                    const LuxeSkeleton(height: 18)
                  else ...[
                    summaryRow(
                      context.tr(JewelryMarketL10n.piecesCount, {
                        'count': pieces,
                      }),
                      rupees(quote.subtotal),
                    ),
                    for (final t in quote.taxes)
                      summaryRow(t.label, rupees(t.amount)),
                    summaryRow(
                      context.tr(JewelryMarketL10n.shipping),
                      quote.shipping <= 0
                          ? context.tr(JewelryMarketL10n.free)
                          : rupees(quote.shipping),
                    ),
                    Divider(color: p.hairline, height: 16),
                    summaryRow(
                      context.tr(JewelryMarketL10n.total),
                      rupees(quote.total),
                      strong: true,
                    ),
                  ],
                  const SizedBox(height: 6),
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
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
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
