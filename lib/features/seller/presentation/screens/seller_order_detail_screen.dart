import 'package:flutter/material.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/seller_orders_mock_data.dart';
import '../../domain/models/seller_orders_models.dart';
import '../widgets/seller_layout.dart';

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
          title: '$_status · ${_locationCtrl.text.trim()}',
          subtitle: note.isEmpty ? 'Status updated' : note,
          at: _nowLabel(),
        ),
        ..._timeline,
      ];
      _noteCtrl.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tracking update saved')));
  }

  String _nowLabel() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(n.day)}/${two(n.month)}/${n.year}, ${two(n.hour)}:${two(n.minute)}:${two(n.second)}';
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.surface(context),
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    if (order == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Order not found'),
            TextButton(
              onPressed: () => context.goBack(),
              child: const Text('Back to orders'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => openSellerDrawer(context),
                icon: const Icon(Icons.menu),
              ),
              Text(
                'Order details',
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${order.id}',
                      style: AppTypography.headline.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Shipment · $_status',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.textMuted(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _locationCtrl.text.isEmpty
                              ? order.location
                              : _locationCtrl.text,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Update tracking',
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Status', style: _labelStyle),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_status),
                      initialValue: _statusOptions.contains(_status)
                          ? _status
                          : _statusOptions.first,
                      items: [
                        for (final s in _statusOptions)
                          DropdownMenuItem(value: s, child: Text(s)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                      decoration: _fieldDecoration('Status'),
                    ),
                    const SizedBox(height: 12),
                    Text('Current location', style: _labelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _locationCtrl,
                      decoration: _fieldDecoration('Location'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Text('Carrier', style: _labelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _carrierCtrl,
                      decoration: _fieldDecoration('Carrier'),
                    ),
                    const SizedBox(height: 12),
                    Text('Tracking number', style: _labelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _trackingCtrl,
                      decoration: _fieldDecoration('Tracking number'),
                    ),
                    const SizedBox(height: 12),
                    Text('Update note', style: _labelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      decoration: _fieldDecoration(
                        'Optional note for the timeline',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: _saveUpdate,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: AppColors.warmWhite,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Save update'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Timeline',
                          style: AppTypography.title.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _timeline.length; i++) ...[
                      _TimelineRow(
                        entry: _timeline[i],
                        isLast: i == _timeline.length - 1,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Comments',
                          style: AppTypography.title.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No comments yet.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentCtrl,
                      decoration: _fieldDecoration('Reply to the buyer...'),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: () {
                          _commentCtrl.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Comment posted')),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.info.withValues(
                            alpha: 0.85,
                          ),
                          foregroundColor: AppColors.warmWhite,
                        ),
                        child: const Text('Post comment'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle get _labelStyle => AppTypography.caption.copyWith(
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary(context),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: child,
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.isLast});

  final SellerOrderTimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.bronze,
                    shape: BoxShape.circle,
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
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
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
