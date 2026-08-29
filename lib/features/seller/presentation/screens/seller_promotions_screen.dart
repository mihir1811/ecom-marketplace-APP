import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../promotions/application/promotions_providers.dart';
import '../../../promotions/domain/models/promotion.dart';

enum _PromoTab { discounts, promoCodes }

class SellerPromotionsScreen extends ConsumerStatefulWidget {
  const SellerPromotionsScreen({super.key});

  @override
  ConsumerState<SellerPromotionsScreen> createState() =>
      _SellerPromotionsScreenState();
}

class _SellerPromotionsScreenState extends ConsumerState<SellerPromotionsScreen> {
  _PromoTab _tab = _PromoTab.discounts;

  Future<void> _openAddDiscount() async {
    if (!AccountAccess.guard(context, ref)) return;
    await showAppDialog<void>(
      context: context,
      builder: (context) => _AddDiscountDialog(
        onSave: (input) async {
          final result =
              await ref.read(sellerPromotionsProvider.notifier).createDiscount(input);
          if (!context.mounted) return;
          switch (result) {
            case Success():
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Discount created')),
              );
            case ResultFailure(:final failure):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(failure.message)),
              );
          }
        },
      ),
    );
  }

  Future<void> _openAddPromoCode() async {
    if (!AccountAccess.guard(context, ref)) return;
    await showAppDialog<void>(
      context: context,
      builder: (context) => _AddPromoCodeDialog(
        onSave: (input) async {
          final result =
              await ref.read(sellerPromotionsProvider.notifier).createPromoCode(input);
          if (!context.mounted) return;
          switch (result) {
            case Success():
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Promo code created')),
              );
            case ResultFailure(:final failure):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(failure.message)),
              );
          }
        },
      ),
    );
  }

  Future<void> _deleteDiscount(String id) async {
    final result =
        await ref.read(sellerPromotionsProvider.notifier).deleteDiscount(id);
    if (!mounted) return;
    if (result case ResultFailure(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    }
  }

  Future<void> _deletePromoCode(String id) async {
    final result =
        await ref.read(sellerPromotionsProvider.notifier).deletePromoCode(id);
    if (!mounted) return;
    if (result case ResultFailure(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerPromotionsProvider);
    final isDiscounts = _tab == _PromoTab.discounts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isLoading || state.isMutating)
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              state.errorMessage!,
              style: AppTypography.caption.copyWith(color: AppColors.error),
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
                color: AppColors.card(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.border(context)),
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
                            onPressed: state.isMutating
                                ? null
                                : isDiscounts
                                    ? _openAddDiscount
                                    : _openAddPromoCode,
                            child: Text(
                              isDiscounts ? 'Add Discount' : 'Add Promo Code',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (state.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (isDiscounts)
                        if (state.discounts.isEmpty)
                          const _EmptyState(label: 'No discounts found.')
                        else
                          for (final d in state.discounts) ...[
                            _DiscountTile(
                              item: d,
                              onDelete: () => _deleteDiscount(d.id),
                            ),
                            const SizedBox(height: 10),
                          ]
                      else if (state.promoCodes.isEmpty)
                        const _EmptyState(label: 'No promo codes found.')
                      else
                        for (final p in state.promoCodes) ...[
                          _PromoTile(
                            item: p,
                            onDelete: () => _deletePromoCode(p.id),
                          ),
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
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary(context),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: AppColors.textPrimary(context),
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
          style: AppTypography.body.copyWith(
            color: AppColors.textMuted(context),
          ),
        ),
      ),
    );
  }
}

class _DiscountTile extends StatelessWidget {
  const _DiscountTile({required this.item, required this.onDelete});

  final Discount item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.label
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  item.description,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary(context)),
                ),
                Text(
                  '${item.type == PromotionType.percentage ? '${item.value}%' : AppCurrency.format(item.value)} · ${item.startDateLabel} → ${item.endDateLabel}',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textMuted(context)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
    );
  }
}

class _PromoTile extends StatelessWidget {
  const _PromoTile({required this.item, required this.onDelete});

  final PromoCode item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.code,
                  style: AppTypography.label
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  item.description,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary(context)),
                ),
                Text(
                  '${item.type == PromotionType.percentage ? '${item.value}%' : AppCurrency.format(item.value)}'
                  '${item.maxUses != null ? ' · Max ${item.maxUses}' : ''} · ${item.startDateLabel} → ${item.endDateLabel}',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textMuted(context)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
    );
  }
}

typedef _DiscountSave = Future<void> Function(DiscountInput input);
typedef _PromoCodeSave = Future<void> Function(PromoCodeInput input);

class _AddDiscountDialog extends StatefulWidget {
  const _AddDiscountDialog({required this.onSave});

