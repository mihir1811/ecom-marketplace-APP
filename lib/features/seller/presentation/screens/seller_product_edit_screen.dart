import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../application/seller_products_provider.dart';
import '../../domain/models/seller_product.dart';

class _EditField {
  const _EditField(this.id, {this.fullWidth = false, this.required = false});

  final String id;
  final bool fullWidth;
  final bool required;
}

class _EditSection {
  const _EditSection(this.title, this.fields);

  final String title;
  final List<_EditField> fields;
}

const _kEditInputFontSize = 16.0;
const _kEditLabelFontSize = 15.0;
const _kEditSectionFontSize = 16.0;
const _kEditInputMinHeight = 52.0;

/// Categorized editable fields for the seller product edit form.
const kSellerEditSections = <_EditSection>[
  _EditSection('Basic', [
    _EditField('stock_number', required: true),
    _EditField('available'),
    _EditField('tags'),
    _EditField('origin'),
  ]),
  _EditSection('Diamond specs', [
    _EditField('shape'),
    _EditField('carat_weight'),
    _EditField('color'),
    _EditField('clarity'),
    _EditField('cut'),
    _EditField('polish'),
    _EditField('symmetry'),
    _EditField('eye_clean'),
  ]),
  _EditSection('Pricing', [
    _EditField('rap'),
    _EditField('discount'),
    _EditField('price_per_carat'),
    _EditField('total_price', required: true),
  ]),
  _EditSection('Measurements', [
    _EditField('measurement'),
    _EditField('ratio'),
    _EditField('table'),
    _EditField('depth'),
    _EditField('gridle_min'),
    _EditField('gridle_max'),
    _EditField('gridle_percentage'),
    _EditField('crown_height'),
    _EditField('crown_angle'),
    _EditField('pavilion_angle'),
    _EditField('pavilion_depth'),
    _EditField('culet_size'),
  ]),
  _EditSection('Certificate', [
    _EditField('certificate_company_name'),
    _EditField('certificate_number'),
    _EditField('certification'),
    _EditField('laser_inscription'),
  ]),
  _EditSection('Appearance', [
    _EditField('fluorescence_intensity'),
    _EditField('fluorescence_color'),
    _EditField('shade'),
    _EditField('tinge'),
    _EditField('luster'),
    _EditField('milky'),
    _EditField('bgm'),
    _EditField('ha'),
    _EditField('fancy_color'),
    _EditField('fancy_intensity'),
    _EditField('fancy_overtone'),
    _EditField('enhancement'),
    _EditField('growth_type'),
    _EditField('inclusions_type'),
  ]),
  _EditSection('Notes', [
    _EditField('comment', fullWidth: true),
    _EditField('cert_comment', fullWidth: true),
    _EditField('key_to_symbols', fullWidth: true),
  ]),
];

/// Flat list of all editable field ids (for controllers / save).
List<String> get kSellerEditableFieldIds => [
      for (final section in kSellerEditSections)
        for (final field in section.fields) field.id,
    ];

const _fieldLabels = <String, String>{
  'stock_number': 'Stock number',
  'available': 'Available',
  'tags': 'Tags',
  'origin': 'Origin',
  'shape': 'Shape',
  'carat_weight': 'Carat weight',
  'color': 'Color',
  'clarity': 'Clarity',
  'cut': 'Cut',
  'polish': 'Polish',
  'symmetry': 'Symmetry',
  'eye_clean': 'Eye clean',
  'rap': 'Rap',
  'discount': 'Discount',
  'price_per_carat': 'Price / ct',
  'total_price': 'Total price',
  'measurement': 'Measurement',
  'ratio': 'Ratio',
  'table': 'Table %',
  'depth': 'Depth %',
  'gridle_min': 'Girdle min',
  'gridle_max': 'Girdle max',
  'gridle_percentage': 'Girdle %',
  'crown_height': 'Crown height',
  'crown_angle': 'Crown angle',
  'pavilion_angle': 'Pavilion angle',
  'pavilion_depth': 'Pavilion depth',
  'culet_size': 'Culet size',
  'certificate_company_name': 'Lab',
  'certificate_number': 'Certificate #',
  'certification': 'Certification',
  'laser_inscription': 'Laser inscription',
  'fluorescence_intensity': 'Fluorescence',
  'fluorescence_color': 'Fluor. color',
  'shade': 'Shade',
  'tinge': 'Tinge',
  'luster': 'Luster',
  'milky': 'Milky',
  'bgm': 'BGM',
  'ha': 'H&A',
  'fancy_color': 'Fancy color',
  'fancy_intensity': 'Fancy intensity',
  'fancy_overtone': 'Fancy overtone',
  'enhancement': 'Enhancement',
  'growth_type': 'Growth type',
  'inclusions_type': 'Inclusions',
  'comment': 'Comment',
  'cert_comment': 'Cert comment',
  'key_to_symbols': 'Key to symbols',
};

