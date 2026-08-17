import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
import '../../../../core/router/account_nav.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/inquiry_provider.dart';
import '../../data/mappers/inquiry_request_mapper.dart';
import '../../domain/models/seller_inquiry.dart';
import '../widgets/inquiry_form_fields.dart';
import '../widgets/seller_layout.dart';

class SellerInquiryFormScreen extends ConsumerStatefulWidget {
  const SellerInquiryFormScreen({
    super.key,
    this.initialCategory,
    this.showHeader = true,
  });

  final InquiryCategory? initialCategory;

  /// When false, the parent shell already provides the title/menu app bar.
  final bool showHeader;

  @override
  ConsumerState<SellerInquiryFormScreen> createState() =>
      _SellerInquiryFormScreenState();
}

class _SellerInquiryFormScreenState
    extends ConsumerState<SellerInquiryFormScreen> {
  InquiryCategory? _category;
  bool _dirty = false;
  bool _submitting = false;
  final _ctrls = <String, TextEditingController>{};
  final _bools = <String, bool>{};
  DateTime? _urgency;
  final List<Uint8List> _referenceImages = [];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _seedDefaults();
  }

  TextEditingController _c(String key, [String initial = '']) {
    return _ctrls.putIfAbsent(
      key,
      () => TextEditingController(text: initial),
    );
  }

  bool _b(String key, [bool initial = false]) {
    return _bools.putIfAbsent(key, () => initial);
  }

  void _markDirty([_]) => setState(() => _dirty = true);

  void _setBool(String key, bool value) {
    setState(() {
      _bools[key] = value;
      _dirty = true;
    });
  }

  void _setReferenceImages(List<Uint8List> images) {
    setState(() {
      _referenceImages
        ..clear()
        ..addAll(images);
      _dirty = true;
    });
  }

  Widget _referenceImageField() {
    final imageKey =
        _category?.imageFieldKey ?? InquiryCategory.diamond.imageFieldKey;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InquiryTextField(
          label: imageKey,
          controller: _c(imageKey == 'referenceImage' ? 'referenceImage' : 'imageUrl'),
          hint: 'https://example.com/image.jpg',
          onChanged: _markDirty,
        ),
        const SizedBox(height: 8),
        InquiryImagePickerField(
          label: 'Reference image (local preview)',
          helperText: 'Upload a photo of what you want (optional local preview)',
          images: _referenceImages,
          onChanged: _setReferenceImages,
        ),
      ],
    );
  }

  void _seedDefaults() {
    _c('subCategory', 'SINGLE');
    _c('diamondType', 'NATURAL');
    _c('shape', 'Round');
    _c('caratMin', '1');
    _c('caratMax', '2');
    _c('colorMin', 'D');
    _c('colorMax', 'G');
    _c('clarityMin', 'VS1');
    _c('clarityMax', 'SI1');
    _c('cut', 'EX-VG-GD');
    _c('quantity', '1');
    _c('gemstoneType', 'Ruby');
    _c('metalType', 'Gold');
    _c('metalFineness', '24KT');
    _c('shapeFormat', 'Coin');
    _c('weightMin', '10');
    _c('weightMax', '12');
    _c('jewelrySubCategory', 'Ring');
    _c('metalPurity', '18Kt');
    _c('brand', 'Rolex');
    _c('model', 'Submariner');
  }

  void _fillRandom() {
    setState(() {
      _dirty = true;
      switch (_category) {
        case InquiryCategory.diamond:
          _c('shape').text = 'Oval';
          _c('caratMin').text = '0.9';
          _c('caratMax').text = '1.5';
          _c('remarks').text = 'Need for anniversary gift';
          _c('deliveryLocation').text = 'Mumbai, IN';
        case InquiryCategory.gemstone:
          _c('gemstoneType').text = 'Sapphire';
          _c('clarity').text = 'VVS';
          _c('origin').text = 'Sri Lanka';
          _c('deliveryLocation').text = 'Delhi, IN';
        case InquiryCategory.bullion:
          _c('metalType').text = 'Silver';
          _c('preferredMint').text = 'PAMP';
          _c('deliveryLocation').text = 'Ahmedabad, IN';
        case InquiryCategory.watch:
          _c('brand').text = 'Omega';
          _c('model').text = 'Speedmaster';
          _c('condition').text = 'New';
          _c('deliveryLocation').text = 'Bangalore, IN';
        case InquiryCategory.jewelry:
          _c('jewelrySubCategory').text = 'Necklace';
          _c('metalColor').text = 'Yellow';
          _c('occasion').text = 'Wedding';
          _c('deliveryLocation').text = 'Jaipur, IN';
        case null:
          break;
      }
    });
  }

  void _reset() {
    for (final c in _ctrls.values) {
      c.clear();
    }
    _bools.clear();
    _urgency = null;
    _referenceImages.clear();
    _seedDefaults();
    setState(() => _dirty = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      _urgency = picked;
      _dirty = true;
    });
  }

  Future<void> _submit() async {
    if (_category == null || !_dirty || _submitting) return;

    setState(() => _submitting = true);

    final textFields = <String, String>{};
    for (final e in _ctrls.entries) {
      if (e.value.text.trim().isEmpty) continue;
      textFields[e.key] = e.value.text.trim();
    }

    final validationError = InquiryRequestMapper.validateFormInput(
      category: _category!,
      textFields: textFields,
    );
    if (validationError != null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    final result = await ref.read(inquiryMutationProvider.notifier).create(
          category: _category!,
          textFields: textFields,
          boolFields: Map<String, bool>.from(_bools),
          urgency: _urgency,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case Success(value: final inquiry):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_category!.label} inquiry sent to admin'),
          ),
        );
        final path = GoRouterState.of(context).uri.path;
        context.go(
          inquiryDetailPathFor(path, _category!.name, inquiry.id),
        );
      case ResultFailure(failure: final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Color _accent(InquiryCategory c) => switch (c) {
        InquiryCategory.diamond => AppColors.info,
        InquiryCategory.gemstone => AppSwatches.inquiryGemstone,
        InquiryCategory.bullion => AppSwatches.inquiryBullion,
        InquiryCategory.watch => AppColors.textSecondaryLight,
        InquiryCategory.jewelry => AppSwatches.inquiryJewelry,
      };

  IconData _icon(InquiryCategory c) => switch (c) {
        InquiryCategory.diamond => Icons.diamond_outlined,
        InquiryCategory.gemstone => Icons.auto_awesome,
        InquiryCategory.bullion => Icons.monetization_on_outlined,
        InquiryCategory.watch => Icons.watch_outlined,
        InquiryCategory.jewelry => Icons.workspace_premium_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => openSellerDrawer(context),
                  icon: const Icon(Icons.menu),
                ),
                IconButton(
                  onPressed: () => context.go(
                    inquiriesPathFor(GoRouterState.of(context).uri.path),
                  ),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(
                    'Product inquiry',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => context.go(
                inquiriesPathFor(GoRouterState.of(context).uri.path),
              ),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sandSurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Sent to admin',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Choose a category, then complete the form. Your inquiry is sent '
                'directly to admin — not to other buyers or sellers. Only admin '
                'replies will appear in your inbox.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.go(
                    inquiriesPathFor(GoRouterState.of(context).uri.path),
                  ),
                  child: const Text('Open inquiry inbox'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'STEP 1  What are you looking for?',
                style: AppTypography.label.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a category to load the matching form.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<InquiryCategory>(
                key: ValueKey(_category?.name),
                initialValue: _category,
                hint: const Text('Select category'),
                decoration: inquiryInputDecoration('Select category'),
                items: [
                  for (final c in InquiryCategory.values)
                    DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(_icon(c), size: 18, color: _accent(c)),
                          const SizedBox(width: 8),
                          Text(c.label),
                        ],
                      ),
                    ),
                ],
                onChanged: (c) {
                  if (c == null) return;
                  setState(() {
                    _category = c;
                    _dirty = true;
                  });
                },
              ),
              if (_category != null) ...[
                const SizedBox(height: 20),
                Text(
                  'STEP 2  Details',
                  style:
                      AppTypography.label.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ..._formFor(_category!),
                InquirySectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: _dirty && !_submitting ? _submit : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          backgroundColor: AppColors.info,
                          disabledBackgroundColor: AppColors.warmBorder,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Submit ${_category!.label.toLowerCase()} inquiry',
                              ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _fillRandom,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('Fill random data'),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _reset,
                        child: Text(
                          'Reset form',
                          style: AppTypography.label.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      Text(
                        'Submit is enabled after you make changes.',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _formFor(InquiryCategory c) => switch (c) {
        InquiryCategory.diamond => _diamondForm(),
        InquiryCategory.gemstone => _gemstoneForm(),
        InquiryCategory.bullion => _bullionForm(),
        InquiryCategory.watch => _watchForm(),
        InquiryCategory.jewelry => _jewelryForm(),
      };

  List<Widget> _diamondForm() => [
        InquirySectionCard(
          title: 'Basic details',
          child: Column(
            children: [
              InquiryDropdownField(
                label: 'subCategory',
                value: _c('subCategory').text,
                options: const ['SINGLE', 'PARCEL'],
                onChanged: (v) {
                  _c('subCategory').text = v;
                  _markDirty();
                },
              ),
              InquiryDropdownField(
                label: 'diamondType',
                value: _c('diamondType').text,
                options: const ['NATURAL', 'LAB'],
                onChanged: (v) {
                  _c('diamondType').text = v;
                  _markDirty();
                },
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Quality & specs',
          child: Column(
            children: [
              InquiryCheckboxField(
                label: 'isCertified',
                value: _b('isCertified', true),
                onChanged: (v) => _setBool('isCertified', v),
              ),
              if (_b('isCertified', true))
                InquiryTextField(
                  label: 'certificateName',
                  controller: _c('certificateName'),
                  hint: 'Enter certificate name (e.g. GIA)',
                  onChanged: _markDirty,
                ),
              InquiryTextField(
                label: 'shape',
                controller: _c('shape'),
                onChanged: _markDirty,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'caratMin',
                  controller: _c('caratMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'caratMax',
                  controller: _c('caratMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'colorMin',
                  controller: _c('colorMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'colorMax',
                  controller: _c('colorMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'clarityMin',
                  controller: _c('clarityMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'clarityMax',
                  controller: _c('clarityMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryTextField(
                label: 'cut',
                controller: _c('cut'),
                onChanged: _markDirty,
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Commercial',
          child: Column(
            children: [
              InquiryCheckboxField(
                label: 'Isrt',
                value: _b('Isrt'),
                onChanged: (v) => _setBool('Isrt', v),
              ),
              InquiryTextField(
                label: 'invitationType',
                controller: _c('invitationType'),
                onChanged: _markDirty,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'fluorescenceIntensityMin',
                  controller: _c('fluorescenceIntensityMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'fluorescenceIntensityMax',
                  controller: _c('fluorescenceIntensityMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryTextField(
                label: 'quantity',
                controller: _c('quantity'),
                onChanged: _markDirty,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'totalPriceMin',
                  controller: _c('totalPriceMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'totalPriceMax',
                  controller: _c('totalPriceMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'pricePerCaratMin',
                  controller: _c('pricePerCaratMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'pricePerCaratMax',
                  controller: _c('pricePerCaratMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryTextField(
                label: 'paymentTerms',
                controller: _c('paymentTerms'),
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'remarks',
                controller: _c('remarks'),
                maxLines: 3,
                onChanged: _markDirty,
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Dimensions (SINGLE)',
          child: Column(
            children: [
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'lengthMin',
                  controller: _c('lengthMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'lengthMax',
                  controller: _c('lengthMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'widthMin',
                  controller: _c('widthMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'widthMax',
                  controller: _c('widthMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'heightMin',
                  controller: _c('heightMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'heightMax',
                  controller: _c('heightMax'),
                  onChanged: _markDirty,
                ),
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Logistics',
          child: Column(
            children: [
              InquiryDateField(
                label: 'urgency',
                value: _urgency,
                onPick: _pickDate,
              ),
              _referenceImageField(),
              InquiryTextField(
                label: 'deliveryLocation',
                controller: _c('deliveryLocation'),
                onChanged: _markDirty,
              ),
            ],
          ),
        ),
      ];

  List<Widget> _gemstoneForm() => [
        InquirySectionCard(
          child: Column(
            children: [
              InquiryCheckboxField(
                label: 'Is Certified',
                value: _b('isCertified', true),
                onChanged: (v) => _setBool('isCertified', v),
              ),
              if (_b('isCertified', true))
                InquiryTextField(
                  label: 'certificateName',
                  controller: _c('certificateName'),
                  hint: 'Enter certificate name (e.g. GIA)',
                  onChanged: _markDirty,
                ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Gemstone properties',
          child: Column(
            children: [
              InquiryTextField(
                label: 'gemstone.type',
                controller: _c('gemstoneType'),
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'shape',
                controller: _c('shape'),
                onChanged: _markDirty,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'caratWeightMin',
                  controller: _c('caratMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'caratWeightMax',
                  controller: _c('caratMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'primaryColorMin',
                  controller: _c('primaryColorMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'primaryColorMax',
                  controller: _c('primaryColorMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryTextField(
                label: 'clarity',
                controller: _c('clarity'),
                onChanged: _markDirty,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'origin',
                  controller: _c('origin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'treatments',
                  controller: _c('treatments'),
                  onChanged: _markDirty,
                ),
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Commercial',
          child: Column(
            children: [
              InquiryTextField(
                label: 'quantity',
                controller: _c('quantity'),
                onChanged: _markDirty,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'totalBudgetMin',
                  controller: _c('totalBudgetMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'totalBudgetMax',
                  controller: _c('totalBudgetMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'pricePerCaratMin',
                  controller: _c('pricePerCaratMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'pricePerCaratMax',
                  controller: _c('pricePerCaratMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryTextField(
                label: 'description',
                controller: _c('description'),
                maxLines: 3,
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'paymentTerms',
                controller: _c('paymentTerms'),
                onChanged: _markDirty,
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Dimensions',
          child: Column(
            children: [
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'lengthMin',
                  controller: _c('lengthMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'lengthMax',
                  controller: _c('lengthMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'widthMin',
                  controller: _c('widthMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'widthMax',
                  controller: _c('widthMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'heightMin',
                  controller: _c('heightMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'heightMax',
                  controller: _c('heightMax'),
                  onChanged: _markDirty,
                ),
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Logistics',
          child: Column(
            children: [
              InquiryDateField(
                label: 'urgency',
                value: _urgency,
                onPick: _pickDate,
              ),
              _referenceImageField(),
              InquiryTextField(
                label: 'deliveryLocation',
                controller: _c('deliveryLocation'),
                onChanged: _markDirty,
              ),
            ],
          ),
        ),
      ];

  List<Widget> _bullionForm() => [
        InquirySectionCard(
          child: Column(
            children: [
              InquiryCheckboxField(
                label: 'isCertified',
                value: _b('isCertified'),
                onChanged: (v) => _setBool('isCertified', v),
              ),
              if (_b('isCertified'))
                InquiryTextField(
                  label: 'certificateName',
                  controller: _c('certificateName'),
                  hint: 'Enter certificate name (e.g. LBMA)',
                  onChanged: _markDirty,
                ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Bullion',
          child: Column(
            children: [
              InquiryTextField(
                label: 'metalType',
                controller: _c('metalType'),
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'metalFineness',
                controller: _c('metalFineness'),
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'shapeFormat',
                controller: _c('shapeFormat'),
                onChanged: _markDirty,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'weightMin',
                  controller: _c('weightMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'weightMax',
                  controller: _c('weightMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryTextField(
                label: 'preferredMint',
                controller: _c('preferredMint'),
                onChanged: _markDirty,
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Commercial',
          child: Column(
            children: [
              InquiryTextField(
                label: 'quantity',
                controller: _c('quantity'),
                onChanged: _markDirty,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'totalPriceMin',
                  controller: _c('totalPriceMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'totalPriceMax',
                  controller: _c('totalPriceMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'pricePerGramMin',
                  controller: _c('pricePerGramMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'pricePerGramMax',
                  controller: _c('pricePerGramMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryTextField(
                label: 'description',
                controller: _c('description'),
                maxLines: 3,
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'paymentTerms',
                controller: _c('paymentTerms'),
                onChanged: _markDirty,
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Dimensions',
          child: Column(
            children: [
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'lengthMin',
                  controller: _c('lengthMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'lengthMax',
                  controller: _c('lengthMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'widthMin',
                  controller: _c('widthMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'widthMax',
                  controller: _c('widthMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'heightMin',
                  controller: _c('heightMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'heightMax',
                  controller: _c('heightMax'),
                  onChanged: _markDirty,
                ),
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Logistics',
          child: Column(
            children: [
              InquiryDateField(
                label: 'expiry',
                value: _urgency,
                onPick: _pickDate,
              ),
              _referenceImageField(),
              InquiryTextField(
                label: 'deliveryLocation',
                controller: _c('deliveryLocation'),
                onChanged: _markDirty,
              ),
            ],
          ),
        ),
      ];

  List<Widget> _watchForm() => [
        InquirySectionCard(
          child: Column(
            children: [
              InquiryTextField(
                label: 'Brand',
                controller: _c('brand'),
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'Model',
                controller: _c('model'),
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'Reference Number',
                controller: _c('referenceNumber'),
                onChanged: _markDirty,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Year Min',
                  controller: _c('yearMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'Year Max',
                  controller: _c('yearMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Total Price Min',
                  controller: _c('totalPriceMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'Total Price Max',
                  controller: _c('totalPriceMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Case Material',
                  controller: _c('caseMaterial'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'Dial Color',
                  controller: _c('dialColor'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Case Size Min',
                  controller: _c('caseSizeMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'Case Size Max',
                  controller: _c('caseSizeMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryTextField(
                label: 'Strap Material',
                controller: _c('strapMaterial'),
                onChanged: _markDirty,
              ),
              InquiryDropdownField(
                label: 'Movement',
                value: _c('movement', 'Automatic').text,
                options: const ['Automatic', 'Manual', 'Quartz'],
                onChanged: (v) {
                  _c('movement').text = v;
                  _markDirty();
                },
              ),
              InquiryCheckboxField(
                label: 'hasOriginalBox',
                value: _b('hasOriginalBox'),
                onChanged: (v) => _setBool('hasOriginalBox', v),
              ),
              InquiryCheckboxField(
                label: 'hasWarrantyPapers',
                value: _b('hasWarrantyPapers'),
                onChanged: (v) => _setBool('hasWarrantyPapers', v),
              ),
              InquiryCheckboxField(
                label: 'hasService',
                value: _b('hasService'),
                onChanged: (v) => _setBool('hasService', v),
              ),
              InquiryTextField(
                label: 'Condition',
                controller: _c('condition'),
                hint: 'New / Used',
                onChanged: _markDirty,
              ),
              InquiryDateField(
                label: 'Urgency',
                value: _urgency,
                onPick: _pickDate,
              ),
              InquiryTextField(
                label: 'Description',
                controller: _c('description'),
                maxLines: 3,
                onChanged: _markDirty,
              ),
              _referenceImageField(),
              InquiryTextField(
                label: 'Delivery Location',
                controller: _c('deliveryLocation'),
                onChanged: _markDirty,
              ),
            ],
          ),
        ),
      ];

  List<Widget> _jewelryForm() => [
        InquirySectionCard(
          title: 'Base details',
          child: Column(
            children: [
              InquiryTextField(
                label: 'subCategory',
                controller: _c('jewelrySubCategory'),
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'metalType',
                controller: _c('metalType'),
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'metalPurity',
                controller: _c('metalPurity'),
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'metalColor',
                controller: _c('metalColor'),
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'occasion',
                controller: _c('occasion'),
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'versionReference',
                controller: _c('versionReference'),
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'finish',
                controller: _c('finish'),
                onChanged: _markDirty,
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Stone details',
          child: Column(
            children: [
              InquiryCheckboxField(
                label: 'hasStone',
                value: _b('hasStone'),
                onChanged: (v) => _setBool('hasStone', v),
              ),
              if (_b('hasStone')) ...[
                InquiryDropdownField(
                  label: 'stoneType',
                  value: _c('stoneType', 'NATURAL').text,
                  options: const ['NATURAL', 'LAB'],
                  hint: 'Select stone type',
                  onChanged: (v) {
                    _c('stoneType').text = v;
                    _markDirty();
                  },
                ),
                InquiryPairFields(
                  left: InquiryTextField(
                    label: 'stoneShape',
                    controller: _c('stoneShape'),
                    hint: 'e.g. Round, Oval',
                    onChanged: _markDirty,
                  ),
                  right: InquiryTextField(
                    label: 'stoneCut',
                    controller: _c('stoneCut'),
                    hint: 'e.g. Excellent',
                    onChanged: _markDirty,
                  ),
                ),
                InquiryTextField(
                  label: 'stoneQuantity',
                  controller: _c('stoneQuantity'),
                  hint: 'Enter quantity',
                  onChanged: _markDirty,
                ),
                InquiryPairFields(
                  left: InquiryTextField(
                    label: 'stoneCaratMin',
                    controller: _c('stoneCaratMin'),
                    hint: 'Min carat',
                    onChanged: _markDirty,
                  ),
                  right: InquiryTextField(
                    label: 'stoneCaratMax',
                    controller: _c('stoneCaratMax'),
                    hint: 'Max carat',
                    onChanged: _markDirty,
                  ),
                ),
                InquiryPairFields(
                  left: InquiryTextField(
                    label: 'stoneColorMin',
                    controller: _c('stoneColorMin'),
                    hint: 'Min color',
                    onChanged: _markDirty,
                  ),
                  right: InquiryTextField(
                    label: 'stoneColorMax',
                    controller: _c('stoneColorMax'),
                    hint: 'Max color',
                    onChanged: _markDirty,
                  ),
                ),
                InquiryPairFields(
                  left: InquiryTextField(
                    label: 'stoneClarityMin',
                    controller: _c('stoneClarityMin'),
                    hint: 'Min clarity',
                    onChanged: _markDirty,
                  ),
                  right: InquiryTextField(
                    label: 'stoneClarityMax',
                    controller: _c('stoneClarityMax'),
                    hint: 'Max clarity',
                    onChanged: _markDirty,
                  ),
                ),
              ],
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Design & dimensions',
          child: Column(
            children: [
              InquiryTextField(
                label: 'settingType',
                controller: _c('settingType'),
                onChanged: _markDirty,
              ),
              InquiryTextField(
                label: 'ringSize',
                controller: _c('ringSize'),
                onChanged: _markDirty,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'shankWidthMin',
                  controller: _c('shankWidthMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'shankWidthMax',
                  controller: _c('shankWidthMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'widthMin',
                  controller: _c('widthMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'widthMax',
                  controller: _c('widthMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'thicknessMin',
                  controller: _c('thicknessMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'thicknessMax',
                  controller: _c('thicknessMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'approxWeightMin',
                  controller: _c('approxWeightMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'approxWeightMax',
                  controller: _c('approxWeightMax'),
                  onChanged: _markDirty,
                ),
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Commercial & delivery',
          child: Column(
            children: [
              InquiryCheckboxField(
                label: 'isEngravingRequired',
                value: _b('isEngravingRequired'),
                onChanged: (v) => _setBool('isEngravingRequired', v),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'quantity',
                  controller: _c('quantity'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'paymentCurrency',
                  controller: _c('paymentCurrency'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'totalPriceMin',
                  controller: _c('totalPriceMin'),
                  onChanged: _markDirty,
                ),
                right: InquiryTextField(
                  label: 'totalPriceMax',
                  controller: _c('totalPriceMax'),
                  onChanged: _markDirty,
                ),
              ),
              InquiryTextField(
                label: 'designDescription',
                controller: _c('designDescription'),
                maxLines: 3,
                onChanged: _markDirty,
              ),
              _referenceImageField(),
              InquiryTextField(
                label: 'referenceVideo',
                controller: _c('referenceVideo'),
                onChanged: _markDirty,
              ),
              InquiryDateField(
                label: 'expiry',
                value: _urgency,
                onPick: _pickDate,
              ),
              InquiryTextField(
                label: 'deliveryLocation',
                controller: _c('deliveryLocation'),
                onChanged: _markDirty,
              ),
            ],
          ),
        ),
      ];
}



