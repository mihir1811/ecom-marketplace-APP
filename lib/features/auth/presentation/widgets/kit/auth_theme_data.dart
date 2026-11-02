import 'package:flutter/material.dart';
import 'package:gemstone/core/theme/app_fonts.dart';

import 'auth_tokens.dart';

/// Local [ThemeData] for auth screens so stock Material pieces (text fields,
/// date picker, menus, selection handles) speak the auth kit's language.
ThemeData authThemeData(ThemeData base, AuthPalette p) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AuthSpace.rField),
        borderSide: BorderSide(color: color, width: width),
      );

  final scheme = ColorScheme(
    brightness: p.isDark ? Brightness.dark : Brightness.light,
    primary: p.accent,
    onPrimary: p.isDark ? p.onCta : const Color(0xFFFFFFFF),
    secondary: p.accent,
    onSecondary: p.onCta,
    error: p.danger,
    onError: p.isDark ? const Color(0xFF1A0E0B) : const Color(0xFFFFFFFF),
    surface: p.isDark ? const Color(0xFF141317) : const Color(0xFFFBF8F2),
    onSurface: p.ink,
    onSurfaceVariant: p.inkSoft,
    outline: p.hairlineStrong,
    outlineVariant: p.hairline,
    surfaceContainerHighest: p.isDark
        ? const Color(0xFF1C1B20)
        : const Color(0xFFF1EBE0),
  );

  final fieldText = AuthType.field(p);

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    textTheme: AppFonts.secondaryTextTheme(
      base.textTheme,
    ).apply(bodyColor: p.ink, displayColor: p.ink),
    iconTheme: IconThemeData(color: p.ink, size: 22),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accent.withValues(alpha: 0.28),
      selectionHandleColor: p.accent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WidgetStateColor.resolveWith(
        (states) =>
            states.contains(WidgetState.focused) ? p.surfaceFocus : p.surface,
      ),
      hoverColor: p.surfaceFocus,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AuthSpace.s20,
        vertical: 12,
      ),
      border: border(p.hairline),
      enabledBorder: border(p.hairline),
      focusedBorder: border(p.accent, 1.4),
      errorBorder: border(p.danger.withValues(alpha: 0.7)),
      focusedErrorBorder: border(p.danger, 1.4),
      disabledBorder: border(p.hairline.withValues(alpha: 0.5)),
      labelStyle: fieldText.copyWith(color: p.inkMuted),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => AuthType.caption(p).copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          color: states.contains(WidgetState.error)
              ? p.danger
              : states.contains(WidgetState.focused)
              ? p.accent
              : p.inkMuted,
        ),
      ),
      hintStyle: fieldText.copyWith(color: p.inkMuted),
      helperStyle: AuthType.caption(p),
      errorStyle: AuthType.caption(p).copyWith(color: p.danger),
      errorMaxLines: 3,
      prefixIconColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.error)
            ? p.danger
            : states.contains(WidgetState.focused)
            ? p.accent
            : p.inkMuted,
      ),
      suffixIconColor: p.inkMuted,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AuthSpace.rCard),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: scheme.surface,
      headerBackgroundColor: scheme.surface,
      headerForegroundColor: p.ink,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AuthSpace.rCard),
      ),
      headerHeadlineStyle: AuthType.title(p),
      todayBorder: BorderSide(color: p.accent),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      textStyle: AuthType.label(p),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AuthSpace.rField),
        side: BorderSide(color: p.hairline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.accent,
        textStyle: AuthType.label(p),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: p.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: AuthType.caption(p).copyWith(color: p.bg),
    ),
  );
}
