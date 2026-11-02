import 'package:flutter/material.dart';

import 'luxe_tokens.dart';

/// Marks a subtree as a luxe surface.
///
/// Shared building blocks (filter chips, cards, [AppColors] lookups) check
/// [LuxeScope.paletteOf] and switch to the luxe palette and shapes, so a
/// whole flow can be re-skinned without forking every widget. Screens outside
/// a scope are unaffected. The scope also installs a matching [Theme] for
/// Material pieces (inputs, checkboxes, snack bars, progress, dropdowns).
class LuxeScope extends StatelessWidget {
  const LuxeScope({required this.child, super.key});

  final Widget child;

  /// Luxe palette when [context] is inside a scope, otherwise null.
  /// Cheap: reads the marker without registering a dependency.
  static LuxePalette? paletteOf(BuildContext context) {
    final marker = context.getInheritedWidgetOfExactType<_LuxeMarker>();
    if (marker == null) return null;
    return LuxePalette.of(context);
  }

  static bool isActive(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_LuxeMarker>() != null;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final p = LuxePalette.of(context);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
      borderSide: BorderSide(color: c, width: w),
    );

    final theme = base.copyWith(
      scaffoldBackgroundColor: p.canvas,
      colorScheme: base.colorScheme.copyWith(
        primary: p.ink,
        onPrimary: p.canvas,
        secondary: p.accent,
        surface: p.surface,
        onSurface: p.ink,
        outline: p.hairline,
      ),
      dividerColor: p.hairline,
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        circularTrackColor: p.hairline,
        linearTrackColor: p.hairline,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: p.inkFaint, width: 1.2),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.ink : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(p.canvas),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: LuxeType.body(p.inkFaint, size: 14),
        labelStyle: LuxeType.label(p.inkMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: border(p.hairline),
        enabledBorder: border(p.hairline),
        focusedBorder: border(p.ink, 1.3),
        errorBorder: border(p.caution),
        focusedErrorBorder: border(p.caution, 1.3),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accent.withValues(alpha: 0.25),
        selectionHandleColor: p.accent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.isDark ? p.surfaceRaised : p.ink,
        contentTextStyle: LuxeType.label(
          p.isDark ? p.ink : p.canvas,
          size: 13.5,
        ),
        actionTextColor: p.accent,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.surface),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
            ),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
          side: BorderSide(color: p.hairline),
        ),
      ),
      canvasColor: p.surface,
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxeSpace.radius),
        ),
        titleTextStyle: LuxeType.display(26, p.ink),
        contentTextStyle: LuxeType.body(p.inkMuted, size: 14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: p.ink,
        inactiveTrackColor: p.hairline,
        thumbColor: p.ink,
        overlayColor: p.accent.withValues(alpha: 0.12),
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 9,
          elevation: 1,
        ),
        trackHeight: 2.5,
      ),
    );

    return Theme(
      data: theme,
      child: _LuxeMarker(child: child),
    );
  }
}

class _LuxeMarker extends InheritedWidget {
  const _LuxeMarker({required super.child});

  @override
  bool updateShouldNotify(_LuxeMarker oldWidget) => false;
}
