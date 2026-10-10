import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'navigation/app_drawer_stage.dart';

/// Opens the nearest drawer: the page's [AppDrawerStage], else a [Scaffold]
/// drawer (parent shell preferred).
void openAppDrawer(BuildContext context) {
  final stage = AppDrawerStage.maybeOf(context);
  if (stage != null) {
    stage.open();
    return;
  }

  ScaffoldState? withDrawer(ScaffoldState? state) =>
      (state != null && state.hasDrawer) ? state : null;

  final nearest = withDrawer(Scaffold.maybeOf(context));
  if (nearest != null) {
    nearest.openDrawer();
    return;
  }

  ScaffoldState? found;
  context.visitAncestorElements((element) {
    if (element is! StatefulElement) return true;
    final state = element.state;
    if (state is ScaffoldState && state.hasDrawer) {
      found = state;
      return false;
    }
    return true;
  });
  found?.openDrawer();
}

/// Global side-drawer menu button — same always-on pattern as theme toggle.
class AppDrawerButton extends StatelessWidget {
  const AppDrawerButton({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.tr(RemainingL10n.menu),
      icon: Icon(Icons.menu, size: size),
      onPressed: () => openAppDrawer(context),
    );
  }
}
