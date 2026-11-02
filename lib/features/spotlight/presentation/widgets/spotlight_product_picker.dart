import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../buyer/presentation/maison/maison_kit.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../data/spotlight_seller_repository.dart';
import '../../domain/spotlight_models.dart';
import '../../domain/spotlight_seller_models.dart';
import '../screens/seller_spotlight_screen.dart' show spotlightCategoryName;

/// Picks the seller's products that can be sponsored. With [max] 1 it is a
/// single choice (a banner's link); otherwise up to [max] products.
///
/// Resolves to the new selection, or null when dismissed.
Future<List<SpotlightSellerProduct>?> showSpotlightProductPicker({
  required BuildContext context,
  required List<SpotlightCategory> categories,
  required List<SpotlightSellerProduct> selected,
  required int max,
  String title = 'Choose products',
}) {
  return showAtelierSheet<List<SpotlightSellerProduct>>(
    context: context,
    title: title,
    subtitle: max == 1
        ? 'Only pieces for sale right now can be picked.'
        : 'Up to $max. Only pieces for sale right now can be picked.',
    scrollable: false,
    builder: (_) => _ProductPicker(
      categories: categories,
      initial: selected,
      max: max,
    ),
  );
}

class _ProductPicker extends ConsumerStatefulWidget {
  const _ProductPicker({
    required this.categories,
    required this.initial,
    required this.max,
  });

  final List<SpotlightCategory> categories;
  final List<SpotlightSellerProduct> initial;
  final int max;

  @override
  ConsumerState<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends ConsumerState<_ProductPicker> {
  final _search = TextEditingController();
  late final _picked = <String, SpotlightSellerProduct>{
    for (final p in widget.initial) p.key: p,
  };
  late SpotlightCategory _category = widget.categories.first;
  List<SpotlightSellerProduct>? _items;
  String? _error;
  Timer? _debounce;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _items = null;
      _error = null;
    });
    final result = await ref
        .read(spotlightSellerRepositoryProvider)
        .products(category: _category, search: _search.text);
    if (!mounted || request != _request) return;
    setState(() {
      switch (result) {
        case Success(:final value):
          _items = value;
        case ResultFailure(:final failure):
          _items = const [];
          _error = failure.message;
      }
    });
  }

  void _toggle(SpotlightSellerProduct product) {
    setState(() {
      if (widget.max == 1) {
        _picked
          ..clear()
          ..[product.key] = product;
        return;
      }
      if (_picked.remove(product.key) != null) return;
      if (_picked.length >= widget.max) {
        showAtelierToast(
          context,
          'Up to ${widget.max} products in one ad.',
          tone: AtelierTone.amber,
        );
        return;
      }
      _picked[product.key] = product;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final items = _items;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.categories.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in widget.categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AtelierChoiceChip(
                        label: spotlightCategoryName(c),
                        selected: c == _category,
                        onTap: () {
                          if (c == _category) return;
                          setState(() => _category = c);
                          _load();
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          AtelierSearchField(
            controller: _search,
            hint: 'Search by title or stock number',
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), _load);
            },
          ),
          const SizedBox(height: 12),
          Flexible(
            child: items == null
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: AtelierEmptyState(
                      compact: true,
                      icon: Icons.inventory_2_outlined,
                      title: _error == null ? 'Nothing to sponsor here' : 'Couldn’t load products',
                      message:
                          _error ??
                          'Only pieces for sale right now in this section can be sponsored.',
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AtelierSpace.s8),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final on = _picked.containsKey(item.key);
                      final line = [
                        if (item.stockNumber != null) '#${item.stockNumber}',
                        ?item.subtitle,
                        if (item.price != null) maisonUsd(item.price!),
                      ].join(' · ');
                      return AtelierCard(
                        onTap: () => _toggle(item),
                        padding: const EdgeInsets.all(AtelierSpace.s10),
                        borderColor: on ? p.gold : null,
                        elevated: false,
                        child: Row(
                          children: [
                            AtelierThumb(url: item.imageUrl, size: 48),
                            const SizedBox(width: AtelierSpace.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AtelierType.label(p.ink),
                                  ),
                                  if (line.isNotEmpty)
                                    Text(
                                      line,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AtelierType.caption(p.muted),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              widget.max == 1
                                  ? (on
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded)
                                  : (on
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined),
                              color: on ? p.gold : p.muted,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          AtelierButton(
            label: widget.max == 1
                ? 'Use this product'
                : 'Done · ${_picked.length} picked',
            expand: true,
            onPressed: _picked.isEmpty && widget.initial.isEmpty
                ? null
                : () => Navigator.of(context).pop(_picked.values.toList()),
          ),
        ],
      ),
    );
  }
}
