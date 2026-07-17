import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/diamond_search_provider.dart';
import 'filter_boolean_checkbox.dart';

class FilterCategoryInclusions extends ConsumerWidget {
  const FilterCategoryInclusions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diamondSearchProvider);

    return RepaintBoundary(
      child: Column(
        children: [
          FilterBooleanCheckbox(
            label: 'No BGM (No Brown, Green, Milky tints)',
            value: state.noBgm,
            onChanged: (_) => ref.read(diamondSearchProvider.notifier).toggleNoBgm(),
          ),
          FilterBooleanCheckbox(
            label: 'Eye Clean (No inclusions visible to naked eye)',
            value: state.eyeClean,
            onChanged: (_) => ref.read(diamondSearchProvider.notifier).toggleEyeClean(),
          ),
          FilterBooleanCheckbox(
            label: 'Hearts & Arrows',
            value: state.heartAndArrow,
            onChanged: (_) => ref.read(diamondSearchProvider.notifier).toggleHeartAndArrow(),
          ),
        ],
      ),
    );
  }
}
