import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'live_stage_tokens.dart';

// Built once: the sheet rebuilds on every keyboard frame, and a ThemeData
// is costly to make.
final _sheetTheme = ThemeData.dark(useMaterial3: true).copyWith(
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: LiveStage.champagne,
    selectionHandleColor: LiveStage.champagne,
  ),
);

/// Noir bottom sheet for everything opened over the stage: a grab handle,
/// a serif title, an optional line under it, then [builder]'s content,
/// which fades up a beat after the sheet lands.
Future<T?> showLiveSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  String? subtitle,
  Widget? trailing,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 420),
      reverseDuration: Duration(milliseconds: 240),
      curve: LiveMotion.emphasized,
    ),
    builder: (sheetContext) {
      final inset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final safe = MediaQuery.paddingOf(sheetContext).bottom;
      final still = MediaQuery.disableAnimationsOf(sheetContext);
      Widget content = Builder(builder: builder);
      if (!still) {
        content = content
            .animate()
            .fadeIn(delay: 80.ms, duration: 280.ms)
            .slideY(
              begin: 0.04,
              end: 0,
              duration: 380.ms,
              curve: LiveMotion.ease,
            );
      }
      return Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.86,
          ),
          decoration: BoxDecoration(
            color: LiveStage.obsidian,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: LiveStage.hairlineStrong)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Theme(
            data: _sheetTheme,
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 10),
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: LiveStage.hairlineStrong,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: LiveType.display(28)),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: LiveType.body(13),
                                ),
                              ],
                            ],
                          ),
                        ),
                        ?trailing,
                        LiveIconButton(
                          icon: Icons.close_rounded,
                          tooltip: 'Close',
                          size: 38,
                          onTap: () => Navigator.of(sheetContext).maybePop(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: inset > 0 ? 0 : safe),
                      child: content,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
