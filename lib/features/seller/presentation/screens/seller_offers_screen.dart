import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../product_offer/application/product_offer_providers.dart';
import '../../../product_offer/data/mappers/product_offer_mapper.dart';
import '../../../product_offer/domain/models/product_offer.dart';

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
    final result = await ref
        .read(sellerOfferListProvider.notifier)
        .respond(id: offer.id, status: status);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success():
        if (status == ProductOfferStatus.accepted) {
          AppHaptics.success();
        } else {
          AppHaptics.warning();
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              status == ProductOfferStatus.accepted
                  ? context.tr(RemainingL10n.offerAccepted)
                  : context.tr(RemainingL10n.offerRejected),
            ),
          ),
        );
      case ResultFailure(:final failure):
        AppHaptics.error();
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
        if (state.isLoading)
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
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    state.errorMessage!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  context.tr(RemainingL10n.reviewBuyerPriceOffersOnYour),
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
                    label: context.tr(RemainingL10n.all),
                    selected: _filter == null,
                    onTap: () => _applyFilter(null),
                  ),
                  _FilterChip(
                    label: context.tr(RemainingL10n.pending),
                    selected: _filter == ProductOfferStatus.pending,
                    onTap: () => _applyFilter(ProductOfferStatus.pending),
                  ),
                  _FilterChip(
                    label: context.tr(RemainingL10n.accepted),
                    selected: _filter == ProductOfferStatus.accepted,
                    onTap: () => _applyFilter(ProductOfferStatus.accepted),
                  ),
                  _FilterChip(
                    label: context.tr(RemainingL10n.rejected),
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
                      context.tr(RemainingL10n.noOffersInThisFilter),
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
    final listPrice = offer.listPrice;
    final statusColor = _statusColor(context);
    final buyerLine = [
      if (offer.buyerName != null) offer.buyerName!,
      if (offer.buyerEmail != null) offer.buyerEmail!,
    ].join(' · ');
    final metaParts = <String>[
      if (offer.stockNumber != null)
        context.tr(RemainingL10n.stockWithNumber, {
          'stockNumber': offer.stockNumber!,
        }),
      if (offer.productSpecs != null) offer.productSpecs!,
      if (offer.certificateLabel != null) offer.certificateLabel!,
    ];

    return Material(
      color: AppColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Pill(label: offer.productType),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    offer.status.label,
                    style: AppTypography.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductThumb(imageUrl: offer.imageUrl),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (metaParts.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          metaParts.join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary(context),
                            height: 1.3,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (offer.productId.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'ID ${offer.productId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted(context),
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                      if (buyerLine.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          buyerLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (listPrice != null) ...[
                      _PriceBlock(
                        label: context.tr(RemainingL10n.listPrice),
                        value: AppCurrency.format(listPrice),
                        alignEnd: true,
                      ),
                      const SizedBox(height: 6),
                    ],
                    _PriceBlock(
                      label: context.tr(RemainingL10n.buyerOffer),
                      value: ProductOfferMapper.offerPriceLabel(offer.amount),
                      emphasize: true,
                      alignEnd: true,
                    ),
                  ],
                ),
              ],
            ),
            if (offer.message != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                ),
                child: Text(
                  offer.message!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary(context),
                    height: 1.35,
                  ),
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size.fromHeight(40),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(context.tr(RemainingL10n.reject)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.charcoal,
                        minimumSize: const Size.fromHeight(40),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(context.tr(RemainingL10n.accept)),
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

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.r8);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: 64,
        height: 64,
        color: AppColors.surface(context),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppColors.border(context)),
        ),
        child: imageUrl == null || imageUrl!.isEmpty
            ? Icon(
                Icons.diamond_outlined,
                size: 26,
                color: AppColors.textMuted(context),
              )
            : AppNetworkImage(
                url: imageUrl!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                memCacheWidth: 128,
                error: Icon(
                  Icons.diamond_outlined,
                  size: 26,
                  color: AppColors.textMuted(context),
                ),
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
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final align = alignEnd ? TextAlign.end : TextAlign.start;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: align,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted(context),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: align,
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w800,
            color: emphasize ? AppColors.info : AppColors.textPrimary(context),
            fontSize: emphasize ? 18 : 14,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}
