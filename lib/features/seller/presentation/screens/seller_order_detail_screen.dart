import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/seller_orders_mock_data.dart';
import '../../domain/models/seller_orders_models.dart';

class SellerOrderDetailScreen extends StatefulWidget {
  const SellerOrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  State<SellerOrderDetailScreen> createState() =>
      _SellerOrderDetailScreenState();
}

class _SellerOrderDetailScreenState extends State<SellerOrderDetailScreen> {
  static const _statusOptions = [
    'Processing',
    'Shipped',
    'Out For Delivery',
    'Delivered',
    'Cancelled',
  ];

  static const _progressStatuses = [
    'Processing',
    'Shipped',
    'Out For Delivery',
    'Delivered',
  ];

  static const _statusLabelKeys = <String, String>{
    'Processing': RemainingL10n.orderStatusProcessing,
    'Shipped': RemainingL10n.orderStatusShipped,
    'Out For Delivery': RemainingL10n.orderStatusOutForDelivery,
    'Delivered': RemainingL10n.orderStatusDelivered,
    'Cancelled': RemainingL10n.orderStatusCancelled,
  };

  late String _status;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _carrierCtrl;
  late final TextEditingController _trackingCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _commentCtrl;
  late List<SellerOrderTimelineEntry> _timeline;
  SellerOrder? _order;

