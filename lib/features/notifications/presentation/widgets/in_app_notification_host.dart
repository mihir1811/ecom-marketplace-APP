import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/navigator_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/in_app_notification_provider.dart';
import '../../domain/models/app_notification.dart';
import '../open_notification.dart';
import 'notification_tile.dart';

/// Top-of-screen banner for pushes that arrive while the app is open, and
/// the router for tapped system notifications.
///
/// Sits above the navigator in `MaterialApp.builder`. Only the banner itself
/// takes touches; it never moves focus or navigates unless tapped.
class InAppNotificationHost extends ConsumerStatefulWidget {
  const InAppNotificationHost({super.key});

  /// Long enough to read a two-line message; touching the banner pauses it.
  static const visibleFor = Duration(seconds: 6);

  @override
  ConsumerState<InAppNotificationHost> createState() =>
      _InAppNotificationHostState();
}

class _InAppNotificationHostState extends ConsumerState<InAppNotificationHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, -1.4), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );

  AppNotification? _shown;
  Timer? _dismissTimer;
  var _closing = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      inAppNotificationProvider.select((s) => s.current),
      (_, next) => _onCurrentChanged(next),
      fireImmediately: true,
    );
    ref.listenManual(
      inAppNotificationProvider.select((s) => s.pendingOpen != null),
      (_, hasPending) {
        if (hasPending) _openPendingWhenReady();
      },
      fireImmediately: true,
    );
    ref.listenManual(authProvider.select((s) => s.isBootstrapping), (
      _,
      booting,
    ) {
      if (!booting) _openPendingWhenReady();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _controller.duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 280);
    _controller.reverseDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onCurrentChanged(AppNotification? next) {
    _dismissTimer?.cancel();
    if (next == null) {
      if (_shown == null) return;
      if (_closing) {
        setState(() => _shown = null);
        _closing = false;
        return;
      }
      // Cleared from outside (sign-out): slide away, then drop it.
      _closing = true;
      _controller.reverse().then((_) {
        if (!mounted || ref.read(inAppNotificationProvider).current != null) {
          return;
        }
        setState(() => _shown = null);
        _closing = false;
      });
      return;
    }
    _closing = false;
    setState(() => _shown = next);
    _controller.forward();
    _startDismissTimer();
  }

  void _startDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(InAppNotificationHost.visibleFor, _close);
  }

  /// Holding the banner keeps it up; the countdown restarts on release.
  void _pauseDismiss() => _dismissTimer?.cancel();

  void _resumeDismiss() {
    if (_shown == null || _closing) return;
    _startDismissTimer();
  }

  Future<void> _close() async {
    if (_closing || _shown == null) return;
    _closing = true;
    _dismissTimer?.cancel();
    await _controller.reverse();
    if (!mounted || !_closing) return;
    ref.read(inAppNotificationProvider.notifier).dismiss();
  }

  void _onTap() {
    final notification = _shown;
    if (notification == null) return;
    unawaited(_close());
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;
    unawaited(
      openNotification(navContext, ref, notification, fallbackToInbox: true),
    );
  }

  /// A tapped system notification is routed once the session is restored
  /// and the navigator has been built.
  void _openPendingWhenReady() {
    if (ref.read(authProvider).isBootstrapping) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(authProvider).isBootstrapping) return;
      final navContext = rootNavigatorKey.currentContext;
      if (navContext == null) return;
      final notification = ref
          .read(inAppNotificationProvider.notifier)
          .takePendingOpen();
      if (notification == null) return;
      unawaited(
        openNotification(navContext, ref, notification, fallbackToInbox: true),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final notification = _shown;
    final waiting = ref.watch(
      inAppNotificationProvider.select((s) => s.queue.length),
    );
    if (notification == null) return const SizedBox.shrink();
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s12,
            AppSpacing.s16,
            0,
          ),
          child: SlideTransition(
            position: _slide,
            // Taps here count as "inside" any focused text field, so typing
            // is not interrupted on platforms that unfocus on outside taps.
            child: TextFieldTapRegion(
              child: Listener(
                onPointerDown: (_) => _pauseDismiss(),
                onPointerUp: (_) => _resumeDismiss(),
                onPointerCancel: (_) => _resumeDismiss(),
                child: _Banner(
                  notification: notification,
                  waiting: waiting,
                  onTap: _onTap,
                  onClose: _close,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.notification,
    required this.waiting,
    required this.onTap,
    required this.onClose,
  });

  final AppNotification notification;

  /// Banners queued behind this one; shown as "+N" so none feel lost.
  final int waiting;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final title = notification.title.trim();
    final body = notification.body.trim();
    final radius = BorderRadius.circular(AppSpacing.r16);
    return Semantics(
      container: true,
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: GestureDetector(
          // Flick up to dismiss.
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) < -150) onClose();
          },
          child: Material(
            color: AppColors.card(context),
            elevation: 8,
            shadowColor: Colors.black38,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: AppColors.border(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s12,
                  AppSpacing.s4,
                  AppSpacing.s12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.bg(context),
                        borderRadius: BorderRadius.circular(AppSpacing.r12),
                      ),
                      child: Icon(
                        notificationTypeIcon(notification.type),
                        size: 20,
                        color: AppColors.bronze,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title.isNotEmpty || waiting > 0)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.label.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                ),
                                if (waiting > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: AppSpacing.s8,
                                    ),
                                    child: Text(
                                      '+$waiting',
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.bronze,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          if (body.isNotEmpty) ...[
                            if (title.isNotEmpty)
                              const SizedBox(height: AppSpacing.s4),
                            Text(
                              body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary(context),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // No tooltip: the host sits above the navigator's Overlay.
                    IconButton(
                      onPressed: onClose,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.textMuted(context),
                        semanticLabel: context.tr(CoreL10n.close),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