  final _DiscountSave onSave;

  @override
  State<_AddDiscountDialog> createState() => _AddDiscountDialogState();
}

class _AddDiscountDialogState extends State<_AddDiscountDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valueCtrl = TextEditingController(text: '10');
  PromotionType _type = PromotionType.percentage;
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;

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

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _valueCtrl.text.trim().isEmpty ||
        _start == null ||
        _end == null) {
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(
      DiscountInput(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        type: _type,
        value: num.tryParse(_valueCtrl.text.trim()) ?? 0,
        startDate: _start!,
        endDate: _end!,
      ),
    );
    if (mounted) setState(() => _saving = false);
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
                    decoration: _inputDecoration(context, 'e.g., Summer Sale'),
                  ),
                ),
                _LabeledField(
                  label: 'Description',
                  child: TextField(
                    controller: _descCtrl,
                    decoration: _inputDecoration(context, 'Description'),
                  ),
                ),
                _LabeledField(
                  label: 'Discount Type',
                  child: DropdownButtonFormField<PromotionType>(
                    initialValue: _type,
                    items: const [
                      DropdownMenuItem(
                        value: PromotionType.percentage,
                        child: Text('Percentage (%)'),
                      ),
                      DropdownMenuItem(
                        value: PromotionType.fixedAmount,
                        child: Text('Fixed amount'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _type = v);
                    },
                    decoration: _inputDecoration(context, ''),
                  ),
                ),
                _LabeledField(
                  label: 'Value',
                  child: TextField(
                    controller: _valueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(context, '10'),
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
                            decoration: _inputDecoration(context, 'mm/dd/yyyy').copyWith(
                              suffixIcon:
                                  const Icon(Icons.calendar_today, size: 18),
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
                            decoration: _inputDecoration(context, 'mm/dd/yyyy').copyWith(
                              suffixIcon:
                                  const Icon(Icons.calendar_today, size: 18),
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
                  onPressed: _saving ? null : _save,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Discount'),
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
  const _AddPromoCodeDialog({required this.onSave});

  final _PromoCodeSave onSave;

  @override
  State<_AddPromoCodeDialog> createState() => _AddPromoCodeDialogState();
}

class _AddPromoCodeDialogState extends State<_AddPromoCodeDialog> {
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valueCtrl = TextEditingController(text: '20');
  final _maxUsesCtrl = TextEditingController(text: '100');
  PromotionType _type = PromotionType.percentage;
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;

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

  Future<void> _save() async {
    if (_codeCtrl.text.trim().isEmpty ||
        _valueCtrl.text.trim().isEmpty ||
        _start == null ||
        _end == null) {
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(
      PromoCodeInput(
        code: _codeCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        type: _type,
        value: num.tryParse(_valueCtrl.text.trim()) ?? 0,
        startDate: _start!,
        endDate: _end!,
        maxUses: int.tryParse(_maxUsesCtrl.text.trim()),
      ),
    );
    if (mounted) setState(() => _saving = false);
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
                    decoration: _inputDecoration(context, 'e.g., SUMMER20'),
                  ),
                ),
                _LabeledField(
                  label: 'Description',
                  child: TextField(
                    controller: _descCtrl,
                    decoration: _inputDecoration(context, 'Description'),
                  ),
                ),
                _LabeledField(
                  label: 'Discount Type',
                  child: DropdownButtonFormField<PromotionType>(
                    initialValue: _type,
                    items: const [
                      DropdownMenuItem(
                        value: PromotionType.percentage,
                        child: Text('Percentage (%)'),
                      ),
                      DropdownMenuItem(
                        value: PromotionType.fixedAmount,
                        child: Text('Fixed amount'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _type = v);
                    },
                    decoration: _inputDecoration(context, ''),
                  ),
                ),
                _LabeledField(
                  label: 'Value',
                  child: TextField(
                    controller: _valueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(context, '20'),
                  ),
                ),
                _LabeledField(
                  label: 'Max Uses (Optional)',
                  child: TextField(
                    controller: _maxUsesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(context, '100'),
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
                            decoration: _inputDecoration(context, 'mm/dd/yyyy').copyWith(
                              suffixIcon:
                                  const Icon(Icons.calendar_today, size: 18),
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
                            decoration: _inputDecoration(context, 'mm/dd/yyyy').copyWith(
                              suffixIcon:
                                  const Icon(Icons.calendar_today, size: 18),
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
                  onPressed: _saving ? null : _save,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Promo Code'),
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
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(BuildContext context, String hint) {
  final borderSide = BorderSide(color: AppColors.border(context));
  return InputDecoration(
    hintText: hint.isEmpty ? null : hint,
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: borderSide,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: borderSide,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}
