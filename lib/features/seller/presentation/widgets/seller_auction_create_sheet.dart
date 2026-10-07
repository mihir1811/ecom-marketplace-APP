import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../auction/application/auction_providers.dart';
import '../../../auction/data/repositories/auction_repository_impl.dart';
import '../../../auction/domain/models/auction_models.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../../application/seller_products_provider.dart';
import '../../domain/models/seller_product.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_studio.dart';
import '../atelier/atelier_theme.dart';

/// Opens the create / bulk-create auction sheet. Returns true when any auction
/// was created.
Future<bool> showSellerAuctionCreateSheet(BuildContext context) async {
  final created = await showAtelierSheet<bool>(
    context: context,
    title: 'Create auction',
    subtitle: 'Pick stones, set a schedule and opening bids.',
    scrollable: false,
    builder: (context) => const _CreateAuctionSheet(),
  );
  return created == true;
}

class _CreateAuctionSheet extends ConsumerStatefulWidget {
  const _CreateAuctionSheet();

  @override
  ConsumerState<_CreateAuctionSheet> createState() =>
      _CreateAuctionSheetState();
}

class _CreateAuctionSheetState extends ConsumerState<_CreateAuctionSheet> {
  final Set<String> _selected = {};
  final Map<String, TextEditingController> _bids = {};
  final Map<String, TextEditingController> _reserves = {};
  final Map<String, String> _fieldErrors = {};
  final _search = TextEditingController();
  String _query = '';
  DateTime _start = DateTime.now().add(const Duration(minutes: 10));
  DateTime _end = DateTime.now().add(const Duration(days: 7));
  int? _preset = 7;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(sellerProductsCatalogProvider.notifier).loadIfNeeded();
    });
  }

  @override
  void dispose() {
    for (final c in _bids.values) {
      c.dispose();
    }
    for (final c in _reserves.values) {
      c.dispose();
    }
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final catalog = ref.watch(sellerProductsCatalogProvider);
    final settings = ref.watch(auctionSettingsProvider).asData?.value;
    final maxDays = settings?.maxDays ?? 11;
    final presets = settings?.presetsWithinMax() ?? const [3, 5, 7];
    final eligible = catalog.products
        .where((p) => !p.isDeleted && !p.isSold && !p.isOnAuction)
        .toList();
    final visible = [
      for (final product in eligible)
        if (product.matchesSearch(_query.trim())) product,
    ];
    final duration = _end.difference(_start);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _StepLabel(index: 1, label: 'Schedule'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AtelierDateTile(
                        label: 'Starts',
                        value: atelierDateTime(_start),
                        icon: Icons.play_circle_outline_rounded,
                        onTap: () => _pick(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AtelierDateTile(
                        label: 'Ends',
                        value: atelierDateTime(_end),
                        icon: Icons.flag_outlined,
                        error:
                            !_end.isAfter(_start) ||
                            duration.inHours > maxDays * 24,
                        onTap: () => _pick(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final d in presets)
                      AtelierChoiceChip(
                        label: '$d days',
                        selected: _preset == d,
                        onTap: () => setState(() {
                          _preset = d;
                          _end = _start.add(Duration(days: d));
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  duration.isNegative
                      ? 'End must be after the start · max $maxDays days'
                      : 'Runs ${_durationLabel(duration)} · max $maxDays days · '
                            'one schedule for every stone',
                  style: AtelierType.caption(
                    duration.isNegative || duration.inHours > maxDays * 24
                        ? p.ruby
                        : p.muted,
                    size: 11.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: _StepLabel(index: 2, label: 'Stones'),
                    ),
                    AnimatedSwitcher(
                      duration: AtelierMotion.base,
                      child: _selected.isEmpty
                          ? const SizedBox.shrink()
                          : AtelierPill(
                              key: ValueKey(_selected.length),
                              label: '${_selected.length} selected',
                              tone: AtelierTone.gold,
                              dense: true,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AtelierSearchField(
                  controller: _search,
                  hint: 'Search stock no., shape, colour…',
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),
                if (catalog.isLoading && eligible.isEmpty)
                  const AtelierSkeletonList(count: 3, height: 64)
                else if (catalog.errorMessage != null && eligible.isEmpty)
                  AtelierErrorState(
                    compact: true,
                    title: 'Catalogue unavailable',
                    message: catalog.errorMessage!,
                    onRetry: () => ref
                        .read(sellerProductsCatalogProvider.notifier)
                        .refresh(),
                  )
                else if (eligible.isEmpty)
                  const AtelierEmptyState(
                    compact: true,
                    icon: Icons.inventory_2_outlined,
                    title: 'Nothing to auction',
                    message:
                        'Every stone is already sold, on auction or removed.',
                  )
                else if (visible.isEmpty)
                  AtelierEmptyState(
                    compact: true,
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    message: 'No eligible stone matches “${_query.trim()}”.',
                  )
                else
                  for (var i = 0; i < visible.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Reveal(
                        key: ValueKey(visible[i].id),
                        index: i < 8 ? i : 0,
                        offset: 8,
                        child: _ProductRow(
                          product: visible[i],
                          selected: _selected.contains(visible[i].id),
                          bid: _bids[visible[i].id],
                          reserve: _reserves[visible[i].id],
                          error: _fieldErrors[visible[i].id],
                          onToggle: () => _toggle(visible[i]),
                          onEdited: () {
                            if (_fieldErrors.remove(visible[i].id) != null) {
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          decoration: BoxDecoration(
            color: p.raised,
            border: Border(top: BorderSide(color: p.hairline)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSize(
                duration: AtelierMotion.base,
                curve: AtelierMotion.emphasized,
                child: _error == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AtelierNotice(
                          text: _error!,
                          tone: AtelierTone.ruby,
                          icon: Icons.error_outline_rounded,
                        ),
                      ),
              ),
              AtelierButton(
                label: _selected.isEmpty
                    ? 'Select stones to continue'
                    : 'Create ${_selected.length} '
                          'auction${_selected.length == 1 ? '' : 's'}',
                icon: Icons.gavel_rounded,
                variant: AtelierButtonVariant.gold,
                expand: true,
                loading: _submitting,
                onPressed: _selected.isEmpty ? null : _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _durationLabel(Duration d) {
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    if (days == 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return hours == 0 ? '$days days' : '${days}d ${hours}h';
  }

  void _toggle(SellerProduct product) {
    setState(() {
      if (_selected.remove(product.id)) {
        _fieldErrors.remove(product.id);
      } else {
        _selected.add(product.id);
        _bids.putIfAbsent(product.id, TextEditingController.new);
        _reserves.putIfAbsent(product.id, TextEditingController.new);
      }
      _error = null;
    });
  }

  Future<void> _pick({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final next = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _preset = null;
      _error = null;
      if (isStart) {
        final length = _end.difference(_start);
        _start = next;
        // Keep the chosen length when the start moves.
        if (!length.isNegative) _end = next.add(length);
      } else {
        _end = next;
      }
    });
  }

  Future<void> _submit() async {
    final settings = ref.read(auctionSettingsProvider).asData?.value;
    final maxDays = settings?.maxDays ?? 11;
    if (!_end.isAfter(_start)) {
      setState(() => _error = 'End time must be after the start.');
      return;
    }
    if (_end.difference(_start).inHours > maxDays * 24) {
      setState(() => _error = 'Auction cannot run longer than $maxDays days.');
      return;
    }
    final catalog = ref.read(sellerProductsCatalogProvider).products;
    final drafts = <AuctionBulkDraft>[];
    final errors = <String, String>{};
    for (final id in _selected) {
      final product = catalog.where((p) => p.id == id).firstOrNull;
      if (product == null) continue;
      final minBid = double.tryParse(_bids[id]?.text.trim() ?? '');
      if (minBid == null || minBid <= 0) {
        errors[id] = 'Enter an opening bid.';
        continue;
      }
      final reserve = double.tryParse(_reserves[id]?.text.trim() ?? '');
      if (reserve != null && reserve < minBid) {
        errors[id] = 'Reserve should be at or above the opening bid.';
        continue;
      }
      drafts.add(
        AuctionBulkDraft(
          productId: product.id,
          productType: product.isNatural
              ? CartProductType.diamond
              : CartProductType.meleeDiamond,
          minimumBid: minBid,
          reservePrice: reserve,
        ),
      );
    }
    if (errors.isNotEmpty) {
      AppHaptics.error();
      setState(() {
        _fieldErrors
          ..clear()
          ..addAll(errors);
        _error = errors.length == 1
            ? 'One stone needs attention.'
            : '${errors.length} stones need attention.';
      });
      return;
    }
    if (drafts.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final repo = ref.read(auctionRepositoryProvider);
    if (drafts.length == 1) {
      final item = drafts.first;
      final result = await repo.create(
        productId: item.productId,
        productType: item.productType,
        startTime: _start,
        endTime: _end,
        minimumBid: item.minimumBid,
        reservePrice: item.reservePrice,
      );
      if (!mounted) return;
      switch (result) {
        case Success(:final value):
          _done(value.message);
        case ResultFailure(:final failure):
          AppHaptics.error();
          setState(() {
            _submitting = false;
            _error = failure.message;
          });
      }
      return;
    }
    final result = await repo.bulkCreate(
      startTime: _start,
      endTime: _end,
      items: drafts,
    );
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        _done(
          '${value.message} Created ${value.created}, failed ${value.failed}.',
        );
      case ResultFailure(:final failure):
        AppHaptics.error();
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
    }
  }

  void _done(String message) {
    AppHaptics.success();
    showAtelierToast(context, message, tone: AtelierTone.emerald);
    Navigator.pop(context, true);
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.gold.withValues(alpha: 0.6)),
          ),
          child: Text('$index', style: AtelierType.figure(p.gold, size: 11)),
        ),
        const SizedBox(width: 10),
        Text(label, style: AtelierType.title(p.ink, size: 15)),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.selected,
    required this.onToggle,
    required this.onEdited,
    this.bid,
    this.reserve,
    this.error,
  });

  final SellerProduct product;
  final bool selected;
  final TextEditingController? bid;
  final TextEditingController? reserve;
  final String? error;
  final VoidCallback onToggle;
  final VoidCallback onEdited;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final facts = [
      product.field('shape'),
      product.field('carat_weight') == null
          ? null
          : '${product.field('carat_weight')} ct',
      [
        product.field('color'),
        product.field('clarity'),
      ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' '),
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
    final price = product.field('total_price');
    final money = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

    return AnimatedContainer(
      duration: AtelierMotion.base,
      curve: AtelierMotion.emphasized,
      decoration: BoxDecoration(
        color: selected ? p.goldSoft.withValues(alpha: 0.6) : p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.md),
        border: Border.all(
          color: error != null
              ? p.ruby.withValues(alpha: 0.6)
              : selected
              ? p.gold
              : p.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            onTap: onToggle,
            scale: 0.99,
            semanticLabel:
                '${selected ? 'Deselect' : 'Select'} '
                '${product.stockNumber}',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: AtelierMotion.base,
                    curve: AtelierMotion.settle,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? p.gold : Colors.transparent,
                      border: Border.all(
                        color: selected ? p.gold : p.muted,
                        width: 1.4,
                      ),
                    ),
                    child: AnimatedScale(
                      duration: AtelierMotion.base,
                      curve: AtelierMotion.settle,
                      scale: selected ? 1 : 0,
                      child: Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: p.onGold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.stockNumber,
                          style: AtelierType.label(p.ink, size: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          facts.isEmpty
                              ? (product.isNatural
                                    ? 'Natural diamond'
                                    : 'Melee diamond')
                              : facts,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.caption(p.muted, size: 11.5),
                        ),
                      ],
                    ),
                  ),
                  if (price != null && price.trim().isNotEmpty)
                    Text(
                      price.startsWith('\$') ? price : '\$$price',
                      style: AtelierType.figure(p.inkSoft, size: 12.5),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AtelierMotion.base,
            curve: AtelierMotion.emphasized,
            child: selected && bid != null && reserve != null
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AtelierTextField(
                                controller: bid!,
                                label: 'Opening bid',
                                hint: '0',
                                prefixText: '\$',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: money,
                                onChanged: (_) => onEdited(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AtelierTextField(
                                controller: reserve!,
                                label: 'Reserve (optional)',
                                hint: '—',
                                prefixText: '\$',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: money,
                                onChanged: (_) => onEdited(),
                              ),
                            ),
                          ],
                        ),
                        AtelierFieldError(error: error),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
