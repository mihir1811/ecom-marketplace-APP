import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'inquiry_form_fields.dart';
import 'inquiry_reference_media.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Diamond inquiry field groups for single/parcel, natural/lab, and fancy color.
class DiamondInquiryForm extends StatelessWidget {
  const DiamondInquiryForm({
    required this.controller,
    required this.flag,
    required this.setFlag,
    required this.onChanged,
    required this.urgency,
    required this.onPickUrgency,
    required this.referenceImages,
    required this.onReferenceImages,
    super.key,
  });

  final TextEditingController Function(String key, [String initial]) controller;
  final bool Function(String key, [bool initial]) flag;
  final void Function(String key, bool value) setFlag;
  final ValueChanged<String>? onChanged;
  final DateTime? urgency;
  final VoidCallback onPickUrgency;
  final List<Uint8List> referenceImages;
  final ValueChanged<List<Uint8List>> onReferenceImages;

  bool get _isParcel => controller('subCategory').text == 'PARCEL';
  bool get _isLab => controller('diamondType').text == 'LAB';
  bool get _measureCarat =>
      controller('parcelMeasure', 'carat').text != 'pieces';
  bool get _isFancy => flag('isFancyColor');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InquirySectionCard(
          title: context.tr(RemainingL10n.basicDetails),
          child: Column(
            children: [
              InquiryDropdownField(
                label: context.tr(RemainingL10n.subCategory),
                value: controller('subCategory').text,
                options: const ['SINGLE', 'PARCEL'],
                allowOther: false,
                onChanged: (v) {
                  controller('subCategory').text = v;
                  onChanged?.call(v);
                },
              ),
              InquiryDropdownField(
                label: context.tr(RemainingL10n.diamondType),
                value: controller('diamondType').text,
                options: const ['NATURAL', 'LAB'],
                allowOther: false,
                onChanged: (v) {
                  controller('diamondType').text = v;
                  onChanged?.call(v);
                },
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: context.tr(RemainingL10n.qualitySpecs),
          child: Column(
            children: [
              if (_isLab)
                InquiryDropdownField(
                  label: context.tr(RemainingL10n.growthProcess),
                  value: controller('growthProcess', 'CVD').text,
                  options: const ['CVD', 'HPHT'],
                  allowOther: false,
                  onChanged: (v) {
                    controller('growthProcess').text = v;
                    onChanged?.call(v);
                  },
                ),
              InquiryCheckboxField(
                label: context.tr(RemainingL10n.isCertified),
                value: flag('isCertified'),
                onChanged: (v) => setFlag('isCertified', v),
              ),
              if (flag('isCertified'))
                InquiryTextField(
                  label: context.tr(RemainingL10n.certificateName),
                  controller: controller('certificateName'),
                  hint: context.tr(RemainingL10n.enterCertificateNameHint),
                  onChanged: onChanged,
                ),
              InquiryTextField(
                label: context.tr(RemainingL10n.shape),
                controller: controller('shape'),
                onChanged: onChanged,
              ),
              if (_isParcel) ...[
                InquiryPairFields(
                  left: InquiryTextField(
                    label: context.tr(RemainingL10n.sieveMin),
                    controller: controller('sieveSizeMin'),
                    hint: 'e.g. +6.5',
                    onChanged: onChanged,
                  ),
                  right: InquiryTextField(
                    label: context.tr(RemainingL10n.sieveMax),
                    controller: controller('sieveSizeMax'),
                    hint: 'e.g. -8.5',
                    onChanged: onChanged,
                  ),
                ),
                InquirySegmentedField(
                  label: context.tr(RemainingL10n.parcelMeasure),
                  value: _measureCarat ? 'carat' : 'pieces',
                  options: [
                    (
                      value: 'carat',
                      label: context.tr(RemainingL10n.totalCarat),
                    ),
                    (
                      value: 'pieces',
                      label: context.tr(RemainingL10n.totalPieces),
                    ),
                  ],
                  onChanged: (v) {
                    controller('parcelMeasure').text = v;
                    onChanged?.call(v);
                  },
                ),
                Text(
                  context.tr(RemainingL10n.selectEitherTotalCaratOrTotalPieces),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                ),
                const SizedBox(height: 12),
                if (_measureCarat)
                  InquiryPairFields(
                    left: InquiryTextField(
                      label: context.tr(RemainingL10n.totalCaratMin),
                      controller: controller('caratMin'),
                      onChanged: onChanged,
                    ),
                    right: InquiryTextField(
                      label: context.tr(RemainingL10n.totalCaratMax),
                      controller: controller('caratMax'),
                      onChanged: onChanged,
                    ),
                  )
                else
                  InquiryTextField(
                    label: context.tr(RemainingL10n.totalPieces),
                    controller: controller('totalPieces'),
                    onChanged: onChanged,
                  ),
                InquiryTextField(
                  label: context.tr(RemainingL10n.caratPerPiece),
                  controller: controller('caratPerPiece'),
                  hint: '0.05',
                  onChanged: onChanged,
                ),
              ] else
                InquiryPairFields(
                  left: InquiryTextField(
                    label: context.tr(RemainingL10n.caratMin),
                    controller: controller('caratMin'),
                    onChanged: onChanged,
                  ),
                  right: InquiryTextField(
                    label: context.tr(RemainingL10n.caratMax),
                    controller: controller('caratMax'),
                    onChanged: onChanged,
                  ),
                ),
              _colorHeader(context),
              if (_isFancy)
                InquiryPairFields(
                  left: InquiryDropdownField(
                    label: context.tr(RemainingL10n.fancyColorMin),
                    value: controller('fancyColorMin', 'Yellow').text,
                    options: _fancyColors,
                    optionLabels: {
                      for (final color in _fancyColors) color: 'Fancy $color',
                    },
                    onChanged: (v) {
                      controller('fancyColorMin').text = v;
                      onChanged?.call(v);
                    },
                  ),
                  right: InquiryDropdownField(
                    label: context.tr(RemainingL10n.fancyColorMax),
                    value: controller('fancyColorMax', 'Yellow').text,
                    options: _fancyColors,
                    optionLabels: {
                      for (final color in _fancyColors) color: 'Fancy $color',
                    },
                    onChanged: (v) {
                      controller('fancyColorMax').text = v;
                      onChanged?.call(v);
                    },
                  ),
                )
              else
                InquiryPairFields(
                  left: InquiryDropdownField(
                    label: context.tr(RemainingL10n.colorMin),
                    value: controller('colorMin').text,
                    options: _colorGrades.keys.toList(),
                    optionLabels: _colorGrades,
                    onChanged: (v) {
                      controller('colorMin').text = v;
                      onChanged?.call(v);
                    },
                  ),
                  right: InquiryDropdownField(
                    label: context.tr(RemainingL10n.colorMax),
                    value: controller('colorMax').text,
                    options: _colorGrades.keys.toList(),
                    optionLabels: _colorGrades,
                    onChanged: (v) {
                      controller('colorMax').text = v;
                      onChanged?.call(v);
                    },
                  ),
                ),
              InquiryPairFields(
                left: InquiryDropdownField(
                  label: context.tr(RemainingL10n.clarityMin),
                  value: controller('clarityMin').text,
                  options: _clarities,
                  onChanged: (v) {
                    controller('clarityMin').text = v;
                    onChanged?.call(v);
                  },
                ),
                right: InquiryDropdownField(
                  label: context.tr(RemainingL10n.clarityMax),
                  value: controller('clarityMax').text,
                  options: _clarities,
                  onChanged: (v) {
                    controller('clarityMax').text = v;
                    onChanged?.call(v);
                  },
                ),
              ),
              InquiryTextField(
                label: context.tr(RemainingL10n.cutSymmetryPolish),
                controller: controller('cut'),
                hint: 'EX-VG-VG',
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: context.tr(RemainingL10n.commercial),
          child: Column(
            children: [
              InquiryCheckboxField(
                label: context.tr(RemainingL10n.bgm),
                value: flag('bgm'),
                onChanged: (v) => setFlag('bgm', v),
              ),
              InquiryTextField(
                label: context.tr(RemainingL10n.inclusionType),
                controller: controller('inclusionType'),
                onChanged: onChanged,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.floroMin),
                  controller: controller('fluorescenceIntensityMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.floroMax),
                  controller: controller('fluorescenceIntensityMax'),
                  onChanged: onChanged,
                ),
              ),
              if (!_isParcel)
                InquiryTextField(
                  label: context.tr(RemainingL10n.quantity),
                  controller: controller('quantity'),
                  onChanged: onChanged,
                ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.totalPriceMin2),
                  controller: controller('totalPriceMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.totalPriceMax2),
                  controller: controller('totalPriceMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(
                    _isParcel && !_measureCarat
                        ? RemainingL10n.pppMin
                        : RemainingL10n.ppcMin,
                  ),
                  controller: controller('pricePerCaratMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(
                    _isParcel && !_measureCarat
                        ? RemainingL10n.pppMax
                        : RemainingL10n.ppcMax,
                  ),
                  controller: controller('pricePerCaratMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryTextField(
                label: context.tr(RemainingL10n.paymentTerms2),
                controller: controller('paymentTerms'),
                onChanged: onChanged,
              ),
              InquiryTextField(
                label: context.tr(RemainingL10n.remarks),
                controller: controller('remarks'),
                maxLines: 3,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: context.tr(RemainingL10n.dimensions),
          child: Column(
            children: [
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.lengthMin2),
                  controller: controller('lengthMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.lengthMax2),
                  controller: controller('lengthMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.widthMin2),
                  controller: controller('widthMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.widthMax2),
                  controller: controller('widthMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.heightMin2),
                  controller: controller('heightMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.heightMax2),
                  controller: controller('heightMax'),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: context.tr(RemainingL10n.logistics),
          child: Column(
            children: [
              InquiryDateField(
                label: context.tr(RemainingL10n.urgency),
                value: urgency,
                onPick: onPickUrgency,
              ),
              InquiryTextField(
                label: context.tr(RemainingL10n.deliveryAddress2),
                controller: controller('deliveryLocation'),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        InquiryReferenceMedia(
          controller: controller,
          onChanged: onChanged,
          referenceImages: referenceImages,
          onReferenceImages: onReferenceImages,
        ),
      ],
    );
  }

  Widget _colorHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            context.tr(RemainingL10n.color),
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 156,
            child: InquirySegmentedField(
              value: _isFancy ? 'fancy' : 'standard',
              options: [
                (value: 'standard', label: context.tr(RemainingL10n.standard)),
                (value: 'fancy', label: context.tr(RemainingL10n.fancy)),
              ],
              onChanged: (v) => setFlag('isFancyColor', v == 'fancy'),
            ),
          ),
        ],
      ),
    );
  }

  static final _clarities = [
    'FL',
    'IF',
    'VVS1',
    'VVS2',
    'VS1',
    'VS2',
    'SI1',
    'SI2',
    'SI3',
    'I1',
    'I2',
    'I3',
  ];

  static const _fancyColors = [
    'Yellow',
    'Orange',
    'Blue',
    'Red',
    'Pink',
    'Green',
    'Olive',
    'Brown',
    'Purple',
    'Violet',
    'Grey',
    'Black',
    'Multi',
  ];

  static const _colorGrades = {
    'D': 'D (Colorless)',
    'E': 'E (Colorless)',
    'F': 'F (Colorless)',
    'G': 'G (Near colorless)',
    'H': 'H (Near colorless)',
    'I': 'I (Near colorless)',
    'J': 'J (Near colorless)',
    'K': 'K (Faint)',
    'L': 'L (Faint)',
    'M': 'M (Faint)',
    'N': 'N (Very light)',
    'O': 'O (Very light)',
    'P': 'P (Very light)',
    'Q': 'Q (Very light)',
    'R': 'R (Very light)',
    'S': 'S (Light)',
    'T': 'T (Light)',
    'U': 'U (Light)',
    'V': 'V (Light)',
    'W': 'W (Light)',
    'X': 'X (Light)',
    'Y': 'Y (Light)',
    'Z': 'Z (Light)',
  };
}
