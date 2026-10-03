import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../domain/models/diamond_viewer_args.dart';
import '../../domain/models/diamond_viewer_config.dart';
import '../../domain/models/diamond_viewer_load_state.dart';
import '../widgets/diamond_viewer.dart';

/// Immersive full-screen 360° stage.
///
/// Dark obsidian chrome keeps attention on the stone: a glass close /
/// reload header, the viewer filling the stage, and gesture hints that
/// appear once the stone is ready and then step aside. Chrome sits beside
/// (never over) the web view, because hybrid-composition platform views
/// draw above Flutter siblings.
class DiamondViewerScreen extends StatefulWidget {
  const DiamondViewerScreen({
    required this.args,
    super.key,
    this.config = DiamondViewerConfig.standard,
  });

  final DiamondViewerArgs args;
  final DiamondViewerConfig config;

  @override
  State<DiamondViewerScreen> createState() => _DiamondViewerScreenState();
}

class _DiamondViewerScreenState extends State<DiamondViewerScreen> {
  int _generation = 0;
  bool _ready = false;
  bool _showHints = false;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _onState(DiamondViewerLoadState state) {
    final ready = state is DiamondViewerReady;
    if (ready == _ready) return;
    // Called from the viewer's build path; defer our own rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _ready = ready;
        _showHints = ready;
      });
      _hintTimer?.cancel();
      if (ready) {
        _hintTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _showHints = false);
        });
      }
    });
  }

  /// Rebuilds the viewer from scratch (fresh web view and load state).
  void _reload() {
    AppHaptics.selection();
    _hintTimer?.cancel();
    setState(() {
      _generation++;
      _ready = false;
      _showHints = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.args.subtitle;
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: LuxeStage.obsidian,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12, top + 8, 12, 10),
              child: Row(
                children: [
                  LuxeIconButton(
                    icon: Icons.close_rounded,
                    tooltip: context.tr(CatalogL10n.close),
                    glass: true,
                    size: 42,
                    onPressed: () => context.goBack(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '360° VIEW',
                          style: LuxeType.eyebrow(
                            LuxeStage.gold,
                          ).copyWith(fontSize: 9.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.args.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.display(21, LuxeStage.ink),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuxeType.label(LuxeStage.inkMuted, size: 12),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  LuxeIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: context.tr(CatalogL10n.tryAgain),
                    glass: true,
                    size: 42,
                    onPressed: _reload,
                  ),
                ],
              ),
            ),
            Container(height: 0.6, color: LuxeStage.glassBorder),
            Expanded(
              child: ColoredBox(
                color: LuxeStage.obsidian,
                child: DiamondViewer(
                  key: ValueKey(_generation),
                  viewerUrl: widget.args.viewerUrl,
                  config: widget.config,
                  onLoadStateChanged: _onState,
                ),
              ),
            ),
            // Fixed height so showing / hiding hints never resizes the web
            // view (which would make the viewer re-layout mid-rotation).
            AnimatedOpacity(
              opacity: _showHints ? 1 : 0,
              duration: LuxeMotion.medium,
              child: _GestureHints(
                text: context.tr(CatalogL10n.viewerGestureHint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rotate / zoom hints under the stage.
class _GestureHints extends StatelessWidget {
  const _GestureHints({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    Widget hint(IconData icon, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: LuxeStage.gold),
        const SizedBox(width: 6),
        Text(label, style: LuxeType.label(LuxeStage.ink, size: 12)),
      ],
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                hint(Icons.swipe_rounded, 'Drag to rotate'),
                const SizedBox(width: 22),
                hint(Icons.pinch_rounded, 'Pinch to zoom'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: LuxeType.label(LuxeStage.inkMuted, size: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}
