import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
import '../../../../core/router/account_nav.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/inquiry_provider.dart';
import '../../data/mappers/inquiry_request_mapper.dart';
import '../../domain/models/seller_inquiry.dart';
import '../widgets/bullion_inquiry_form.dart';
import '../widgets/diamond_inquiry_form.dart';
import '../widgets/gemstone_inquiry_form.dart';
import '../widgets/inquiry_category_picker.dart';
import '../widgets/inquiry_form_fields.dart';
import '../widgets/jewelry_inquiry_form.dart';
import '../widgets/watch_inquiry_form.dart';

import '../../../../core/l10n/app_localizations.dart';

class SellerInquiryFormScreen extends ConsumerStatefulWidget {
  const SellerInquiryFormScreen({super.key, this.initialCategory});

  final InquiryCategory? initialCategory;

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
    return _ctrls.putIfAbsent(key, () => TextEditingController(text: initial));
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

  void _seedDefaults() {
    _c('subCategory', 'SINGLE');
    _c('diamondType', 'NATURAL');
    _c('shape', 'Round');
    _c('caratMin', '1');
    _c('caratMax', '2');
    _c('colorMin', 'D');
    _c('colorMax', 'G');
    _c('clarityMin', 'VVS2');
    _c('clarityMax', 'VS2');
    _c('cut', 'EX-VG-VG');
    _c('parcelMeasure', 'carat');
    _c('growthProcess', 'CVD');
    _c('photoSource', 'device');
    _c('videoSource', 'device');
    _c('fancyColorMin', 'Yellow');
    _c('fancyColorMax', 'Yellow');
    _c('quantity', '1');
    _c('gemstoneType', 'Ruby');
    _c('metalType', 'Gold');
    _c('metalFineness', '24K');
    _c('shapeFormat', 'Coin');
    _c('weightMin', '9');
    _c('weightMax', '12');
    _c('jewelrySubCategory', 'Accessories');
    _c('metalPurity', '18KT');
    _c('stoneType', 'NATURAL');
    _c('brand', 'Rolex');
    _c('model', 'Submariner');
    _c('movement', 'AUTOMATIC');
    _bools['isCertified'] = true;
    _bools['hasStone'] = true;
    _bools['isEngravingRequired'] = true;
    _bools['hasOriginalBox'] = true;
    _bools['hasWarrantyPapers'] = true;
    _bools['hasManuals'] = true;
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
    if (_category == InquiryCategory.diamond) {
      _prepareDiamondFields(textFields);
    }
    _prepareMediaFields(textFields);
    textFields.removeWhere(
      (key, value) => value == InquiryDropdownField.otherValue,
    );

    final validationError = InquiryRequestMapper.validateFormInput(
      category: _category!,
      textFields: textFields,
    );
    if (validationError != null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    final result = await ref
        .read(inquiryMutationProvider.notifier)
        .create(
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
          SnackBar(content: Text('${_category!.label} inquiry sent to admin')),
        );
        final path = GoRouterState.of(context).uri.path;
        context.openRoute(
          inquiryDetailPathFor(path, _category!.name, inquiry.id),
        );
      case ResultFailure(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.goBack(),
            child: Text(context.tr(RemainingL10n.allInquiries)),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              Text.rich(
                TextSpan(
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: context.tr(
                        RemainingL10n.chooseACategoryThenCompleteThe,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: () => context.goBack(),
                        child: Text(
                          context.tr(RemainingL10n.viewYourSubmittedInquiries),
                          style: AppTypography.body.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr(RemainingL10n.step1WhatAreYouLookingFor),
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(RemainingL10n.tapACategoryToLoadTheMatching),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 12),
              InquiryCategoryPicker(
                selected: _category,
                onSelected: (c) {
                  setState(() {
                    _category = c;
                    _dirty = true;
                  });
                },
              ),
              if (_category != null) ...[
                const SizedBox(height: 20),
                Text(
                  context.tr(RemainingL10n.step2Details),
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ..._formFor(_category!),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 560;
                    final submit = FilledButton(
                      onPressed: _dirty && !_submitting ? _submit : null,
                      style: FilledButton.styleFrom(
                        minimumSize: Size(stacked ? double.infinity : 220, 46),
                        backgroundColor: AppColors.info,
                        disabledBackgroundColor: AppColors.border(context),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.warmWhite,
                              ),
                            )
                          : Text(_category!.submitLabel),
                    );
                    final tools = OutlinedButton(
                      onPressed: _reset,
                      child: Text(context.tr(RemainingL10n.resetForm)),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (stacked) ...[
                          tools,
                          const SizedBox(height: 10),
                          submit,
                        ] else
                          Row(children: [tools, const Spacer(), submit]),
                        const SizedBox(height: 8),
                        Text(
                          context.tr(
                            RemainingL10n.submitIsEnabledAfterYouMakeChanges,
                          ),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
                    );
                  },
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

  void _prepareDiamondFields(Map<String, String> textFields) {
    const uiOnly = {
      'parcelMeasure',
      'photoSource',
      'videoSource',
      'videoFileName',
      'fancyColorMin',
      'fancyColorMax',
      'totalPieces',
    };
    if (_b('isFancyColor')) {
      final min = _c('fancyColorMin').text.trim();
      final max = _c('fancyColorMax').text.trim();
      if (min.isNotEmpty) textFields['colorMin'] = min;
      if (max.isNotEmpty) textFields['colorMax'] = max;
    }
    if (_c('subCategory').text == 'PARCEL' &&
        _c('parcelMeasure').text == 'pieces') {
      final pieces = _c('totalPieces').text.trim();
      if (pieces.isNotEmpty) textFields['quantity'] = pieces;
      textFields.remove('caratMin');
      textFields.remove('caratMax');
    }
    if (_c('subCategory').text == 'PARCEL' &&
        _c('parcelMeasure').text == 'carat') {
      textFields.remove('quantity');
    }
    if (_c('diamondType').text != 'LAB') {
      textFields.remove('growthProcess');
    }
    if (_c('photoSource').text != 'url') {
      textFields.remove('imageUrl');
    }
    if (_c('videoSource').text != 'url') {
      textFields.remove('videoUrl');
    }
    for (final key in uiOnly) {
      textFields.remove(key);
    }
  }

  List<Widget> _diamondForm() => [
    DiamondInquiryForm(
      controller: _c,
      flag: _b,
      setFlag: _setBool,
      onChanged: _markDirty,
      urgency: _urgency,
      onPickUrgency: _pickDate,
      referenceImages: _referenceImages,
      onReferenceImages: _setReferenceImages,
    ),
  ];

  void _prepareMediaFields(Map<String, String> textFields) {
    const uiOnly = {'photoSource', 'videoSource', 'videoFileName'};
    if (_c('photoSource').text != 'url') {
      textFields.remove('imageUrl');
      textFields.remove('referenceImage');
    }
    if (_c('videoSource').text != 'url') {
      textFields.remove('videoUrl');
      textFields.remove('referenceVideo');
    }
    for (final key in uiOnly) {
      textFields.remove(key);
    }
  }

  List<Widget> _gemstoneForm() => [
    GemstoneInquiryForm(
      controller: _c,
      flag: _b,
      setFlag: _setBool,
      onChanged: _markDirty,
      urgency: _urgency,
      onPickUrgency: _pickDate,
      referenceImages: _referenceImages,
      onReferenceImages: _setReferenceImages,
    ),
  ];

  List<Widget> _bullionForm() => [
    BullionInquiryForm(
      controller: _c,
      flag: _b,
      setFlag: _setBool,
      onChanged: _markDirty,
      urgency: _urgency,
      onPickUrgency: _pickDate,
      referenceImages: _referenceImages,
      onReferenceImages: _setReferenceImages,
    ),
  ];

  List<Widget> _watchForm() => [
    WatchInquiryForm(
      controller: _c,
      flag: _b,
      setFlag: _setBool,
      onChanged: _markDirty,
      urgency: _urgency,
      onPickUrgency: _pickDate,
      referenceImages: _referenceImages,
      onReferenceImages: _setReferenceImages,
    ),
  ];

  List<Widget> _jewelryForm() => [
    JewelryInquiryForm(
      controller: _c,
      flag: _b,
      setFlag: _setBool,
      onChanged: _markDirty,
      urgency: _urgency,
      onPickUrgency: _pickDate,
      referenceImages: _referenceImages,
      onReferenceImages: _setReferenceImages,
    ),
  ];
}
