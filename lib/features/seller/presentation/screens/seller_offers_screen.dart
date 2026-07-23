import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/seller_orders_mock_data.dart';
import '../../domain/models/seller_orders_models.dart';
import '../widgets/seller_layout.dart';

class SellerOffersScreen extends StatefulWidget {
  const SellerOffersScreen({super.key});

  @override
  State<SellerOffersScreen> createState() => _SellerOffersScreenState();
}

class _SellerOffersScreenState extends State<SellerOffersScreen> {
  SellerOfferStatus? _filter;
  late final List<SellerOffer> _offers;

  @override
  void initState() {
    super.initState();
    _offers = List<SellerOffer>.from(kSellerOffersMock);
  }

  List<SellerOffer> get _visible {
    if (_filter == null) return _offers;
    return _offers.where((o) => o.status == _filter).toList();
  }

  void _updateOffer(String id, SellerOffer Function(SellerOffer) transform) {
    setState(() {
      final i = _offers.indexWhere((o) => o.id == id);
      if (i >= 0) _offers[i] = transform(_offers[i]);
    });
  }

  Future<void> _counterOffer(SellerOffer offer) async {
    final controller = TextEditingController(
      text: offer.offerPrice.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Counter offer'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Your price (USD)',
            prefixText: r'$',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.r8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.charcoal),
            onPressed: () {
              final raw = controller.text.trim();
              if (raw.isEmpty) return;
              Navigator.pop(context, raw);
            },
            child: const Text('Send counter'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    final formatted = result.startsWith(r'$') ? result : '\$$result';
    _updateOffer(
      offer.id,
      (o) => o.copyWith(
        status: SellerOfferStatus.countered,
        counterPrice: formatted,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Counter sent at $formatted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;

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
              Expanded(
                child: Text(
                  'Offers',
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.sandSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.local_offer_outlined,
                        size: 56,
                        color: AppColors.textMutedLight.withValues(alpha: 0.25),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmWhite,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.warmBorder),
                          ),
                          child: Text(
                            'Seller · Offers',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Review buyer price offers on your listings. Accept, '
                          'reject, or send a counter to keep the deal moving.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  _FilterChip(
                    label: 'Pending',
                    selected: _filter == SellerOfferStatus.pending,
                    onTap: () =>
                        setState(() => _filter = SellerOfferStatus.pending),
                  ),
                  _FilterChip(
                    label: 'Accepted',
                    selected: _filter == SellerOfferStatus.accepted,
                    onTap: () =>
                        setState(() => _filter = SellerOfferStatus.accepted),
                  ),
                  _FilterChip(
                    label: 'Countered',
                    selected: _filter == SellerOfferStatus.countered,
                    onTap: () =>
                        setState(() => _filter = SellerOfferStatus.countered),
                  ),
                  _FilterChip(
                    label: 'Rejected',
                    selected: _filter == SellerOfferStatus.rejected,
                    onTap: () =>
                        setState(() => _filter = SellerOfferStatus.rejected),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final offer in items) ...[
                _OfferCard(
                  offer: offer,
                  onAccept: () {
                    _updateOffer(
                      offer.id,
                      (o) => o.copyWith(status: SellerOfferStatus.accepted),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Offer accepted')),
                    );
                  },
                  onReject: () {
                    _updateOffer(
                      offer.id,
                      (o) => o.copyWith(status: SellerOfferStatus.rejected),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Offer rejected')),
                    );
                  },
                  onCounter: () => _counterOffer(offer),
                ),
                const SizedBox(height: 12),
              ],
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'No offers in this filter.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textMutedLight,
                      ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.info : AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? AppColors.info : AppColors.warmBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.warmWhite : AppColors.charcoal,
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.onAccept,
    required this.onReject,
    required this.onCounter,
  });

  final SellerOffer offer;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onCounter;

  String get _statusLabel => switch (offer.status) {
        SellerOfferStatus.pending => 'Pending',
        SellerOfferStatus.accepted => 'Accepted',
        SellerOfferStatus.rejected => 'Rejected',
        SellerOfferStatus.countered => 'Countered',
      };

  Color get _statusColor => switch (offer.status) {
        SellerOfferStatus.pending => AppColors.info,
        SellerOfferStatus.accepted => AppColors.success,
        SellerOfferStatus.rejected => AppColors.error,
        SellerOfferStatus.countered => AppColors.bronzeDark,
      };

  @override
  Widget build(BuildContext context) {
    final isPending = offer.status == SellerOfferStatus.pending;

    return Material(
      color: AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.warmBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Pill(label: offer.category),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel,
                    style: AppTypography.caption.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  offer.createdAt,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              offer.productLabel,
              style: AppTypography.title.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Stock ${offer.stockNumber}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PriceBlock(
                    label: 'List price',
                    value: offer.listPrice,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PriceBlock(
                    label: 'Buyer offer',
                    value: offer.offerPrice,
                    emphasize: true,
                  ),
                ),
                if (offer.counterPrice != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PriceBlock(
                      label: 'Your counter',
                      value: offer.counterPrice!,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${offer.buyer} · ${offer.buyerEmail}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            if (offer.message != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sandSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  offer.message!,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondaryLight,
                    height: 1.35,
                  ),
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCounter,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.charcoal,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Counter'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.charcoal,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sandSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMutedLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w800,
            color: emphasize ? AppColors.info : AppColors.charcoal,
            fontSize: emphasize ? 18 : 16,
          ),
        ),
      ],
    );
  }
}
