import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/luxe_scope.dart';
import '../../theme/luxe_tokens.dart';
import 'luxe_button.dart';
import '../../theme/app_palette.dart';

enum LuxeTone { neutral, success, error, info }

/// Floating toast for confirmations and recoverable errors.
///
/// Uses the nearest [ScaffoldMessenger], so it survives navigation, with an
/// optional action (e.g. "Undo"). Always auto-dismisses after [duration],
/// even when it carries an action.
void showLuxeToast(
  BuildContext context,
  String message, {
  LuxeTone tone = LuxeTone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(milliseconds: 2600),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  switch (tone) {
    case LuxeTone.success:
      AppHaptics.success();
    case LuxeTone.error:
      AppHaptics.error();
    case LuxeTone.info || LuxeTone.neutral:
      AppHaptics.light();
  }
  final day = AppPalette.current.day.luxe;
  final ink = day.canvas;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        // Snack bars with an action persist by default; keep this one timed.
        persist: false,
        backgroundColor: day.ink,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
        ),
        content: Text(message, style: LuxeType.label(ink, size: 13.5)),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: AppPalette.current.night.luxe.accent,
                onPressed: onAction ?? () {},
              ),
      ),
    );
}

/// Shimmering placeholder block used to build skeleton loaders.
class LuxeSkeleton extends StatelessWidget {
  const LuxeSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.child,
  });

  final double? width;
  final double height;
  final double radius;

  /// When set, shimmers this whole composed skeleton instead of a block.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final content =
        child ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
    if (MediaQuery.disableAnimationsOf(context)) return content;
    return content
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1500.ms,
          color: p.isDark ? const Color(0x14FFFFFF) : const Color(0x8CFFFFFF),
        );
  }
}

/// Centered empty / error state with a soft icon medallion and an action.
class LuxeStateView extends StatelessWidget {
  const LuxeStateView({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.tone = LuxeTone.neutral,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final LuxeTone tone;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final tint = tone == LuxeTone.error ? p.caution : p.accent;
    Widget view = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint.withValues(alpha: 0.1),
                  border: Border.all(color: tint.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, size: 34, color: tint),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: LuxeType.display(28, p.ink),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: LuxeType.body(p.inkMuted, size: 14),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 16),
                LuxeButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  icon: tone == LuxeTone.error ? Icons.refresh_rounded : null,
                ),
              ],
              if (secondaryLabel != null) ...[
                const SizedBox(height: 5),
                LuxeButton(
                  label: secondaryLabel!,
                  onPressed: onSecondary,
                  variant: LuxeButtonVariant.ghost,
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (!MediaQuery.disableAnimationsOf(context)) {
      view = view
          .animate()
          .fadeIn(duration: 500.ms)
          .moveY(begin: 16, end: 0, duration: 700.ms, curve: LuxeMotion.settle);
    }
    return view;
  }
}

/// Opens a luxe modal bottom sheet with a grab handle and serif title.
///
/// The sheet content is re-wrapped in the caller's theme so luxe styling
/// carries across the route boundary.
Future<T?> showLuxeSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  String? subtitle,
  bool scrollable = true,
}) {
  final theme = Theme.of(context);
  final luxe = LuxeScope.isActive(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (sheetContext) {
      final p = LuxePalette.of(context);
      final inset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final sheet = Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.88,
          ),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: LuxeType.display(28, p.ink)),
                            if (subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: LuxeType.body(p.inkMuted, size: 13.5),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          sheetContext,
                        ).closeButtonTooltip,
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: Icon(Icons.close_rounded, color: p.inkMuted),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: scrollable
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                          child: builder(sheetContext),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                          child: builder(sheetContext),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
      // Re-enter the caller's styling across the route boundary.
      return luxe ? LuxeScope(child: sheet) : Theme(data: theme, child: sheet);
    },
  );
}
