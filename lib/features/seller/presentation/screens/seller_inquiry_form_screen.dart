import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/router/account_nav.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/utils/price_weight_sync.dart';
import '../../application/inquiry_provider.dart';
import '../../data/mappers/inquiry_request_mapper.dart';
import '../../domain/models/seller_inquiry.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_theme.dart';
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
  final _priceSyncs = <PriceWeightSync>[];
  DateTime? _urgency;
  final List<Uint8List> _referenceImages = [];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _seedDefaults();
    _bindPriceSyncs();
  }

  /// Links min/max price-per-carat (or per piece) with min/max total price
  /// for the diamond and gemstone forms.
  void _bindPriceSyncs() {
    double? diamondWeight(String bound) {
      if (_category != InquiryCategory.diamond) return null;
      final byPieces =
          _c('subCategory').text == 'PARCEL' &&
          _c('parcelMeasure').text == 'pieces';
      return PriceWeightSync.parseAmount(
        _c(byPieces ? 'totalPieces' : 'carat$bound').text,
      );
    }

    double? gemstoneWeight(String bound) {
      if (_category != InquiryCategory.gemstone) return null;
      return PriceWeightSync.parseAmount(_c('carat$bound').text);
    }

    for (final bound in const ['Min', 'Max']) {
      _priceSyncs.addAll([
        PriceWeightSync(
          unitPrice: _c('pricePerCarat$bound'),
          total: _c('totalPrice$bound'),
          weight: () => diamondWeight(bound),
          weightSources: [
            _c('carat$bound'),
            _c('totalPieces'),
            _c('subCategory'),
            _c('parcelMeasure'),
          ],
        ),
        PriceWeightSync(
          unitPrice: _c('pricePerCarat$bound'),
          total: _c('totalBudget$bound'),
          weight: () => gemstoneWeight(bound),
          weightSources: [_c('carat$bound')],
        ),
      ]);
    }
  }

  TextEditingController _c(String key, [String initial = '']) {
    return _ctrls.putIfAbsent(key, () => TextEditingController(text: initial));
  }

  bool _b(String key, [bool initial = false]) {
    return _bools.putIfAbsent(key, () => initial);
  }

  void _markDirty([_]) => setState(() => _dirty = true);

  void _setBool(String key, bool value) {
    AppHaptics.selection();
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
    AppHaptics.selection();
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
    AppHaptics.selection();
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
      AppHaptics.error();
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
        AppHaptics.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_category!.label} inquiry sent to admin')),
        );
        final path = GoRouterState.of(context).uri.path;
        context.openRoute(
          inquiryDetailPathFor(path, _category!.name, inquiry.id),
        );
      case ResultFailure(failure: final failure):
        AppHaptics.error();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  void dispose() {
    for (final s in _priceSyncs) {
      s.dispose();
    }
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);
    final category = _category;

    return ColoredBox(
      color: p.canvas,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 18),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _centered(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Reveal(
                        index: 0,
                        child: Text(
                          context.tr(
                            RemainingL10n.chooseACategoryThenCompleteThe,
                          ),
                          style: AtelierType.body(p.inkSoft, size: 14),
                        ),
                      ),
                      const SizedBox(height: AtelierSpace.s6),
                      Reveal(
                        index: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Pressable(
                            onTap: () => context.goBack(),
                            semanticLabel: context.tr(
                              RemainingL10n.viewYourSubmittedInquiries,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.tr(
                                      RemainingL10n.viewYourSubmittedInquiries,
                                    ),
                                    style: AtelierType.title(
                                      p.gold,
                                      size: 13.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: p.gold,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AtelierSpace.s24),
                      Reveal(
                        index: 2,
                        child: _StepHeader(
                          step: 1,
                          done: category != null,
                          title: context.tr(
                            RemainingL10n.step1WhatAreYouLookingFor,
                          ),
                          subtitle: context.tr(
                            RemainingL10n.tapACategoryToLoadTheMatching,
                          ),
                        ),
                      ),
                      const SizedBox(height: AtelierSpace.s16),
                      Reveal(
                        index: 3,
                        child: InquiryCategoryPicker(
                          selected: category,
                          onSelected: (c) {
                            AppHaptics.selection();
                            setState(() {
                              _category = c;
                              _dirty = true;
                            });
                          },
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: AtelierMotion.base,
                        switchInCurve: AtelierMotion.emphasized,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.02),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: category == null
                            ? const SizedBox(
                                key: ValueKey('none'),
                                width: double.infinity,
                              )
                            : Column(
                                key: ValueKey(category),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: AtelierSpace.s32),
                                  _StepHeader(
                                    step: 2,
                                    title:
                                        '${category.label} · ${context.tr(RemainingL10n.step2Details)}',
                                  ),
                                  const SizedBox(height: AtelierSpace.s16),
                                  ..._formFor(category),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (category != null) _actionBar(context, category, gutter),
        ],
      ),
    );
  }

  Widget _centered(Widget child) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: child,
    ),
  );

  Widget _actionBar(
    BuildContext context,
    InquiryCategory category,
    double gutter,
  ) {
    final p = context.atelier;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.hairline)),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 8),
      child: SafeArea(
        top: false,
        child: _centered(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AtelierButton(
                    label: context.tr(RemainingL10n.resetForm),
                    icon: Icons.restart_alt_rounded,
                    variant: AtelierButtonVariant.secondary,
                    onPressed: _submitting ? null : _reset,
                  ),
                  const SizedBox(width: AtelierSpace.s10),
                  Expanded(
                    child: AtelierButton(
                      label: category.submitLabel,
                      icon: Icons.send_rounded,
                      variant: AtelierButtonVariant.gold,
                      expand: true,
                      loading: _submitting,
                      onPressed: _dirty ? _submit : null,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: AtelierMotion.base,
                curve: AtelierMotion.emphasized,
                child: _dirty
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: AtelierSpace.s8),
                        child: Text(
                          context.tr(
                            RemainingL10n.submitIsEnabledAfterYouMakeChanges,
                          ),
                          textAlign: TextAlign.center,
                          style: AtelierType.caption(p.muted),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
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

/// Numbered step marker: gold badge (check once done), title, subtitle.
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.title,
    this.subtitle,
    this.done = false,
  });

  final int step;
  final String title;
  final String? subtitle;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: AtelierMotion.base,
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: done ? null : p.goldGradient,
            color: done ? p.goldSoft : null,
            border: done ? Border.all(color: p.gold) : null,
          ),
          child: AnimatedSwitcher(
            duration: AtelierMotion.base,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: done
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('done'),
                    size: 15,
                    color: p.gold,
                  )
                : Text(
                    '$step',
                    key: const ValueKey('step'),
                    style: AtelierType.figure(p.onGold, size: 13),
                  ),
          ),
        ),
        const SizedBox(width: AtelierSpace.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STEP $step', style: AtelierType.overline(p.muted)),
              const SizedBox(height: 3),
              Text(title, style: AtelierType.display(p.ink, size: 22)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: AtelierType.caption(p.muted)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
