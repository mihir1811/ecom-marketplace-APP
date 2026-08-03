import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/delivery_address.dart';

/// Modal form for adding / editing a delivery address.
Future<DeliveryAddress?> showDeliveryAddressSheet(
  BuildContext context, {
  DeliveryAddress? initial,
}) {
  return showModalBottomSheet<DeliveryAddress>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.warmWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
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
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s24,
          AppSpacing.s16,
          AppSpacing.s24,
          AppSpacing.s24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.bronze, size: 20),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    'Deliver to',
                    style: AppTypography.title.copyWith(
                      color: AppColors.bronze,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppTypography.label.copyWith(
                        color: AppColors.bronze,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              _field(_name, 'Full name', required: true),
              _field(
                _phone,
                'Phone',
                required: true,
                keyboard: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              _field(_line1, 'Address line 1', required: true),
              _field(_line2, 'Address line 2'),
              _field(_city, 'City', required: true),
              _field(_state, 'State', required: true),
              _field(_postal, 'ZIP / Postal code', required: true),
              _field(_country, 'Country', required: true),
              _field(_label, 'Label (Home, Office)'),
              const SizedBox(height: AppSpacing.s16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.charcoal,
                    foregroundColor: AppColors.warmWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r12),
                    ),
                  ),
                  onPressed: _save,
                  child: Text(
                    'Save address',
                    style: AppTypography.label.copyWith(
                      color: AppColors.warmWhite,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    bool required = false,
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.warmWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.r12),
            borderSide: const BorderSide(color: AppColors.warmBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.r12),
            borderSide: const BorderSide(color: AppColors.warmBorder),
          ),
        ),
      ),
    );
  }
}
