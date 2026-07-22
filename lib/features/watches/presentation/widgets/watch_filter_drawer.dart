import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/filters/filter_accordion_section.dart';
import '../../../../core/widgets/filters/filter_end_drawer_shell.dart';
import '../../application/watch_filter_provider.dart';
import '../../application/watch_list_provider.dart';
import '../../domain/models/watch_filter_state.dart';

/// Side pop-up filter panel with the ordered filter sections.
class WatchFilterDrawer extends ConsumerStatefulWidget {
  const WatchFilterDrawer({super.key});

  @override
  ConsumerState<WatchFilterDrawer> createState() => _WatchFilterDrawerState();
}

class _WatchFilterDrawerState extends ConsumerState<WatchFilterDrawer> {
  final Map<String, bool> _expanded = {
    for (final k in _keys) k: k == 'price' || k == 'movement' || k == 'condition',
  };

  final Map<String, int> _visible = {
    'caseShape': 8,
    'caseBack': 8,
    'strapMaterial': 6,
    'crownType': 7,
    'strapColor': 8,
    'claspType': 7,
    'claspMaterial': 7,
    'glass': 7,
    'power': 6,
    'water': 6,
    'bezelType': 7,
    'bezelMaterial': 8,
  };

  static const _keys = [
    'price',
    'movement',
    'gender',
    'condition',
    'caseMaterial',
    'dialColor',
    'caseSize',
    'caseShape',
    'caseBack',
    'strapMaterial',
    'crownType',
    'strapColor',
    'claspType',
    'claspMaterial',
    'glass',
    'power',
    'water',
    'auth',
    'year',
    'cert',
    'bezelType',
    'bezelMaterial',
    'stones',
    'config',
    'material',
    'precious',
    'indexes',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(watchFilterDraftProvider.notifier).syncFromApplied();
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(watchFilterDraftProvider);
    final n = ref.read(watchFilterDraftProvider.notifier);

    return FilterEndDrawerShell(
      resetLabel: 'Clear',
      onReset: n.reset,
      onShowResults: () {
        n.apply();
        ref.read(watchListProvider.notifier).refresh();
        Navigator.of(context).maybePop();
      },
      body: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.s24),
                children: [
                  _section(
                    'price',
                    'PRICE RANGE',
                    _list(
                      WatchFilterState.priceRangeOptions,
                      draft.priceRanges,
                      n.togglePriceRange,
                    ),
                  ),
                  _section(
                    'movement',
                    'MOVEMENT',
                    _list(
                      WatchFilterState.movementOptions,
                      draft.movements,
                      n.toggleMovement,
                    ),
                  ),
                  _section(
                    'gender',
                    'GENDER',
                    _list(
                      WatchFilterState.genderOptions,
                      draft.genders,
                      n.toggleGender,
                    ),
                  ),
                  _section(
                    'condition',
                    'CONDITION',
                    _list(
                      WatchFilterState.conditionOptions,
                      draft.conditions,
                      n.toggleCondition,
                    ),
                  ),
                  _section(
                    'caseMaterial',
                    'CASE MATERIAL',
                    _list(
                      WatchFilterState.caseMaterialOptions,
                      draft.caseMaterials,
                      n.toggleCaseMaterial,
                    ),
                  ),
                  _section(
                    'dialColor',
                    'DIAL COLOR',
                    _expand(
                      'dialColor',
                      WatchFilterState.dialColorOptions,
                      draft.dialColors,
                      n.toggleDialColor,
                    ),
                  ),
                  _section(
                    'caseSize',
                    'CASE SIZE',
                    _list(
                      WatchFilterState.caseSizeRangeOptions,
                      draft.caseSizeRanges,
                      n.toggleCaseSizeRange,
                    ),
                  ),
                  _section(
                    'caseShape',
                    'CASE SHAPE',
                    _expand(
                      'caseShape',
                      WatchFilterState.caseShapeOptions,
                      draft.caseShapes,
                      n.toggleCaseShape,
                    ),
                  ),
                  _section(
                    'caseBack',
                    'CASE BACK',
                    _expand(
                      'caseBack',
                      WatchFilterState.caseBackOptions,
                      draft.caseBacks,
                      n.toggleCaseBack,
                    ),
                  ),
                  _section(
                    'strapMaterial',
                    'STRAP MATERIAL',
                    _expand(
                      'strapMaterial',
                      WatchFilterState.strapMaterialOptions,
                      draft.strapMaterials,
                      n.toggleStrapMaterial,
                    ),
                  ),
                  _section(
                    'crownType',
                    'CROWN TYPE',
                    _expand(
                      'crownType',
                      WatchFilterState.crownTypeOptions,
                      draft.crownTypes,
                      n.toggleCrownType,
                    ),
                  ),
                  _section(
                    'strapColor',
                    'STRAP COLOR',
                    _expand(
                      'strapColor',
                      WatchFilterState.strapColorOptions,
                      draft.strapColors,
                      n.toggleStrapColor,
                    ),
                  ),
                  _section(
                    'claspType',
                    'CLASP TYPE',
                    _expand(
                      'claspType',
                      WatchFilterState.claspTypeOptions,
                      draft.claspTypes,
                      n.toggleClaspType,
                    ),
                  ),
                  _section(
                    'claspMaterial',
                    'CLASP MATERIAL',
                    _expand(
                      'claspMaterial',
                      WatchFilterState.claspMaterialOptions,
                      draft.claspMaterials,
                      n.toggleClaspMaterial,
                    ),
                  ),
                  _section(
                    'glass',
                    'GLASS MATERIAL',
                    _expand(
                      'glass',
                      WatchFilterState.glassMaterialOptions,
                      draft.glassMaterials,
                      n.toggleGlassMaterial,
                    ),
                  ),
                  _section(
                    'power',
                    'POWER RESERVE',
                    _expand(
                      'power',
                      WatchFilterState.powerReserveOptions,
                      draft.powerReserves,
                      n.togglePowerReserve,
                    ),
                  ),
                  _section(
                    'water',
                    'WATER RESISTANCE',
                    _expand(
                      'water',
                      WatchFilterState.waterResistanceOptions,
                      draft.waterResistances,
                      n.toggleWaterResistance,
                    ),
                  ),
                  _section(
                    'auth',
                    'AUTHENTICATION',
                    _list(
                      WatchFilterState.authenticationOptions,
                      draft.authentications,
                      n.toggleAuthentication,
                    ),
                  ),
                  _section(
                    'year',
                    'MODEL YEAR',
                    _list(
                      WatchFilterState.modelYearOptions,
                      draft.modelYears,
                      n.toggleModelYear,
                    ),
                  ),
                  _section(
                    'cert',
                    'CERTIFICATION',
                    _list(
                      WatchFilterState.certificationOptions,
                      draft.certifications,
                      n.toggleCertification,
                    ),
                  ),
                  _section(
                    'bezelType',
                    'BEZEL TYPE',
                    _expand(
                      'bezelType',
                      WatchFilterState.bezelTypeOptions,
                      draft.bezelTypes,
                      n.toggleBezelType,
                    ),
                  ),
                  _section(
                    'bezelMaterial',
                    'BEZEL MATERIAL',
                    _expand(
                      'bezelMaterial',
                      WatchFilterState.bezelMaterialOptions,
                      draft.bezelMaterials,
                      n.toggleBezelMaterial,
                    ),
                  ),
                  _section(
                    'stones',
                    'STONES ON DIAL',
                    _list(
                      WatchFilterState.stonesOnDialOptions,
                      draft.stonesOnDial,
                      n.toggleStonesOnDial,
                    ),
                  ),
                  _section(
                    'config',
                    'COMPLICATION',
                    _list(
                      WatchFilterState.configurationOptions,
                      draft.configurations,
                      n.toggleConfiguration,
                    ),
                  ),
                  _section(
                    'material',
                    'FEATURES',
                    _list(
                      WatchFilterState.materialOptions,
                      draft.materials,
                      n.toggleMaterial,
                    ),
                  ),
                  _section(
                    'precious',
                    'PRECIOUS STONE TYPE',
                    _list(
                      WatchFilterState.preciousStoneTypeOptions,
                      draft.preciousStoneTypes,
                      n.togglePreciousStoneType,
                    ),
                  ),
                  _section(
                    'indexes',
                    'INDEXES',
                    _list(
                      WatchFilterState.indexesOptions,
                      draft.indexes,
                      n.toggleIndexes,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _section(String key, String title, Widget child) {
    final open = _expanded[key] ?? false;
    return FilterAccordionSection(
      title: title,
      expanded: open,
      onToggle: () => setState(() => _expanded[key] = !open),
      titleStyle: AppTypography.label.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontSize: 12,
      ),
      child: child,
    );
  }

  Widget _list(
    List<String> items,
    Set<String> selected,
    void Function(String) onToggle,
  ) {
    return Column(
      children: [
        for (final item in items)
          CheckboxListTile(
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(item, style: AppTypography.label.copyWith(fontSize: 13)),
            value: selected.contains(item),
            activeColor: AppColors.charcoal,
            onChanged: (_) => onToggle(item),
          ),
      ],
    );
  }

  Widget _expand(
    String key,
    List<String> values,
    Set<String> selected,
    void Function(String) onToggle,
  ) {
    final visible = _visible[key] ?? values.length;
    final showing = values.take(visible).toList();
    final remaining = values.length - showing.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in showing)
          CheckboxListTile(
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(item, style: AppTypography.label.copyWith(fontSize: 13)),
            value: selected.contains(item),
            activeColor: AppColors.charcoal,
            onChanged: (_) => onToggle(item),
          ),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.s20,
              bottom: AppSpacing.s12,
            ),
            child: TextButton(
              onPressed: () => setState(() => _visible[key] = values.length),
              child: Text(
                'Show all ($remaining)',
                style: AppTypography.caption.copyWith(
                  color: AppColors.bronze,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
