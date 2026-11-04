import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/navigator_keys.dart';
import '../../core/router/route_names.dart';
import 'domain/models/diamond_viewer_args.dart';
import 'presentation/screens/diamond_viewer_screen.dart';

final List<RouteBase> diamondViewerRoutes = [
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.diamondViewer,
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) {
      final extra = state.extra;
      if (extra is DiamondViewerArgs) {
        return DiamondViewerScreen(args: extra);
      }

      final queryUrl = state.uri.queryParameters['url'];
      if (queryUrl != null && queryUrl.isNotEmpty) {
        return DiamondViewerScreen(
          args: DiamondViewerArgs(
            viewerUrl: Uri.decodeComponent(queryUrl),
            title:
                state.uri.queryParameters['title'] ??
                context.tr(CatalogL10n.viewerTitle),
          ),
        );
      }

      return Scaffold(
        body: Center(child: Text(context.tr(CatalogL10n.viewerMissingUrl))),
      );
    },
  ),
];
