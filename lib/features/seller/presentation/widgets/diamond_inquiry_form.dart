import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'inquiry_form_fields.dart';
import 'inquiry_reference_media.dart';

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
          title: 'Basic details',
          child: Column(
            children: [
              InquiryDropdownField(
                label: 'Sub category',
                value: controller('subCategory').text,
                options: const ['SINGLE', 'PARCEL'],
                allowOther: false,
                onChanged: (v) {
                  controller('subCategory').text = v;
                  onChanged?.call(v);
                },
              ),
              InquiryDropdownField(
                label: 'Diamond type',
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
          title: 'Quality & specs',
          child: Column(
            children: [
              if (_isLab)
                InquiryDropdownField(
                  label: 'Growth process',
                  value: controller('growthProcess', 'CVD').text,
                  options: const ['CVD', 'HPHT'],
                  allowOther: false,
                  onChanged: (v) {
                    controller('growthProcess').text = v;
                    onChanged?.call(v);
                  },
                ),
              InquiryCheckboxField(
                label: 'Is certified',
                value: flag('isCertified'),
                onChanged: (v) => setFlag('isCertified', v),
              ),
              if (flag('isCertified'))
                InquiryTextField(
                  label: 'Certificate name',
                  controller: controller('certificateName'),
                  hint: 'Enter certificate name (e.g. GIA)',
                  onChanged: onChanged,
                ),
              InquiryTextField(
                label: 'Shape',
                controller: controller('shape'),
                onChanged: onChanged,
              ),
              if (_isParcel) ...[
                InquiryPairFields(
                  left: InquiryTextField(
                    label: 'Sieve min.',
                    controller: controller('sieveSizeMin'),
                    hint: 'e.g. +6.5',
                    onChanged: onChanged,
                  ),
                  right: InquiryTextField(
                    label: 'Sieve max.',
                    controller: controller('sieveSizeMax'),
                    hint: 'e.g. -8.5',
                    onChanged: onChanged,
                  ),
                ),
                InquirySegmentedField(
                  label: 'Parcel measure',
                  value: _measureCarat ? 'carat' : 'pieces',
                  options: const [
                    (value: 'carat', label: 'Total carat'),
                    (value: 'pieces', label: 'Total pieces'),
                  ],
                  onChanged: (v) {
                    controller('parcelMeasure').text = v;
                    onChanged?.call(v);
                  },
                ),
                Text(
                  'Select either total carat or total pieces — not both.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                ),
                const SizedBox(height: 12),
                if (_measureCarat)
                  InquiryPairFields(
                    left: InquiryTextField(
                      label: 'Total carat min.',
                      controller: controller('caratMin'),
                      onChanged: onChanged,
                    ),
                    right: InquiryTextField(
                      label: 'Total carat max.',
                      controller: controller('caratMax'),
                      onChanged: onChanged,
                    ),
                  )
                else
                  InquiryTextField(
                    label: 'Total pieces',
                    controller: controller('totalPieces'),
                    onChanged: onChanged,
                  ),
                InquiryTextField(
                  label: 'Carat per piece',
                  controller: controller('caratPerPiece'),
                  hint: '0.05',
                  onChanged: onChanged,
                ),
              ] else
                InquiryPairFields(
                  left: InquiryTextField(
                    label: 'Carat min.',
                    controller: controller('caratMin'),
                    onChanged: onChanged,
                  ),
                  right: InquiryTextField(
                    label: 'Carat max.',
                    controller: controller('caratMax'),
                    onChanged: onChanged,
                  ),
                ),
              _colorHeader(context),
              if (_isFancy)
                InquiryPairFields(
                  left: InquiryDropdownField(
                    label: 'Fancy clr. min.',
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
                    label: 'Fancy clr. max.',
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
                    label: 'Color min.',
                    value: controller('colorMin').text,
                    options: _colorGrades.keys.toList(),
                    optionLabels: _colorGrades,
                    onChanged: (v) {
                      controller('colorMin').text = v;
                      onChanged?.call(v);
                    },
                  ),
                  right: InquiryDropdownField(
                    label: 'Color max.',
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
                  label: 'Clarity min.',
                  value: controller('clarityMin').text,
                  options: _clarities,
                  onChanged: (v) {
                    controller('clarityMin').text = v;
                    onChanged?.call(v);
                  },
                ),
                right: InquiryDropdownField(
                  label: 'Clarity max.',
                  value: controller('clarityMax').text,
                  options: _clarities,
                  onChanged: (v) {
                    controller('clarityMax').text = v;
                    onChanged?.call(v);
                  },
                ),
              ),
              InquiryTextField(
                label: 'Cut – symmetry – polish',
                controller: controller('cut'),
                hint: 'EX-VG-VG',
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Commercial',
          child: Column(
            children: [
              InquiryCheckboxField(
                label: 'BGM',
                value: flag('bgm'),
                onChanged: (v) => setFlag('bgm', v),
              ),
              InquiryTextField(
                label: 'Inclusion type',
                controller: controller('inclusionType'),
                onChanged: onChanged,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Floro. min.',
                  controller: controller('fluorescenceIntensityMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Floro. max.',
                  controller: controller('fluorescenceIntensityMax'),
                  onChanged: onChanged,
                ),
              ),
              if (!_isParcel)
                InquiryTextField(
                  label: 'Quantity',
                  controller: controller('quantity'),
                  onChanged: onChanged,
                ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Total price min.',
                  controller: controller('totalPriceMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Total price max.',
                  controller: controller('totalPriceMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Ppc min.',
                  controller: controller('pricePerCaratMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Ppc max.',
                  controller: controller('pricePerCaratMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryTextField(
                label: 'Payment terms',
                controller: controller('paymentTerms'),
                onChanged: onChanged,
              ),
              InquiryTextField(
                label: 'Remarks',
                controller: controller('remarks'),
                maxLines: 3,
                onChanged: onChanged,
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
                  label: 'Length min.',
                  controller: controller('lengthMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Length max.',
                  controller: controller('lengthMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Width min.',
                  controller: controller('widthMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Width max.',
                  controller: controller('widthMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Height min.',
                  controller: controller('heightMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Height max.',
                  controller: controller('heightMax'),
                  onChanged: onChanged,
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
                label: 'Urgency',
                value: urgency,
                onPick: onPickUrgency,
              ),
              InquiryTextField(
                label: 'Delivery address',
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
            'Color',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 156,
            child: InquirySegmentedField(
              value: _isFancy ? 'fancy' : 'standard',
              selectedColor: _isFancy
                  ? AppColors.bronze
                  : AppColors.selectedFill(context),
              options: const [
                (value: 'standard', label: 'Standard'),
                (value: 'fancy', label: 'Fancy'),
              ],
              onChanged: (v) => setFlag('isFancyColor', v == 'fancy'),
            ),
          ),
        ],
      ),
    );
  }

  static const _clarities = [
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
