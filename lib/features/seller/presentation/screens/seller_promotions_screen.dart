import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/seller_layout.dart';

enum _PromoTab { discounts, promoCodes }

enum _DiscountType { percentage, fixed }

class _DiscountItem {
  const _DiscountItem({
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    required this.startDate,
    required this.endDate,
  });

  final String name;
  final String description;
  final _DiscountType type;
  final String value;
  final String startDate;
  final String endDate;
}

class _PromoCodeItem {
  const _PromoCodeItem({
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    required this.startDate,
    required this.endDate,
    this.maxUses,
  });

  final String code;
  final String description;
  final _DiscountType type;
  final String value;
  final String startDate;
  final String endDate;
  final String? maxUses;
}

class SellerPromotionsScreen extends StatefulWidget {
  const SellerPromotionsScreen({super.key});

  @override
  State<SellerPromotionsScreen> createState() => _SellerPromotionsScreenState();
}

class _SellerPromotionsScreenState extends State<SellerPromotionsScreen> {
  _PromoTab _tab = _PromoTab.discounts;
  final _discounts = <_DiscountItem>[];
  final _promoCodes = <_PromoCodeItem>[];

  Future<void> _openAddDiscount() async {
    final result = await showDialog<_DiscountItem>(
      context: context,
      builder: (context) => const _AddDiscountDialog(),
    );
    if (result != null) {
      setState(() => _discounts.add(result));
    }
  }

  Future<void> _openAddPromoCode() async {
    final result = await showDialog<_PromoCodeItem>(
      context: context,
      builder: (context) => const _AddPromoCodeDialog(),
    );
    if (result != null) {
      setState(() => _promoCodes.add(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDiscounts = _tab == _PromoTab.discounts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => openSellerDrawer(context),
                icon: const Icon(Icons.menu),
              ),
              Text(
                'Promotions Management',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _TabButton(
                label: 'Discounts',
                selected: isDiscounts,
                onTap: () => setState(() => _tab = _PromoTab.discounts),
              ),
              const SizedBox(width: 16),
              _TabButton(
                label: 'Promo Codes',
                selected: !isDiscounts,
                onTap: () => setState(() => _tab = _PromoTab.promoCodes),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              Material(
                color: AppColors.warmWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.warmBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isDiscounts ? 'Active Discounts' : 'Promo Codes',
                              style: AppTypography.title.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: isDiscounts
                                ? _openAddDiscount
                                : _openAddPromoCode,
                            child: Text(
                              isDiscounts ? 'Add Discount' : 'Add Promo Code',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (isDiscounts)
                        if (_discounts.isEmpty)
                          const _EmptyState(label: 'No discounts found.')
                        else
                          for (final d in _discounts) ...[
                            _DiscountTile(item: d),
                            const SizedBox(height: 10),
                          ]
                      else if (_promoCodes.isEmpty)
                        const _EmptyState(label: 'No promo codes found.')
                      else
                        for (final p in _promoCodes) ...[
                          _PromoTile(item: p),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.info,
          foregroundColor: AppColors.warmWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      );
    }
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: AppColors.charcoal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          label,
          style: AppTypography.body.copyWith(color: AppColors.textMutedLight),
        ),
      ),
    );
  }
}

class _DiscountTile extends StatelessWidget {
  const _DiscountTile({required this.item});

  final _DiscountItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sandSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: AppTypography.label.copyWith(fontWeight: FontWeight.w700)),
          Text(item.description, style: AppTypography.caption.copyWith(color: AppColors.textSecondaryLight)),
          Text(
            '${item.type == _DiscountType.percentage ? '${item.value}%' : '₹${item.value}'} · ${item.startDate} → ${item.endDate}',
            style: AppTypography.caption.copyWith(color: AppColors.textMutedLight),
          ),
        ],
      ),
    );
  }
}

class _PromoTile extends StatelessWidget {
  const _PromoTile({required this.item});

  final _PromoCodeItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sandSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.code, style: AppTypography.label.copyWith(fontWeight: FontWeight.w700)),
          Text(item.description, style: AppTypography.caption.copyWith(color: AppColors.textSecondaryLight)),
          Text(
            '${item.type == _DiscountType.percentage ? '${item.value}%' : '₹${item.value}'}'
            '${item.maxUses != null ? ' · Max ${item.maxUses}' : ''} · ${item.startDate} → ${item.endDate}',
            style: AppTypography.caption.copyWith(color: AppColors.textMutedLight),
          ),
        ],
      ),
    );
  }
}

class _AddDiscountDialog extends StatefulWidget {
  const _AddDiscountDialog();

  @override
  State<_AddDiscountDialog> createState() => _AddDiscountDialogState();
}

