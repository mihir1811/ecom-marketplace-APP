import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/widgets/keyboard_aware.dart';
import 'atelier_components.dart';
import 'atelier_motion.dart';
import 'atelier_theme.dart';

/// Calm empty state with a softly floating emblem.
class AtelierEmptyState extends StatelessWidget {
  const AtelierEmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.diamond_outlined,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    Widget emblem = Container(
      width: compact ? 64 : 84,
      height: compact ? 64 : 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [p.goldSoft, p.goldSoft.withValues(alpha: 0)],
        ),
        border: Border.all(color: p.gold.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: compact ? 26 : 32, color: p.gold),
    );
    if (!context.reduceMotion) {
      emblem = emblem
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: -3, end: 3, duration: 2600.ms, curve: Curves.easeInOut);
    }
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AtelierSpace.s24,
        vertical: compact ? AtelierSpace.s24 : AtelierSpace.s48,
      ),
      child: Reveal(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            emblem,
            const SizedBox(height: AtelierSpace.s20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AtelierType.display(p.ink, size: compact ? 20 : 24),
            ),
            const SizedBox(height: AtelierSpace.s8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AtelierType.body(p.muted, size: 13.5),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AtelierSpace.s20),
              AtelierButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AtelierButtonVariant.secondary,
                compact: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Recoverable error with retry.
class AtelierErrorState extends StatelessWidget {
  const AtelierErrorState({
    required this.message,
    required this.onRetry,
    this.title = 'Something went quiet',
    this.compact = false,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AtelierEmptyState(
      icon: Icons.cloud_off_rounded,
      title: title,
      message: message,
      actionLabel: 'Try again',
      onAction: onRetry,
      compact: compact,
    );
  }
}

/// Inline banner for non-blocking information or errors.
class AtelierNotice extends StatelessWidget {
  const AtelierNotice({
    required this.text,
    this.tone = AtelierTone.neutral,
    this.icon = Icons.info_outline_rounded,
    this.actionLabel,
    this.onAction,
    this.dense = false,
    super.key,
  });

  final String text;
  final AtelierTone tone;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Borderless, tight variant for use inside list cards.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final c = p.tone(tone);
    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 5)
          : const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: p.isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(
          dense ? AtelierRadius.sm : AtelierRadius.md,
        ),
        border: dense ? null : Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: dense ? 13 : 17, color: c),
          SizedBox(width: dense ? 6 : 10),
          Expanded(
            child: Text(
              text,
              style: AtelierType.caption(p.inkSoft, size: dense ? 11.5 : 12.5),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: c),
              child: Text(actionLabel!, style: AtelierType.label(c, size: 12)),
            ),
        ],
      ),
    );
  }
}

/// Skeleton stand-in for a list of cards.
class AtelierSkeletonList extends StatelessWidget {
  const AtelierSkeletonList({
    this.count = 4,
    this.height = 120,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final int count;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AtelierSpace.s12),
              child: AtelierSkeletonCard(height: height),
            ),
        ],
      ),
    );
  }
}

class AtelierSkeletonCard extends StatelessWidget {
  const AtelierSkeletonCard({this.height = 120, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      height: height,
      padding: const EdgeInsets.all(AtelierSpace.s16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(color: p.hairline),
      ),
      // Short rows (ledger, inbox) get two lines; taller cards get three.
      child: Row(
        crossAxisAlignment: height < 100
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 36, height: 36, radius: 18),
          const SizedBox(width: AtelierSpace.s12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 140, height: 13),
                const SizedBox(height: 6),
                const SkeletonBox(height: 10),
                if (height >= 100) ...const [
                  SizedBox(height: 6),
                  SkeletonBox(width: 180, height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(width: AtelierSpace.s12),
          const SkeletonBox(width: 64, height: 14),
        ],
      ),
    );
  }
}