/// Full-screen editor for an existing seller product (no create flow).
class SellerProductEditScreen extends ConsumerStatefulWidget {
  const SellerProductEditScreen({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<SellerProductEditScreen> createState() =>
      _SellerProductEditScreenState();
}

class _SellerProductEditScreenState
    extends ConsumerState<SellerProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  SellerProduct? _product;
  bool _ready = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final catalog = ref.read(sellerProductsCatalogProvider).products;
    SellerProduct? found;
    for (final p in catalog) {
      if (p.id == widget.productId) {
        found = p;
        break;
      }
    }
    if (found == null) {
      setState(() => _ready = true);
      return;
    }
    _product = found;
    _controllers = {
      for (final id in kSellerEditableFieldIds)
        id: TextEditingController(text: found.field(id) ?? ''),
    };
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    if (_ready && _product != null) {
      for (final c in _controllers.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_product == null || _saving) return;
    if (!AccountAccess.guard(context, ref)) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final fields = Map<String, String?>.from(_product!.fields);
    for (final id in kSellerEditableFieldIds) {
      final text = _controllers[id]!.text.trim();
      fields[id] = text.isEmpty ? null : text;
    }
    final stock = fields['stock_number'] ?? _product!.stockNumber;
    final updated = _product!.copyWith(
      stockNumber: stock,
      fields: fields,
    );

    setState(() => _saving = true);
    final result = await ref
        .read(sellerProductsCatalogProvider.notifier)
        .persistUpdate(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated')),
        );
        Navigator.of(context).pop(true);
      case ResultFailure(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_product == null) {
      return const AppScaffold(
        appBar: SimpleAppTopBar(title: 'Edit product'),
        body: Center(child: Text('Product not found')),
      );
    }
    const muted = AppColors.textMutedLight;

    return AppScaffold(
      appBar: const SimpleAppTopBar(title: 'Edit product'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s12,
            AppSpacing.s16,
            AppSpacing.s24,
          ),
          children: [
            Text(
              'Stock ${_product!.stockNumber} · ID ${_product!.id}',
              style: AppTypography.body.copyWith(
                color: muted,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            for (final section in kSellerEditSections) ...[
              _SectionHeader(title: section.title),
              const SizedBox(height: AppSpacing.s8),
              _FieldGrid(
                fields: section.fields,
                controllers: _controllers,
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.charcoal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r8),
                  ),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.warmWhite,
                        ),
                      )
                    : Text(
                        'Save changes',
                        style: AppTypography.label.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warmWhite,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.sandSurface,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
      ),
      child: Text(
        title,
        style: AppTypography.label.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: _kEditSectionFontSize,
        ),
      ),
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({
    required this.fields,
    required this.controllers,
  });

  final List<_EditField> fields;
  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var i = 0;
    while (i < fields.length) {
      final field = fields[i];
      if (field.fullWidth) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: _EditTextField(
              field: field,
              controller: controllers[field.id]!,
              maxLines: 3,
            ),
          ),
        );
        i++;
        continue;
      }

      final next = i + 1 < fields.length ? fields[i + 1] : null;
      if (next != null && !next.fullWidth) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _EditTextField(
                    field: field,
                    controller: controllers[field.id]!,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: _EditTextField(
                    field: next,
                    controller: controllers[next.id]!,
                  ),
                ),
              ],
            ),
          ),
        );
        i += 2;
      } else {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: _EditTextField(
              field: field,
              controller: controllers[field.id]!,
            ),
          ),
        );
        i++;
      }
    }
    return Column(children: rows);
  }
}

class _EditTextField extends StatelessWidget {
  const _EditTextField({
    required this.field,
    required this.controller,
    this.maxLines = 1,
  });

  final _EditField field;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: AppTypography.body.copyWith(
        fontSize: _kEditInputFontSize,
        height: 1.35,
      ),
      decoration: InputDecoration(
        labelText: _fieldLabels[field.id] ?? field.id,
        floatingLabelStyle: AppTypography.label.copyWith(
          fontSize: _kEditLabelFontSize,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: AppTypography.label.copyWith(
          fontSize: _kEditLabelFontSize,
        ),
        constraints: const BoxConstraints(minHeight: _kEditInputMinHeight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          borderSide: const BorderSide(color: AppColors.warmBorder),
        ),
      ),
      validator: field.required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}

/// Confirms soft-delete of a seller product.
Future<bool> confirmDeleteSellerProduct(
  BuildContext context,
  SellerProduct product,
) async {
  final result = await showAppDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete product?'),
      content: Text(
        'Remove stock ${product.stockNumber} from your active listings? '
        'This cannot be undone from this screen.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
