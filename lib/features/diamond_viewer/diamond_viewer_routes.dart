import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/navigator_keys.dart';
import '../../core/router/route_names.dart';
import '../product_detail/presentation/screens/certificate_viewer_screen.dart';
import 'domain/models/diamond_viewer_args.dart';
import 'presentation/screens/diamond_viewer_screen.dart';

final List<RouteBase> diamondViewerRoutes = [
  GoRoute(
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
            title: state.uri.queryParameters['title'] ?? '360° View',
          ),
        );
      }

      return const Scaffold(
        body: Center(child: Text('Missing 360° viewer URL')),
      );
    },
  ),
  GoRoute(
    path: AppRouteNames.certificateViewer,
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) {
      final extra = state.extra;
      if (extra is CertificateViewerArgs) {
        return CertificateViewerScreen(args: extra);
      }
      final url = state.uri.queryParameters['url'];
      if (url != null && url.isNotEmpty) {
        return CertificateViewerScreen(
          args: CertificateViewerArgs(
            url: Uri.decodeComponent(url),
            title: state.uri.queryParameters['title'] ?? 'Certificate',
          ),
        );
      }
      return const Scaffold(
        body: Center(child: Text('Missing certificate URL')),
      );
    },
  ),
];
