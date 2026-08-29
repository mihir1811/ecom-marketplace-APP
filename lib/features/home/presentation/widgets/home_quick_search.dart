import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/home_search_provider.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/remaining_messages.dart';

/// Sticky home search field. Debounces input (280ms — web `useLiveSearchResults`).
class HomeQuickSearch extends ConsumerStatefulWidget {
  const HomeQuickSearch({super.key});

  @override
  ConsumerState<HomeQuickSearch> createState() => _HomeQuickSearchState();
}

class _HomeQuickSearchState extends ConsumerState<HomeQuickSearch> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _searchDebounce;

  static const _debounce = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_debounce, () {
      if (!mounted) return;
      ref.read(homeSearchQueryProvider.notifier).state = value;
    });
  }

  void _clear() {
    _searchDebounce?.cancel();
    _controller.clear();
    ref.read(homeSearchQueryProvider.notifier).state = '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return Material(
      color: AppColors.field(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.s8),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.bronze,
                size: 22,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {});
                  _onChanged(value);
                },
                onSubmitted: (value) {
                  _searchDebounce?.cancel();
                  ref.read(homeSearchQueryProvider.notifier).state = value;
                },
                style: AppTypography.body.copyWith(fontSize: 15),
                decoration: InputDecoration(
                  hintText: context.tr(
                    RemainingL10n.searchDiamondsJewelryWatches,
                  ),
                  hintStyle: AppTypography.body.copyWith(
                    fontSize: 15,
                    color: AppColors.textSecondary(context),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s16,
                  ),
                ),
              ),
            ),
            if (hasText)
              IconButton(
                tooltip: context.tr(RemainingL10n.clear),
                onPressed: _clear,
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.textSecondary(context),
              ),
          ],
        ),
      ),
    );
  }
}
