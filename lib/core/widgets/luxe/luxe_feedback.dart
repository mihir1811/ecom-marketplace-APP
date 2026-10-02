import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/luxe_scope.dart';
import '../../theme/luxe_tokens.dart';
import 'luxe_button.dart';

enum LuxeTone { neutral, success, error, info }

/// Floating toast for confirmations and recoverable errors.
///
/// Uses the nearest [ScaffoldMessenger], so it survives navigation, and
/// adds a leading tone icon plus an optional action (e.g. "View cart").
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
  final p = LuxePalette.of(context);
  final (icon, iconColor) = switch (tone) {
    LuxeTone.success => (Icons.check_circle_rounded, const Color(0xFF7BC8A0)),
    LuxeTone.error => (Icons.error_outline_rounded, const Color(0xFFE59A7E)),
    LuxeTone.info => (Icons.info_outline_rounded, p.accent),
    LuxeTone.neutral => (Icons.auto_awesome_outlined, p.accent),
  };
  const ink = Color(0xFFF3EEE6);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        backgroundColor: const Color(0xFF16140F),
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
        ),
        content: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: LuxeType.label(ink, size: 13.5)),
            ),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: LuxePalette.dark.accent,
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
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
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: LuxeType.display(28, p.ink),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: LuxeType.body(p.inkMuted, size: 14),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 24),
                LuxeButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  icon: tone == LuxeTone.error ? Icons.refresh_rounded : null,
                ),
              ],
              if (secondaryLabel != null) ...[
                const SizedBox(height: 6),
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
                const SizedBox(height: 10),
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
                  padding: const EdgeInsets.fromLTRB(24, 18, 12, 6),
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
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          child: builder(sheetContext),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
