import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Minimal search field — opens the diamond finder on submit or tap.
class HomeQuickSearch extends StatefulWidget {
  const HomeQuickSearch({super.key});

  @override
  State<HomeQuickSearch> createState() => _HomeQuickSearchState();
}

class _HomeQuickSearchState extends State<HomeQuickSearch> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goFind() {
    _focusNode.unfocus();
    context.push(AppRouteNames.diamonds);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        side: const BorderSide(color: AppColors.warmBorder),
      ),
      child: InkWell(
        onTap: () => _focusNode.requestFocus(),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
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
                  onSubmitted: (_) => _goFind(),
                  style: AppTypography.body.copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search shape, carat, certificate…',
                    hintStyle: AppTypography.body.copyWith(
                      fontSize: 15,
                      color: AppColors.textSecondaryLight,
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
              TextButton(
                onPressed: _goFind,
                child: Text(
                  'Go',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
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
