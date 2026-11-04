import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../domain/models/delivery_address.dart';

/// Modal form for adding / editing a delivery address.
Future<DeliveryAddress?> showDeliveryAddressSheet(
  BuildContext context, {
  DeliveryAddress? initial,
}) {
  return showLuxeSheet<DeliveryAddress>(
    context,
    title: initial?.id != null
        ? context.tr(AccountCommerceL10n.editAddress)
        : context.tr(AccountCommerceL10n.addAddress),
    subtitle: context.tr(AccountCommerceL10n.deliverTo),
    builder: (context) => _DeliveryAddressSheet(initial: initial),
  );
}

class _DeliveryAddressSheet extends StatefulWidget {
  const _DeliveryAddressSheet({this.initial});

  final DeliveryAddress? initial;

  @override
  State<_DeliveryAddressSheet> createState() => _DeliveryAddressSheetState();
}

class _DeliveryAddressSheetState extends State<_DeliveryAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _postal;
  late final TextEditingController _country;
  late final TextEditingController _label;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?.fullName ?? '');
    _phone = TextEditingController(text: i?.phone ?? '');
    _line1 = TextEditingController(text: i?.line1 ?? '');
    _line2 = TextEditingController(text: i?.line2 ?? '');
    _city = TextEditingController(text: i?.city ?? '');
    _state = TextEditingController(text: i?.state ?? '');
    _postal = TextEditingController(text: i?.postalCode ?? '');
    _country = TextEditingController(text: i?.country ?? '');
    _label = TextEditingController(text: i?.label ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    _country.dispose();
    _label.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      DeliveryAddress(
        id: widget.initial?.id,
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        line1: _line1.text.trim(),
        line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        postalCode: _postal.text.trim(),
        country: _country.text.trim(),
        label: _label.text.trim().isEmpty ? null : _label.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 8),
        Expanded(child: b),
      ],
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            _name,
            context.tr(AccountCommerceL10n.fullNameField),
            required: true,
            icon: Icons.person_outline_rounded,
          ),
          _field(
            _phone,
            context.tr(AccountCommerceL10n.phone),
            required: true,
            keyboard: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            icon: Icons.call_outlined,
          ),
          _field(
            _line1,
            context.tr(AccountCommerceL10n.addressLine1),
            required: true,
            icon: Icons.home_outlined,
          ),
          _field(_line2, context.tr(AccountCommerceL10n.addressLine2)),
          pair(
            _field(_city, context.tr(AccountCommerceL10n.city), required: true),
            _field(
              _state,
              context.tr(AccountCommerceL10n.state),
              required: true,
            ),
          ),
          pair(
            _field(
              _postal,
              context.tr(AccountCommerceL10n.postalCodeCaps),
              required: true,
            ),
            _field(
              _country,
              context.tr(AccountCommerceL10n.country),
              required: true,
            ),
          ),
          _field(
            _label,
            context.tr(AccountCommerceL10n.addressLabel),
            icon: Icons.bookmark_border_rounded,
          ),
          const SizedBox(height: 6),
          LuxeButton(
            label: widget.initial?.id != null
                ? context.tr(AccountCommerceL10n.updateAddress)
                : context.tr(AccountCommerceL10n.saveAddress),
            icon: Icons.check_rounded,
            expand: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        textInputAction: TextInputAction.next,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                  ? context.tr(AccountCommerceL10n.required)
                  : null
            : null,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          prefixIcon: icon == null ? null : Icon(icon, size: 19),
        ),
      ),
    );
  }
}
