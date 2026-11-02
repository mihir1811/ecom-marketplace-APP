import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemstone/core/theme/app_fonts.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../tracking/application/order_shipments_provider.dart';
import '../../../tracking/data/repositories/tracking_repository_impl.dart';
import '../../../tracking/domain/models/shipment_models.dart';
import '../../application/seller_order_shipping_provider.dart';
import '../../application/seller_orders_provider.dart';
import '../../domain/models/seller_order.dart';
import '../widgets/seller_order_decision.dart';

/// Seller view of one incoming order: approve / reject while pending, then
/// shipping updates once confirmed (`/seller/orders`, `/tracking/seller/*`).
class SellerOrderDetailScreen extends ConsumerWidget {
  const SellerOrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sellerOrderDetailProvider(orderId));
    return async.when(
      // Keep showing the order while a realtime refresh reloads it.
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _NotFound(
        message: error is Failure
            ? error.message
            : context.tr(RemainingL10n.orderNotFound),
        onRetry: () => ref.invalidate(sellerOrderDetailProvider(orderId)),
      ),
      data: (order) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sellerOrderShipmentsProvider(order.orderId));
          return ref.refresh(sellerOrderDetailProvider(orderId).future);
        },
        child: _OrderDetailBody(order: order),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.textMuted(context),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              message,
              style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s16),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onRetry,
                  child: Text(context.tr(RemainingL10n.retry)),
                ),
                FilledButton(
                  onPressed: () => context.goBack(),
                  child: Text(context.tr(RemainingL10n.backToOrders)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.order});

  final SellerOrder order;

  @override
  Widget build(BuildContext context) {
    final accent = sellerOrderStatusColor(order.status);
    final customer = order.customer;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s16,
        AppSpacing.s24,
      ),
      children: [
        _OrderHeroCard(
          orderId: order.shortId,
          statusLabel: sellerOrderStatusLabel(order),
          updatedAt: sellerOrderDateLabel(
            order.decidedAt ?? order.updatedAt ?? order.createdAt,
          ),
          accent: accent,
          icon: sellerOrderStatusIcon(order.status),
        ),
        if (order.status == SellerOrderStatus.pending) ...[
          const SizedBox(height: AppSpacing.s16),
          _SectionCard(
            icon: Icons.approval_outlined,
            title: 'Waiting for your approval',
            subtitle:
                'Accept to confirm the order, or reject it to refund the '
                'customer to their wallet.',
            child: SellerOrderDecisionButtons(order: order),
          ),
        ],
        if (order.status == SellerOrderStatus.rejected) ...[
          const SizedBox(height: AppSpacing.s16),
          _SectionCard(
            icon: Icons.cancel_outlined,
            title: 'Order rejected',
            subtitle: 'The customer was refunded to their GemWorld wallet.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KeyValue(
                  label: 'Reason',
                  value: order.rejectionReason ?? 'Not provided',
                ),
                if (order.sellerNote != null) ...[
                  const SizedBox(height: AppSpacing.s12),
                  _KeyValue(
                    label: 'Note to customer',
                    value: order.sellerNote!,
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s16),
        _InfoGrid(
          items: [
            _InfoTile(
              icon: Icons.person_outline,
              label: 'Customer',
              value: order.customerLabel,
            ),
            _InfoTile(
              icon: Icons.payments_outlined,
              label: 'Amount',
              value: sellerOrderAmountLabel(order),
            ),
            _InfoTile(
              icon: Icons.event_outlined,
              label: 'Ordered on',
              value: sellerOrderDateLabel(order.createdAt),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        _SectionCard(
          icon: Icons.receipt_long_outlined,
          title: 'Order details',
          subtitle: order.orderId == order.id
              ? null
              : 'Marketplace order ${order.orderId}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (order.items.isEmpty)
                _EmptyPanel(
                  icon: Icons.inventory_2_outlined,
                  message: order.productSummary,
                  compact: true,
                )
              else
                for (var i = 0; i < order.items.length; i++) ...[
                  if (i > 0) const Divider(height: AppSpacing.s24),
                  _OrderItemRow(item: order.items[i]),
                ],
              if (customer?.email != null || customer?.phone != null) ...[
                const SizedBox(height: AppSpacing.s16),
                _KeyValue(
                  label: 'Contact',
                  value: [
                    customer?.email,
                    customer?.phone,
                  ].whereType<String>().join(' · '),
                ),
              ],
              if (order.shippingAddress != null) ...[
                const SizedBox(height: AppSpacing.s12),
                _KeyValue(label: 'Ship to', value: order.shippingAddress!),
              ],
              if (order.paymentStatus != null) ...[
                const SizedBox(height: AppSpacing.s12),
                _KeyValue(
                  label: 'Payment',
                  value: ShipmentStatuses.label(order.paymentStatus!),
                ),
              ],
            ],
          ),
        ),
        if (order.status == SellerOrderStatus.accepted) ...[
          const SizedBox(height: AppSpacing.s16),
          _ShippingSection(order: order),
        ],
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.body),
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final SellerOrderItem item;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (item.productType != null) item.productType!,
      if (item.stockNumber != null) '#${item.stockNumber}',
      'Qty ${item.quantity}',
    ].join(' · ');
    final price = item.lineTotal ?? item.unitPrice;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: item.image != null
              ? CachedNetworkImage(
                  imageUrl: item.image!,
                  fit: BoxFit.cover,
                  memCacheWidth: 104,
                  errorWidget: (_, __, ___) =>
                      Icon(Icons.diamond_outlined, color: AppColors.bronze),
                )
              : Icon(Icons.diamond_outlined, color: AppColors.bronze),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                ),
              ),
            ],
          ),
        ),
        if (price != null) ...[
          const SizedBox(width: AppSpacing.s8),
          Text(
            AppCurrency.usd(price),
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}

/// Next valid seller step after acceptance: create the shipment, then move it
/// forward until delivered. Comments reach the buyer's tracking view.
class _ShippingSection extends ConsumerStatefulWidget {
  const _ShippingSection({required this.order});

  final SellerOrder order;

  @override
  ConsumerState<_ShippingSection> createState() => _ShippingSectionState();
}

class _ShippingSectionState extends ConsumerState<_ShippingSection> {
  final _locationCtrl = TextEditingController();
  final _carrierCtrl = TextEditingController();
  final _trackingCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  String? _status;
  String? _seededFor;
  bool _postingComment = false;

  String get _orderId => widget.order.orderId;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _carrierCtrl.dispose();
    _trackingCtrl.dispose();
    _noteCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  /// Prefills the form once per shipment so typing is not overwritten by a
  /// background refresh.
  void _seed(Shipment? shipment) {
    final key = shipment?.id ?? '';
    if (_seededFor == key) return;
    _seededFor = key;
    _locationCtrl.text = shipment?.currentLocation ?? '';
    _carrierCtrl.text = shipment?.carrier ?? '';
    _trackingCtrl.text = shipment?.trackingNumber ?? '';
    final options = ShipmentStatuses.nextOptions(shipment?.status);
    _status = options.isEmpty ? null : options.first;
  }

  Future<void> _save(Shipment? shipment) async {
    final status = _status;
    if (status == null) return;
    if (status == ShipmentStatuses.cancelled) {
      final confirmed = await showAppDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancel shipment?'),
          content: const Text('A cancelled shipment cannot be updated again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Cancel shipment'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final result = await ref
        .read(sellerShipmentActionsProvider.notifier)
        .save(
          orderId: _orderId,
          existing: shipment,
          status: status,
          currentLocation: _locationCtrl.text,
          carrier: _carrierCtrl.text,
          trackingNumber: _trackingCtrl.text,
          note: _noteCtrl.text,
        );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success(:final value):
        AppHaptics.success();
        _noteCtrl.clear();
        _seededFor = null;
        _seed(value);
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr(RemainingL10n.trackingSaved))),
        );
      case ResultFailure(:final failure):
        AppHaptics.error();
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _postComment(Shipment shipment) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _postingComment) return;
    setState(() => _postingComment = true);
    final result = await ref
        .read(trackingRepositoryProvider)
        .addComment(shipmentId: shipment.id, body: text);
    if (!mounted) return;
    setState(() => _postingComment = false);
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success():
        AppHaptics.medium();
        _commentCtrl.clear();
        ref.invalidate(shipmentDetailProvider(shipment.id));
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr(RemainingL10n.commentPosted))),
        );
      case ResultFailure(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.r12),
      borderSide: BorderSide(color: AppColors.border(context)),
    );
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: AppColors.surface(context),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: AppColors.bronze, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: maxLines > 1 ? AppSpacing.s16 : AppSpacing.s12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shipmentsAsync = ref.watch(sellerOrderShipmentsProvider(_orderId));
    return shipmentsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.s24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _SectionCard(
        icon: Icons.local_shipping_outlined,
        title: context.tr(RemainingL10n.updateTracking),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(error is Failure ? error.message : 'Could not load shipping.'),
            const SizedBox(height: AppSpacing.s8),
            OutlinedButton(
              onPressed: () =>
                  ref.invalidate(sellerOrderShipmentsProvider(_orderId)),
              child: Text(context.tr(RemainingL10n.retry)),
            ),
          ],
        ),
      ),
      data: (shipments) {
        final shipment = shipments.isEmpty ? null : shipments.first;
        _seed(shipment);
        return _buildShipping(shipment);
      },
    );
  }

  Widget _buildShipping(Shipment? shipment) {
    final saving = ref.watch(sellerShipmentActionsProvider);
    final options = ShipmentStatuses.nextOptions(shipment?.status);
    final currentStatus = shipment?.status;
    final progressIndex = currentStatus == null
        ? null
        : ShipmentStatuses.progression.indexOf(currentStatus.toUpperCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (shipment != null) ...[
          _InfoGrid(
            items: [
              _InfoTile(
                icon: Icons.local_shipping_outlined,
                label: context.tr(RemainingL10n.carrier),
                value: shipment.carrier ?? '',
              ),
              _InfoTile(
                icon: Icons.qr_code_2_outlined,
                label: context.tr(RemainingL10n.trackingNumber),
                value: shipment.trackingNumber ?? '',
                monospace: true,
              ),
              _InfoTile(
                icon: Icons.location_on_outlined,
                label: context.tr(RemainingL10n.currentLocation),
                value: shipment.currentLocation ?? '',
              ),
            ],
          ),
          if (progressIndex != null && progressIndex >= 0) ...[
            const SizedBox(height: AppSpacing.s16),
            _DeliveryProgress(
              currentIndex: progressIndex,
              labels: [
                for (final s in ShipmentStatuses.progression)
                  ShipmentStatuses.label(s),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
        ],
        if (options.isEmpty)
          _EmptyPanel(
            icon: currentStatus?.toUpperCase() == ShipmentStatuses.delivered
                ? Icons.task_alt_outlined
                : Icons.block_outlined,
            message: currentStatus?.toUpperCase() == ShipmentStatuses.delivered
                ? 'Delivered — this order is complete.'
                : 'This shipment was cancelled. No further updates.',
          )
        else
          _SectionCard(
            icon: Icons.edit_location_alt_outlined,
            title: shipment == null
                ? 'Create shipment'
                : context.tr(RemainingL10n.updateTracking),
            subtitle: shipment == null
                ? 'The customer sees each update on their order.'
                : context.tr(RemainingL10n.optionalNoteForTimeline),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr(RemainingL10n.status2),
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in options)
                      _StatusChip(
                        label: ShipmentStatuses.label(s),
                        icon: _shipmentIcon(s),
                        selected: _status == s,
                        color: _shipmentColor(s),
                        onTap: () {
                          if (_status == s) return;
                          AppHaptics.selection();
                          setState(() => _status = s);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                TextField(
                  controller: _locationCtrl,
                  decoration: _fieldDecoration(
                    label: context.tr(RemainingL10n.currentLocation),
                    icon: Icons.location_on_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                TextField(
                  controller: _carrierCtrl,
                  decoration: _fieldDecoration(
                    label: context.tr(RemainingL10n.carrier),
                    icon: Icons.local_shipping_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                TextField(
                  controller: _trackingCtrl,
                  decoration: _fieldDecoration(
                    label: context.tr(RemainingL10n.trackingNumber),
                    icon: Icons.qr_code_2_outlined,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: _fieldDecoration(
                    label: context.tr(RemainingL10n.updateNote),
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: saving || _status == null
                        ? null
                        : () => _save(shipment),
                    icon: saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.warmWhite,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 20),
                    label: Text(
                      shipment == null
                          ? 'Create shipment'
                          : context.tr(RemainingL10n.saveUpdate),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.charcoal,
                      foregroundColor: AppColors.warmWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.r12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (shipment != null) ...[
          const SizedBox(height: AppSpacing.s16),
          _ShipmentActivity(
            shipment: shipment,
            commentController: _commentCtrl,
            posting: _postingComment,
            onPost: () => _postComment(shipment),
            decoration: _fieldDecoration(
              label: context.tr(RemainingL10n.replyToBuyerHint),
              icon: Icons.reply_outlined,
              maxLines: 3,
            ),
          ),
        ],
      ],
    );
  }
}

/// Timeline and buyer/seller comments for one shipment.
class _ShipmentActivity extends ConsumerWidget {
  const _ShipmentActivity({
    required this.shipment,
    required this.commentController,
    required this.posting,
    required this.onPost,
    required this.decoration,
  });

  final Shipment shipment;
  final TextEditingController commentController;
  final bool posting;
  final VoidCallback onPost;
  final InputDecoration decoration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(shipmentDetailProvider(shipment.id)).asData?.value;
    final source = detail ?? shipment;
    final updates = [...source.updates]
      ..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
    final comments = source.comments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          icon: Icons.timeline_outlined,
          title: context.tr(RemainingL10n.timeline),
          child: updates.isEmpty
              ? _EmptyPanel(
                  icon: Icons.history_toggle_off_outlined,
                  message: ShipmentStatuses.label(shipment.status),
                )
              : Column(
                  children: [
                    for (var i = 0; i < updates.length; i++)
                      _TimelineRow(
                        title: [
                          ShipmentStatuses.label(updates[i].status),
                          if (updates[i].location != null) updates[i].location!,
                        ].join(' · '),
                        subtitle:
                            updates[i].note ??
                            context.tr(RemainingL10n.statusUpdated),
                        at: sellerOrderDateLabel(updates[i].createdAt),
                        isFirst: i == 0,
                        isLast: i == updates.length - 1,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.s16),
        _SectionCard(
          icon: Icons.forum_outlined,
          title: context.tr(RemainingL10n.comments),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (comments.isEmpty)
                _EmptyPanel(
                  icon: Icons.chat_bubble_outline,
                  message: context.tr(RemainingL10n.noCommentsYet),
                  compact: true,
                )
              else
                for (final c in comments) ...[
                  _EmptyPanel(
                    icon: Icons.chat_bubble_outline,
                    message: '${c.body}\n${sellerOrderDateLabel(c.createdAt)}',
                    compact: true,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                ],
              const SizedBox(height: AppSpacing.s12),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: decoration,
              ),
              const SizedBox(height: AppSpacing.s12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: posting ? null : onPost,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: Text(context.tr(RemainingL10n.postComment)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.charcoal,
                    foregroundColor: AppColors.warmWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s20,
                      vertical: AppSpacing.s12,
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

Color _shipmentColor(String status) => switch (status.toUpperCase()) {
  ShipmentStatuses.cancelled => AppColors.error,
  ShipmentStatuses.delivered => AppColors.success,
  ShipmentStatuses.outForDelivery => AppColors.info,
  _ => AppColors.bronze,
};

IconData _shipmentIcon(String status) => switch (status.toUpperCase()) {
  ShipmentStatuses.cancelled => Icons.cancel_outlined,
  ShipmentStatuses.delivered => Icons.check_circle_outline,
  ShipmentStatuses.outForDelivery => Icons.local_shipping_outlined,
  ShipmentStatuses.packed => Icons.inventory_2_outlined,
  ShipmentStatuses.shipped ||
  ShipmentStatuses.inTransit => Icons.flight_takeoff_outlined,
  _ => Icons.hourglass_top_outlined,
};

class _OrderHeroCard extends StatelessWidget {
  const _OrderHeroCard({
    required this.orderId,
    required this.statusLabel,
    required this.updatedAt,
    required this.accent,
    required this.icon,
  });

  final String orderId;
  final String statusLabel;
  final String updatedAt;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: AppColors.isDark(context) ? [] : AppShadows.cardLight,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.r16),
                    bottomLeft: Radius.circular(AppSpacing.r16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(icon, color: accent, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr(RemainingL10n.orderWithId, {
                                    'id': orderId,
                                  }),
                                  style: AppTypography.title.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  statusLabel,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MetaChip(
                            icon: Icons.flag_outlined,
                            label: statusLabel,
                            foreground: accent,
                            background: accent.withValues(alpha: 0.12),
                          ),
                          _MetaChip(
                            icon: Icons.schedule_outlined,
                            label: updatedAt,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoTile> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 560;
        if (stacked) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.s12),
                items[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s12),
              Expanded(child: items[i]),
            ],
          ],
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.bronze),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted(context),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? '—' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: monospace ? AppFonts.monoFontFamily : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryProgress extends StatelessWidget {
  const _DeliveryProgress({required this.currentIndex, required this.labels});

  final int currentIndex;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(RemainingL10n.orderStatus),
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted(context),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                Expanded(
                  child: Center(
                    child: _ProgressDot(index: i, currentIndex: currentIndex),
                  ),
                ),
                if (i < labels.length - 1)
                  Container(
                    height: 2,
                    width: 12,
                    color: i < currentIndex
                        ? AppColors.bronze
                        : AppColors.border(context),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      height: 1.25,
                      fontWeight: i == currentIndex
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: i <= currentIndex
                          ? AppColors.textPrimary(context)
                          : AppColors.textMuted(context),
                    ),
                  ),
                ),
                if (i < labels.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({required this.index, required this.currentIndex});

  final int index;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: index <= currentIndex
            ? AppColors.bronze
            : AppColors.surface(context),
        border: Border.all(
          color: index <= currentIndex
              ? AppColors.bronze
              : AppColors.border(context),
          width: 1.5,
        ),
      ),
      child: index < currentIndex
          ? Icon(Icons.check, size: 14, color: AppColors.warmWhite)
          : index == currentIndex
          ? Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.warmWhite,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: AppColors.isDark(context) ? [] : AppShadows.cardLight,
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bronze.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.bronze),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          child,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = selected ? color : AppColors.surface(context);
    final ink = selected ? AppColors.warmWhite : AppColors.textPrimary(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? fill : AppColors.border(context),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: ink),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.foreground,
    this.background,
  });

  final IconData icon;
  final String label;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? AppColors.textSecondary(context);
    final bg = background ?? AppColors.surface(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.subtitle,
    required this.at,
    required this.isFirst,
    required this.isLast,
  });

  final String title;
  final String subtitle;
  final String at;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = isFirst ? AppColors.bronze : AppColors.border(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: isFirst ? 14 : 10,
                  height: isFirst ? 14 : 10,
                  decoration: BoxDecoration(
                    color: isFirst ? dotColor : AppColors.card(context),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.s16),
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                color: isFirst
                    ? AppColors.bronze.withValues(alpha: 0.08)
                    : AppColors.surface(context),
                borderRadius: BorderRadius.circular(AppSpacing.r12),
                border: Border.all(
                  color: isFirst
                      ? AppColors.bronze.withValues(alpha: 0.25)
                      : AppColors.border(context),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary(context),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    at,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.message,
    this.compact = false,
  });

  final IconData icon;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: compact ? AppSpacing.s12 : AppSpacing.s20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: compact ? 20 : 28,
            color: AppColors.textMuted(context),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
