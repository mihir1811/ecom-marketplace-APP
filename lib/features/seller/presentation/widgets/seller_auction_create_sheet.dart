import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auction/application/auction_providers.dart';
import '../../../auction/data/repositories/auction_repository_impl.dart';
import '../../../auction/domain/models/auction_models.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../../application/seller_products_provider.dart';
import '../../domain/models/seller_product.dart';

/// Opens the create / bulk-create auction sheet. Returns true when any auction
/// was created.
Future<bool> showSellerAuctionCreateSheet(BuildContext context) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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
  DateTime _start = DateTime.now().add(const Duration(minutes: 10));
  DateTime _end = DateTime.now().add(const Duration(days: 7));
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
    for (final controller in _bids.values) {
      controller.dispose();
    }
    for (final controller in _reserves.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(sellerProductsCatalogProvider);
    final settings = ref.watch(auctionSettingsProvider);
    final products = catalog.products
        .where((p) => !p.isDeleted && !p.isSold && !p.isOnAuction)
        .toList();
    final maxDays = settings.asData?.value.maxDays ?? 11;
    final bottom =
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create auction', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Max duration $maxDays days. Shared start and end for every item.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(isStart: true),
                  child: Text('Start\n${_label(_start)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(isStart: false),
                  child: Text('End\n${_label(_end)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          if (catalog.isLoading)
            const LinearProgressIndicator()
          else
            SizedBox(
              height: 280,
              child: products.isEmpty
                  ? const Text('No eligible products in your catalog.')
                  : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final selected = _selected.contains(product.id);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: (value) =>
                              _toggle(product, value ?? false),
                          title: Text(product.stockNumber),
                          subtitle: selected
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _bids[product.id],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Min bid',
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _reserves[product.id],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Reserve',
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  product.isNatural
                                      ? CartProductType.diamond
                                      : CartProductType.meleeDiamond,
                                ),
                        );
                      },
                    ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting || _selected.isEmpty ? null : _submit,
            child: Text(
              _submitting
                  ? 'Creating…'
                  : 'Create ${_selected.length} auction${_selected.length == 1 ? '' : 's'}',
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(SellerProduct product, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(product.id);
        _bids.putIfAbsent(product.id, TextEditingController.new);
        _reserves.putIfAbsent(product.id, TextEditingController.new);
      } else {
        _selected.remove(product.id);
      }
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
      if (isStart) {
        _start = next;
      } else {
        _end = next;
      }
    });
  }

  String _label(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
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
    for (final id in _selected) {
      final product = catalog.where((p) => p.id == id).firstOrNull;
      if (product == null) continue;
      final minBid = double.tryParse(_bids[id]?.text.trim() ?? '');
      if (minBid == null || minBid <= 0) {
        setState(
          () => _error = 'Enter a minimum bid for ${product.stockNumber}.',
        );
        return;
      }
      final reserve = double.tryParse(_reserves[id]?.text.trim() ?? '');
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
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
    }
  }

  void _done(String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
    Navigator.pop(context, true);
  }
}