  @override
  void initState() {
    super.initState();
    _order = findSellerOrderById(widget.orderId);
    final o = _order;
    _status = o?.status ?? 'Processing';
    _locationCtrl = TextEditingController(text: o?.location ?? '');
    _carrierCtrl = TextEditingController(text: o?.carrier ?? '');
    _trackingCtrl = TextEditingController(text: o?.trackingNumber ?? '');
    _noteCtrl = TextEditingController();
    _commentCtrl = TextEditingController();
    _timeline = List.of(o?.timeline ?? const []);
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _carrierCtrl.dispose();
    _trackingCtrl.dispose();
    _noteCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _saveUpdate() {
    final note = _noteCtrl.text.trim();
    setState(() {
      _timeline = [
        SellerOrderTimelineEntry(
          title:
              '${_statusLabel(context, _status)} · ${_locationCtrl.text.trim()}',
          subtitle: note.isEmpty
              ? context.tr(RemainingL10n.statusUpdated)
              : note,
          at: _nowLabel(),
        ),
        ..._timeline,
      ];
      _noteCtrl.clear();
    });
    AppHaptics.success();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(RemainingL10n.trackingSaved))),
    );
  }

  void _postComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    AppHaptics.medium();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(RemainingL10n.commentPosted))),
    );
  }

  String _statusLabel(BuildContext context, String status) {
    final key = _statusLabelKeys[status];
    return key == null ? status : context.tr(key);
  }

  String _nowLabel() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(n.day)}/${two(n.month)}/${n.year}, '
        '${two(n.hour)}:${two(n.minute)}:${two(n.second)}';
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('cancel')) return AppColors.error;
    if (s.contains('deliver')) return AppColors.success;
    if (s.contains('out for')) return AppColors.info;
    if (s.contains('process') || s.contains('ship')) return AppColors.bronze;
    return AppColors.charcoalLight;
  }

  IconData _statusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('cancel')) return Icons.cancel_outlined;
    if (s.contains('deliver')) return Icons.check_circle_outline;
    if (s.contains('out for')) return Icons.local_shipping_outlined;
    if (s.contains('process')) return Icons.hourglass_top_outlined;
    if (s.contains('ship')) return Icons.flight_takeoff_outlined;
    return Icons.shopping_bag_outlined;
  }

  int? _progressIndex(String status) {
    final idx = _progressStatuses.indexOf(status);
    return idx >= 0 ? idx : null;
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
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
    final order = _order;
    if (order == null) {
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
                context.tr(RemainingL10n.orderNotFound),
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s16),
              FilledButton(
                onPressed: () => context.goBack(),
                child: Text(context.tr(RemainingL10n.backToOrders)),
              ),
            ],
          ),
        ),
      );
    }

    final accent = _statusColor(_status);
    final location = _locationCtrl.text.trim().isEmpty
        ? order.location
        : _locationCtrl.text.trim();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s8,
              AppSpacing.s16,
              AppSpacing.s16,
            ),
            children: [
              _OrderHeroCard(
                orderId: order.id,
                statusLabel: _statusLabel(context, _status),
                updatedAt: order.updatedAt,
                accent: accent,
                icon: _statusIcon(_status),
              ),
              const SizedBox(height: AppSpacing.s16),
              _InfoGrid(
                items: [
                  _InfoTile(
                    icon: Icons.local_shipping_outlined,
                    label: context.tr(RemainingL10n.carrier),
                    value: _carrierCtrl.text.trim().isEmpty
                        ? order.carrier
                        : _carrierCtrl.text.trim(),
                  ),
                  _InfoTile(
                    icon: Icons.qr_code_2_outlined,
                    label: context.tr(RemainingL10n.trackingNumber),
                    value: _trackingCtrl.text.trim().isEmpty
                        ? order.trackingNumber
                        : _trackingCtrl.text.trim(),
                    monospace: true,
                  ),
                  _InfoTile(
                    icon: Icons.location_on_outlined,
                    label: context.tr(RemainingL10n.currentLocation),
                    value: location,
                  ),
                ],
              ),
              if (_progressIndex(_status) != null) ...[
                const SizedBox(height: AppSpacing.s16),
                _DeliveryProgress(
                  currentIndex: _progressIndex(_status)!,
                  labels: [
                    for (final s in _progressStatuses)
                      _statusLabel(context, s),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.s16),
              _SectionCard(
                icon: Icons.edit_location_alt_outlined,
                title: context.tr(RemainingL10n.updateTracking),
                subtitle: context.tr(RemainingL10n.optionalNoteForTimeline),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr(RemainingL10n.status2),
                      style: _sectionLabelStyle(context),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in _statusOptions)
                          _StatusChip(
                            label: _statusLabel(context, s),
                            icon: _statusIcon(s),
                            selected: _status == s,
                            color: _statusColor(s),
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
                        context,
                        label: context.tr(RemainingL10n.currentLocation),
                        icon: Icons.location_on_outlined,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    TextField(
                      controller: _carrierCtrl,
                      decoration: _fieldDecoration(
                        context,
                        label: context.tr(RemainingL10n.carrier),
                        icon: Icons.local_shipping_outlined,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    TextField(
                      controller: _trackingCtrl,
                      decoration: _fieldDecoration(
                        context,
                        label: context.tr(RemainingL10n.trackingNumber),
                        icon: Icons.qr_code_2_outlined,
                      ),
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      decoration: _fieldDecoration(
                        context,
                        label: context.tr(RemainingL10n.updateNote),
                        icon: Icons.notes_outlined,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              _SectionCard(
                icon: Icons.timeline_outlined,
                title: context.tr(RemainingL10n.timeline),
                child: _timeline.isEmpty
                    ? _EmptyPanel(
                        icon: Icons.history_toggle_off_outlined,
                        message: context.tr(RemainingL10n.statusUpdated),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < _timeline.length; i++)
                            _TimelineRow(
                              entry: _timeline[i],
                              isFirst: i == 0,
                              isLast: i == _timeline.length - 1,
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
                    _EmptyPanel(
                      icon: Icons.chat_bubble_outline,
                      message: context.tr(RemainingL10n.noCommentsYet),
                      compact: true,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    TextField(
                      controller: _commentCtrl,
                      maxLines: 3,
                      decoration: _fieldDecoration(
                        context,
                        label: context.tr(RemainingL10n.replyToBuyerHint),
                        icon: Icons.reply_outlined,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _postComment,
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
          ),
        ),
        _SaveBar(
          label: context.tr(RemainingL10n.saveUpdate),
          onPressed: _saveUpdate,
        ),
      ],
    );
  }

  TextStyle _sectionLabelStyle(BuildContext context) =>
      AppTypography.caption.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: AppColors.textSecondary(context),
      );
}

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
                                  context.tr(RemainingL10n.shipmentWithStatus, {
                                    'status': statusLabel,
                                  }),
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
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(
                            icon: Icons.flag_outlined,
                            label: statusLabel,
                            foreground: accent,
                            background: accent.withValues(alpha: 0.12),
                          ),
                          _MetaChip(
                            icon: Icons.schedule_outlined,
                            label: 'Updated $updatedAt',
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
              const SizedBox(width: 6),
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
          const SizedBox(height: 8),
          Text(
            value.isEmpty ? '—' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: monospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryProgress extends StatelessWidget {
  const _DeliveryProgress({
    required this.currentIndex,
    required this.labels,
  });

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
                    child: _ProgressDot(
                      index: i,
                      currentIndex: currentIndex,
                    ),
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
          const SizedBox(height: 6),
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
                if (i < labels.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({
    required this.index,
    required this.currentIndex,
  });

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
          ? const Icon(Icons.check, size: 14, color: AppColors.warmWhite)
          : index == currentIndex
          ? Container(
              margin: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: ink),
                const SizedBox(width: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
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
    required this.entry,
    required this.isFirst,
    required this.isLast,
  });

  final SellerOrderTimelineEntry entry;
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
                    entry.title,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary(context),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.at,
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
          Icon(icon, size: compact ? 20 : 28, color: AppColors.textMuted(context)),
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

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: AppColors.card(context),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s12,
            AppSpacing.s16,
            AppSpacing.s12,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.save_outlined, size: 20),
              label: Text(
                label,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.warmWhite,
                ),
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
        ),
      ),
    );
  }
}
