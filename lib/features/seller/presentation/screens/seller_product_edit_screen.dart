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

import '../../../../core/l10n/app_localizations.dart';

class _EditField {
  const _EditField(this.id, {this.fullWidth = false, this.required = false});

  final String id;
  final bool fullWidth;
  final bool required;
}

class _EditSection {
  const _EditSection(this.titleKey, this.fields);

  final String titleKey;
  final List<_EditField> fields;
}

const _kEditInputFontSize = 16.0;
const _kEditLabelFontSize = 15.0;
const _kEditSectionFontSize = 16.0;
const _kEditInputMinHeight = 52.0;

/// Categorized editable fields for the seller product edit form.
const kSellerEditSections = <_EditSection>[
  _EditSection(CatalogL10n.basic, [
    _EditField('stock_number', required: true),
    _EditField('available'),
    _EditField('tags'),
    _EditField('origin'),
  ]),
  _EditSection(RemainingL10n.diamondSpecs, [
    _EditField('shape'),
    _EditField('carat_weight'),
    _EditField('color'),
    _EditField('clarity'),
    _EditField('cut'),
    _EditField('polish'),
    _EditField('symmetry'),
    _EditField('eye_clean'),
  ]),
  _EditSection(RemainingL10n.pricing, [
    _EditField('rap'),
    _EditField('discount'),
    _EditField('price_per_carat'),
    _EditField('total_price', required: true),
  ]),
  _EditSection(CatalogL10n.measurements, [
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
  _EditSection(RemainingL10n.certificateSection, [
    _EditField('certificate_company_name'),
    _EditField('certificate_number'),
    _EditField('certification'),
    _EditField('laser_inscription'),
  ]),
  _EditSection(CoreL10n.appearance, [
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
  _EditSection(RemainingL10n.notesSection, [
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

String _fieldLabel(BuildContext context, String fieldId) {
  final key = _fieldLabelKeys[fieldId];
  return key == null ? fieldId : context.tr(key);
}

final _fieldLabelKeys = <String, String>{
  'stock_number': RemainingL10n.stockNumberLabel,
  'available': CatalogL10n.available,
  'tags': RemainingL10n.tags,
  'origin': CatalogL10n.origin,
  'shape': CatalogL10n.shape,
  'carat_weight': CatalogL10n.caratWeight,
  'color': CatalogL10n.color,
  'clarity': CatalogL10n.clarity,
  'cut': RemainingL10n.cut,
  'polish': CatalogL10n.polish,
  'symmetry': CatalogL10n.symmetry,
  'eye_clean': CatalogL10n.eyeClean,
  'rap': RemainingL10n.rap,
  'discount': RemainingL10n.discount,
  'price_per_carat': CatalogL10n.pricePerCarat,
  'total_price': CatalogL10n.totalPrice,
  'measurement': CatalogL10n.measurement,
  'ratio': CatalogL10n.ratio,
  'table': RemainingL10n.tablePercent,
  'depth': RemainingL10n.depthPercent,
  'gridle_min': RemainingL10n.girdleMin,
  'gridle_max': RemainingL10n.girdleMax,
  'gridle_percentage': RemainingL10n.girdlePercent,
  'crown_height': RemainingL10n.crownHeight,
  'crown_angle': RemainingL10n.crownAngle,
  'pavilion_angle': RemainingL10n.pavilionAngle,
  'pavilion_depth': RemainingL10n.pavilionDepth,
  'culet_size': CatalogL10n.culetSize,
  'certificate_company_name': RemainingL10n.lab,
  'certificate_number': CatalogL10n.certificateHash,
  'certification': CatalogL10n.certification,
  'laser_inscription': RemainingL10n.laserInscription,
  'fluorescence_intensity': CatalogL10n.fluorescenceIntensity,
  'fluorescence_color': CatalogL10n.fluorescenceColor,
  'shade': CatalogL10n.shade,
  'tinge': RemainingL10n.tinge,
  'luster': RemainingL10n.luster,
  'milky': CatalogL10n.milky,
  'bgm': CatalogL10n.bgmLabel,
  'ha': RemainingL10n.ha,
  'fancy_color': CatalogL10n.fancyColors,
  'fancy_intensity': RemainingL10n.fancyIntensity,
  'fancy_overtone': RemainingL10n.fancyOvertone,
  'enhancement': RemainingL10n.enhancement,
  'growth_type': RemainingL10n.growthType,
  'inclusions_type': RemainingL10n.inclusions,
  'comment': CatalogL10n.comment,
  'cert_comment': RemainingL10n.certComment,
  'key_to_symbols': RemainingL10n.keyToSymbols,
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
    final updated = _product!.copyWith(stockNumber: stock, fields: fields);

    setState(() => _saving = true);
    final result = await ref
        .read(sellerProductsCatalogProvider.notifier)
        .persistUpdate(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(RemainingL10n.productUpdated))),
        );
        Navigator.of(context).pop(true);
      case ResultFailure(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
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
      return AppScaffold(
        appBar: SimpleAppTopBar(title: context.tr(RemainingL10n.editProduct2)),
        body: Center(child: Text(context.tr(RemainingL10n.productNotFound))),
      );
    }
    final muted = AppColors.textMuted(context);

    return AppScaffold(
      appBar: SimpleAppTopBar(title: context.tr(RemainingL10n.editProduct2)),
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
              context.tr(RemainingL10n.stockWithNumber, {
                'stockNumber':
                    '${_product!.stockNumber} · ID ${_product!.id}',
              }),
              style: AppTypography.body.copyWith(color: muted, fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.s12),
            for (final section in kSellerEditSections) ...[
              _SectionHeader(title: context.tr(section.titleKey)),
              const SizedBox(height: AppSpacing.s8),
              _FieldGrid(fields: section.fields, controllers: _controllers),
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
                        context.tr(RemainingL10n.saveChanges),
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
        color: AppColors.surface(context),
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
  const _FieldGrid({required this.fields, required this.controllers});

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
        labelText: _fieldLabel(context, field.id),
        floatingLabelStyle: AppTypography.label.copyWith(
          fontSize: _kEditLabelFontSize,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: AppTypography.label.copyWith(fontSize: _kEditLabelFontSize),
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
          borderSide: BorderSide(color: AppColors.border(context)),
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
      title: Text(context.tr(RemainingL10n.deleteProduct2)),
      content: Text(
        context.tr(RemainingL10n.removeStockConfirm, {
          'stockNumber': product.stockNumber,
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr(RemainingL10n.cancel)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.tr(RemainingL10n.delete)),
        ),
      ],
    ),
  );
  return result ?? false;
}