class _AddDiscountDialogState extends State<_AddDiscountDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valueCtrl = TextEditingController(text: '10');
  _DiscountType _type = _DiscountType.percentage;
  DateTime? _start;
  DateTime? _end;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'mm/dd/yyyy';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.month)}/${two(d.day)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add Discount',
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _LabeledField(
                  label: 'Discount Name',
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: _inputDecoration('e.g., Summer Sale'),
                  ),
                ),
                _LabeledField(
                  label: 'Description',
                  child: TextField(
                    controller: _descCtrl,
                    decoration: _inputDecoration('Description'),
                  ),
                ),
                _LabeledField(
                  label: 'Discount Type',
                  child: DropdownButtonFormField<_DiscountType>(
                    initialValue: _type,
                    items: const [
                      DropdownMenuItem(
                        value: _DiscountType.percentage,
                        child: Text('Percentage (%)'),
                      ),
                      DropdownMenuItem(
                        value: _DiscountType.fixed,
                        child: Text('Fixed amount'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _type = v);
                    },
                    decoration: _inputDecoration(''),
                  ),
                ),
                _LabeledField(
                  label: 'Value',
                  child: TextField(
                    controller: _valueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('10'),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Start Date',
                        child: InkWell(
                          onTap: () => _pickDate(isStart: true),
                          child: InputDecorator(
                            decoration: _inputDecoration('mm/dd/yyyy').copyWith(
                              suffixIcon: const Icon(Icons.calendar_today, size: 18),
                            ),
                            child: Text(_fmt(_start)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledField(
                        label: 'End Date',
                        child: InkWell(
                          onTap: () => _pickDate(isStart: false),
                          child: InputDecorator(
                            decoration: _inputDecoration('mm/dd/yyyy').copyWith(
                              suffixIcon: const Icon(Icons.calendar_today, size: 18),
                            ),
                            child: Text(_fmt(_end)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    if (_nameCtrl.text.trim().isEmpty ||
                        _valueCtrl.text.trim().isEmpty ||
                        _start == null ||
                        _end == null) {
                      return;
                    }
                    Navigator.pop(
                      context,
                      _DiscountItem(
                        name: _nameCtrl.text.trim(),
                        description: _descCtrl.text.trim(),
                        type: _type,
                        value: _valueCtrl.text.trim(),
                        startDate: _fmt(_start),
                        endDate: _fmt(_end),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Save Discount'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPromoCodeDialog extends StatefulWidget {
  const _AddPromoCodeDialog();

  @override
  State<_AddPromoCodeDialog> createState() => _AddPromoCodeDialogState();
}

class _AddPromoCodeDialogState extends State<_AddPromoCodeDialog> {
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valueCtrl = TextEditingController(text: '20');
  final _maxUsesCtrl = TextEditingController(text: '100');
  _DiscountType _type = _DiscountType.percentage;
  DateTime? _start;
  DateTime? _end;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'mm/dd/yyyy';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.month)}/${two(d.day)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add Promo Code',
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _LabeledField(
                  label: 'Promo Code',
                  child: TextField(
                    controller: _codeCtrl,
                    decoration: _inputDecoration('e.g., SUMMER20'),
                  ),
                ),
                _LabeledField(
                  label: 'Description',
                  child: TextField(
                    controller: _descCtrl,
                    decoration: _inputDecoration('Description'),
                  ),
                ),
                _LabeledField(
                  label: 'Discount Type',
                  child: DropdownButtonFormField<_DiscountType>(
                    initialValue: _type,
                    items: const [
                      DropdownMenuItem(
                        value: _DiscountType.percentage,
                        child: Text('Percentage (%)'),
                      ),
                      DropdownMenuItem(
                        value: _DiscountType.fixed,
                        child: Text('Fixed amount'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _type = v);
                    },
                    decoration: _inputDecoration(''),
                  ),
                ),
                _LabeledField(
                  label: 'Value',
                  child: TextField(
                    controller: _valueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('20'),
                  ),
                ),
                _LabeledField(
                  label: 'Max Uses (Optional)',
                  child: TextField(
                    controller: _maxUsesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('100'),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Start Date',
                        child: InkWell(
                          onTap: () => _pickDate(isStart: true),
                          child: InputDecorator(
                            decoration: _inputDecoration('mm/dd/yyyy').copyWith(
                              suffixIcon: const Icon(Icons.calendar_today, size: 18),
                            ),
                            child: Text(_fmt(_start)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledField(
                        label: 'End Date',
                        child: InkWell(
                          onTap: () => _pickDate(isStart: false),
                          child: InputDecorator(
                            decoration: _inputDecoration('mm/dd/yyyy').copyWith(
                              suffixIcon: const Icon(Icons.calendar_today, size: 18),
                            ),
                            child: Text(_fmt(_end)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    if (_codeCtrl.text.trim().isEmpty ||
                        _valueCtrl.text.trim().isEmpty ||
                        _start == null ||
                        _end == null) {
                      return;
                    }
                    Navigator.pop(
                      context,
                      _PromoCodeItem(
                        code: _codeCtrl.text.trim(),
                        description: _descCtrl.text.trim(),
                        type: _type,
                        value: _valueCtrl.text.trim(),
                        maxUses: _maxUsesCtrl.text.trim().isEmpty
                            ? null
                            : _maxUsesCtrl.text.trim(),
                        startDate: _fmt(_start),
                        endDate: _fmt(_end),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Save Promo Code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint.isEmpty ? null : hint,
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.warmBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.warmBorder),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}
