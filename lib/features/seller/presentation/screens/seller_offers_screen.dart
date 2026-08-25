import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../product_offer/application/product_offer_providers.dart';
import '../../../product_offer/data/mappers/product_offer_mapper.dart';
import '../../../product_offer/domain/models/product_offer.dart';
import '../widgets/seller_layout.dart';

class SellerOffersScreen extends ConsumerStatefulWidget {
  const SellerOffersScreen({super.key});

  @override
  ConsumerState<SellerOffersScreen> createState() => _SellerOffersScreenState();
}

class _SellerOffersScreenState extends ConsumerState<SellerOffersScreen> {
  ProductOfferStatus? _filter;

  String? get _statusFilter => switch (_filter) {
        ProductOfferStatus.pending => 'PENDING',
        ProductOfferStatus.accepted => 'ACCEPTED',
        ProductOfferStatus.rejected => 'REJECTED',
        ProductOfferStatus.expired => 'EXPIRED',
        null => null,
      };

  List<ProductOffer> _visible(List<ProductOffer> items) {
    if (_filter == null) return items;
    return items.where((o) => o.status == _filter).toList();
  }

  Future<void> _applyFilter(ProductOfferStatus? filter) async {
    setState(() => _filter = filter);
    await ref
        .read(sellerOfferListProvider.notifier)
        .refresh(statusFilter: _statusFilter);
  }

  Future<void> _respond(ProductOffer offer, ProductOfferStatus status) async {
    final result = await ref.read(sellerOfferListProvider.notifier).respond(
          id: offer.id,
          status: status,
        );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success():
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              status == ProductOfferStatus.accepted
                  ? 'Offer accepted'
                  : 'Offer rejected',
            ),
          ),
        );
      case ResultFailure(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerOfferListProvider);
    final items = _visible(state.items);

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
              if (state.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    state.errorMessage!,
                    style: AppTypography.caption.copyWith(color: AppColors.error),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Review buyer price offers on your listings. Accept or reject '
                  'to keep the deal moving.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
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
                    onTap: () => _applyFilter(null),
                  ),
                  _FilterChip(
                    label: 'Pending',
                    selected: _filter == ProductOfferStatus.pending,
                    onTap: () => _applyFilter(ProductOfferStatus.pending),
                  ),
                  _FilterChip(
                    label: 'Accepted',
                    selected: _filter == ProductOfferStatus.accepted,
                    onTap: () => _applyFilter(ProductOfferStatus.accepted),
                  ),
                  _FilterChip(
                    label: 'Rejected',
                    selected: _filter == ProductOfferStatus.rejected,
                    onTap: () => _applyFilter(ProductOfferStatus.rejected),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.isLoading && items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (final offer in items) ...[
                  _OfferCard(
                    offer: offer,
                    onAccept: () =>
                        _respond(offer, ProductOfferStatus.accepted),
                    onReject: () =>
                        _respond(offer, ProductOfferStatus.rejected),
                  ),
                  const SizedBox(height: 12),
                ],
              if (!state.isLoading && items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'No offers in this filter.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textMuted(context),
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
      color: selected ? AppColors.info : AppColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? AppColors.info : AppColors.border(context),
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
              color: selected
                  ? AppColors.warmWhite
                  : AppColors.textPrimary(context),
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
  });

  final ProductOffer offer;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  Color _statusColor(BuildContext context) => switch (offer.status) {
        ProductOfferStatus.pending => AppColors.info,
        ProductOfferStatus.accepted => AppColors.success,
        ProductOfferStatus.rejected => AppColors.error,
        ProductOfferStatus.expired => AppColors.textMuted(context),
      };

  @override
  Widget build(BuildContext context) {
    final isPending = offer.status.isPending;
    final productLabel =
        offer.productLabel ?? offer.productType;
    final listPrice = offer.listPrice;
    final statusColor = _statusColor(context);

    return Material(
      color: AppColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Pill(label: offer.productType),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    offer.status.label,
                    style: AppTypography.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  offer.createdAtLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              productLabel,
              style: AppTypography.title.copyWith(fontWeight: FontWeight.w800),
            ),
            if (offer.stockNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                'Stock ${offer.stockNumber}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (listPrice != null)
                  Expanded(
                    child: _PriceBlock(
                      label: 'List price',
                      value: AppCurrency.format(listPrice),
                    ),
                  ),
                if (listPrice != null) const SizedBox(width: 12),
                Expanded(
                  child: _PriceBlock(
                    label: 'Buyer offer',
                    value: ProductOfferMapper.offerPriceLabel(offer.amount),
                    emphasize: true,
                  ),
                ),
              ],
            ),
            if (offer.buyerName != null || offer.buyerEmail != null) ...[
              const SizedBox(height: 12),
              Text(
                [
                  if (offer.buyerName != null) offer.buyerName!,
                  if (offer.buyerEmail != null) offer.buyerEmail!,
                ].join(' · '),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
            if (offer.message != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  offer.message!,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary(context),
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
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border(context)),
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
            color: AppColors.textMuted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w800,
            color: emphasize
                ? AppColors.info
                : AppColors.textPrimary(context),
            fontSize: emphasize ? 18 : 16,
          ),
        ),
      ],
    );
  }
}
