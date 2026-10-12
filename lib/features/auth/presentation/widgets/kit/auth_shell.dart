import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/app_navigation.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../../../core/widgets/gem3d/gem_view.dart';
import '../../../../../core/widgets/language_menu_button.dart';
import '../../../../../core/widgets/theme_toggle_button.dart';
import 'auth_backdrop.dart';
import 'auth_hero.dart';
import 'auth_theme_data.dart';
import 'auth_tokens.dart';

/// Width at which auth screens split into showcase + form.
const double kAuthWideBreakpoint = 960;

bool authIsWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kAuthWideBreakpoint;

/// Frame shared by every auth screen: silk backdrop, a quiet top bar
/// (back · wordmark · language · theme) and a centred, scrollable column.
/// On wide screens a showcase panel with a large live gem sits on the left.
class AuthShell extends StatefulWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.showBack = true,
    this.fallbackLocation = AppRouteNames.login,
  });

  final Widget child;
  final bool showBack;
  final String fallbackLocation;

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell> {
  final _pointer = ValueNotifier<Offset>(const Offset(0.5, 0.5));

  @override
  void dispose() {
    _pointer.dispose();
    super.dispose();
  }

  void _track(PointerEvent event) {
    final size = MediaQuery.sizeOf(context);
    if (size.isEmpty) return;
    _pointer.value = Offset(
      (event.position.dx / size.width).clamp(0.0, 1.0),
      (event.position.dy / size.height).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    final wide = authIsWide(context);

    final column = _AuthColumn(
      showBack: widget.showBack,
      fallbackLocation: widget.fallbackLocation,
      child: widget.child,
    );

    return Theme(
      data: authThemeData(Theme.of(context), palette),
      child: AppScaffold(
        backgroundColor: palette.bg,
        enableAppDrawer: false,
        safeTop: false,
        safeBottom: false,
        body: Listener(
          onPointerHover: _track,
          onPointerMove: _track,
          child: Stack(
            children: [
              Positioned.fill(
                child: AuthBackdrop(
                  pointer: _pointer,
                  focus: wide
                      ? const Offset(0.28, 0.42)
                      : const Offset(0.5, 0.16),
                ),
              ),
              SafeArea(
                child: wide
                    ? Row(
                        children: [
                          const Expanded(child: _ShowcasePanel()),
                          Container(width: 1, color: palette.hairline),
                          SizedBox(width: 560, child: column),
                        ],
                      )
                    : column,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthColumn extends StatelessWidget {
  const _AuthColumn({
    required this.child,
    required this.showBack,
    required this.fallbackLocation,
  });

  final Widget child;
  final bool showBack;
  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          _AuthTopBar(showBack: showBack, fallbackLocation: fallbackLocation),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AuthSpace.s24,
                AuthSpace.s8,
                AuthSpace.s24,
                AuthSpace.s40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AuthSpace.contentMaxWidth,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTopBar extends StatelessWidget {
  const _AuthTopBar({required this.showBack, required this.fallbackLocation});

  final bool showBack;
  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final wide = authIsWide(context);
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AuthSpace.s12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!wide) const AuthWordmark(),
            Row(
              children: [
                if (showBack)
                  AuthIconCircle(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => AppNavigation.back(
                      context,
                      fallbackLocation: fallbackLocation,
                    ),
                  ),
                const Spacer(),
                IconTheme.merge(
                  data: IconThemeData(color: p.inkSoft),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LanguageMenuButton(iconSize: 20),
                      ThemeToggleButton(size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small circular glass button used for back/close affordances.
class AuthIconCircle extends StatelessWidget {
  const AuthIconCircle({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: p.surface,
        shape: CircleBorder(side: BorderSide(color: p.hairline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, size: 20, color: p.ink),
          ),
        ),
      ),
    );
  }
}

class _ShowcasePanel extends StatelessWidget {
  const _ShowcasePanel();

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final reduced = AuthMotion.reduced(context);
    Widget reveal(Widget child, int i) => reduced
        ? child
        : child
              .animate(delay: AuthMotion.stagger(i))
              .fadeIn(duration: AuthMotion.entrance, curve: AuthMotion.ease)
              .moveY(begin: 24, end: 0, curve: AuthMotion.ease);

    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 40, 48, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthWordmark(),
          Expanded(
            child: Center(
              child: reveal(
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const AuthHalo(size: 420),
                    GemView(
                      cut: GemCut.round,
                      look: p.isDark ? GemLook.white : GemLook.champagne,
                      size: 300,
                      spin: 0.32,
                      tilt: 0.5,
                      interactive: true,
                      semanticLabel: context.tr(AuthL10n.gemLabel),
                    ),
                  ],
                ),
                0,
              ),
            ),
          ),
          reveal(
            Text(
              context.tr(AuthL10n.showcaseTitle),
              style: AuthType.display(p).copyWith(fontSize: 54, height: 1.0),
            ),
            1,
          ),
          const SizedBox(height: AuthSpace.s16),
          reveal(
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                context.tr(AuthL10n.showcaseBody),
                style: AuthType.body(p).copyWith(fontSize: 16),
              ),
            ),
            2,
          ),
          const SizedBox(height: AuthSpace.s32),
          reveal(
            Wrap(
              spacing: AuthSpace.s24,
              runSpacing: AuthSpace.s12,
              children: [
                _TrustMark(
                  icon: Icons.verified_outlined,
                  label: context.tr(AuthL10n.trustVerified),
                ),
                _TrustMark(
                  icon: Icons.diamond_outlined,
                  label: context.tr(AuthL10n.trustCertified),
                ),
                _TrustMark(
                  icon: Icons.lock_outline_rounded,
                  label: context.tr(AuthL10n.trustSecure),
                ),
              ],
            ),
            3,
          ),
        ],
      ),
    );
  }
}

class _TrustMark extends StatelessWidget {
  const _TrustMark({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: p.accent),
        const SizedBox(width: AuthSpace.s8),
        Text(label, style: AuthType.caption(p).copyWith(color: p.inkSoft)),
      ],
    );
  }
}
