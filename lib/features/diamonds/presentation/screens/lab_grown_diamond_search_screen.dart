import 'package:flutter/material.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/models/diamond_catalog_type.dart';
import 'diamond_search_screen.dart';

/// Lab-grown diamond finder — same components as [DiamondSearchScreen],
/// wired to the lab-grown catalog and its own filter/list provider scope.
class LabGrownDiamondSearchScreen extends StatelessWidget {
  const LabGrownDiamondSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DiamondSearchScreen(
      catalog: DiamondCatalogType.labGrown,
      title: 'LAB GROWN FINDER',
      resultsRoute: AppRouteNames.labGrownDiamondResults,
    );
  }
}