/// Floating toast in place of stock snackbars.
void showAtelierToast(
  BuildContext context,
  String message, {
  AtelierTone tone = AtelierTone.neutral,
  IconData? icon,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  showAtelierToastOn(
    messenger,
    context.atelier,
    message,
    tone: tone,
    icon: icon,
  );
}

/// Toast for callers that captured the messenger before an async gap.
void showAtelierToastOn(
  ScaffoldMessengerState messenger,
  AtelierPalette p,
  String message, {
  AtelierTone tone = AtelierTone.neutral,
  IconData? icon,
}) {
  final accent = tone == AtelierTone.neutral ? p.gold : p.tone(tone);
  final glyph =
      icon ??
      switch (tone) {
        AtelierTone.emerald => Icons.check_circle_rounded,
        AtelierTone.ruby => Icons.error_outline_rounded,
        AtelierTone.amber => Icons.schedule_rounded,
        _ => Icons.auto_awesome_rounded,
      };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: p.isDark ? p.raised : p.onyx,
            borderRadius: BorderRadius.circular(AtelierRadius.md),
            border: Border.all(
              color: p.isDark ? p.hairline : Colors.transparent,
            ),
            boxShadow: p.floatShadow,
          ),
          child: Row(
            children: [
              Icon(glyph, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: AtelierType.label(
                    p.isDark ? p.ink : p.onOnyx,
                    size: 13,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

/// Bottom sheet with the workspace's surface, handle and optional title.
Future<T?> showAtelierSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  String? subtitle,
  bool isDismissible = true,
  bool scrollable = true,
}) {
  final theme = Theme.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (sheetContext) {
      return Theme(
        data: theme,
        child: Builder(
          builder: (context) {
            final p = context.atelier;
            final body = builder(context);
            return AppKeyboardInset(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.92,
                  maxWidth: 720,
                ),
                decoration: BoxDecoration(
                  color: p.raised,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AtelierRadius.xl),
                  ),
                  border: Border(top: BorderSide(color: p.hairline)),
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
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: p.hairline,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      if (title != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AtelierType.display(p.ink, size: 26),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: AtelierType.caption(
                                    p.muted,
                                    size: 12.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      Flexible(
                        child: scrollable
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  16,
                                ),
                                child: body,
                              )
                            : body,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

/// Modal dialog with blurred backdrop and a soft scale-in.
Future<T?> showAtelierDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final theme = Theme.of(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.38),
    transitionDuration: AtelierMotion.base,
    pageBuilder: (dialogContext, _, _) {
      return Theme(
        data: theme,
        child: SafeArea(
          minimum: const EdgeInsets.all(12),
          child: AppKeyboardInset(child: Center(child: builder(dialogContext))),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AtelierMotion.emphasized,
        reverseCurve: Curves.easeIn,
      );
      return BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: 6 * animation.value,
          sigmaY: 6 * animation.value,
        ),
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Consistent dialog surface: title, message, body, actions.
class AtelierDialogFrame extends StatelessWidget {
  const AtelierDialogFrame({
    required this.title,
    required this.actions,
    this.message,
    this.content,
    this.icon,
    this.tone = AtelierTone.gold,
    this.maxWidth = 440,
    super.key,
  });

  final String title;
  final String? message;
  final Widget? content;
  final List<Widget> actions;
  final IconData? icon;
  final AtelierTone tone;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: p.raised,
            borderRadius: BorderRadius.circular(AtelierRadius.xl),
            border: Border.all(color: p.hairline),
            boxShadow: p.floatShadow,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  AtelierIconBadge(icon: icon!, tone: tone, size: 44),
                  const SizedBox(height: 12),
                ],
                Text(title, style: AtelierType.display(p.ink, size: 26)),
                if (message != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    message!,
                    style: AtelierType.body(p.inkSoft, size: 13.5),
                  ),
                ],
                if (content != null) ...[const SizedBox(height: 12), content!],
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: actions[i]),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One row in [showAtelierOptions].
class AtelierOption<T> {
  const AtelierOption({
    required this.value,
    required this.label,
    this.icon,
    this.selected = false,
    this.destructive = false,
    this.hint,
  });

  final T value;
  final String label;
  final IconData? icon;
  final bool selected;
  final bool destructive;
  final String? hint;
}

/// Action / single-choice sheet (sort menus, overflow actions).
Future<T?> showAtelierOptions<T>({
  required BuildContext context,
  required String title,
  required List<AtelierOption<T>> options,
  String? subtitle,
}) {
  return showAtelierSheet<T>(
    context: context,
    title: title,
    subtitle: subtitle,
    builder: (context) {
      final p = context.atelier;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++)
            Reveal(
              index: i,
              offset: 8,
              child: Pressable(
                onTap: () => Navigator.of(context).pop(options[i].value),
                semanticLabel: options[i].label,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: options[i].selected
                        ? p.goldSoft
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AtelierRadius.md),
                  ),
                  child: Row(
                    children: [
                      if (options[i].icon != null) ...[
                        Icon(
                          options[i].icon,
                          size: 19,
                          color: options[i].destructive ? p.ruby : p.inkSoft,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              options[i].label,
                              style: AtelierType.label(
                                options[i].destructive ? p.ruby : p.ink,
                                size: 14,
                              ),
                            ),
                            if (options[i].hint != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                options[i].hint!,
                                style: AtelierType.caption(p.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (options[i].selected)
                        Icon(Icons.check_rounded, size: 18, color: p.gold),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// Simple yes/no confirmation in the workspace style.
Future<bool> showAtelierConfirm({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
}) async {
  final result = await showAtelierDialog<bool>(
    context: context,
    builder: (context) => AtelierDialogFrame(
      title: title,
      message: message,
      icon: icon ?? (destructive ? Icons.delete_outline_rounded : null),
      tone: destructive ? AtelierTone.ruby : AtelierTone.gold,
      actions: [
        AtelierButton(
          label: cancelLabel,
          variant: AtelierButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AtelierButton(
          label: confirmLabel,
          variant: destructive
              ? AtelierButtonVariant.danger
              : AtelierButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}
