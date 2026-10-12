import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../widgets/kit/auth_kit.dart';

/// OTP verification after registration.
class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  static const _cooldownSeconds = 30;

  final _otpController = TextEditingController();
  bool _didAutoRedirect = false;
  bool _resendBusy = false;
  String? _otpError;
  int _shake = 0;
  int _cooldown = _cooldownSeconds;
  Timer? _timer;

  String get _email {
    final fromState =
        ref.read(authProvider).pendingVerificationEmail?.trim() ?? '';
    if (fromState.isNotEmpty) return fromState;
    return widget.email?.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _verify(String email) async {
    final notifier = ref.read(authProvider.notifier);
    if (ref.read(authProvider).isLoading || email.isEmpty) return;
    notifier.clearError();

    if (_otpController.text.trim().length != 6) {
      AppHaptics.error();
      setState(() {
        _otpError = context.tr(AccountCommerceL10n.enterOtp);
        _shake++;
      });
      return;
    }
    setState(() => _otpError = null);

    await notifier.verifyOtp(email: email, otp: _otpController.text);
    if (!mounted) return;
    final after = ref.read(authProvider);
    if (after.isAuthenticated) {
      AppHaptics.success();
    } else if (after.errorMessage != null) {
      AppHaptics.error();
      setState(() => _shake++);
    }
  }

  Future<void> _resend(String email) async {
    setState(() => _resendBusy = true);
    final ok = await ref.read(authProvider.notifier).resendOtp(email: email);
    if (!mounted) return;
    setState(() => _resendBusy = false);
    if (ok) {
      AppHaptics.success();
      _otpController.clear();
      _startCooldown();
      AuthToast.show(
        context,
        context.tr(AccountCommerceL10n.otpSent),
        icon: Icons.mark_email_read_outlined,
      );
    } else {
      AppHaptics.error();
    }
  }

  String _formatCooldown() {
    final s = _cooldown.clamp(0, 999);
    return '0:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(
      authProvider.select(
        (s) => (
          isAuthenticated: s.isAuthenticated,
          isLoading: s.isLoading,
          errorMessage: s.errorMessage,
          pendingEmail: s.pendingVerificationEmail,
        ),
      ),
    );

    if (authState.isAuthenticated && !_didAutoRedirect) {
      _didAutoRedirect = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(AppRouteNames.home);
      });
    }

    final email = (authState.pendingEmail?.trim().isNotEmpty == true)
        ? authState.pendingEmail!.trim()
        : _email;
    final loading = authState.isLoading;
    final p = AuthPalette.of(context);
    final hasError = _otpError != null || authState.errorMessage != null;
    final canResend =
        !loading && !_resendBusy && email.isNotEmpty && _cooldown <= 0;

    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHero(
            cut: GemCut.princess,
            eyebrow: context.tr(AccountCommerceL10n.verifyEmail),
            title: context.tr(AuthL10n.otpTitle),
            subtitle: email.isEmpty
                ? Text(context.tr(AccountCommerceL10n.enterSixDigitCode))
                : Text(
                    context.tr(AccountCommerceL10n.codeSentToEmail, {
                      'email': email,
                    }),
                  ),
          ),
          const SizedBox(height: AuthSpace.s32),
          AuthReveal(
            index: 4,
            child: AuthShake(
              trigger: _shake,
              child: AuthOtpInput(
                controller: _otpController,
                enabled: !loading && email.isNotEmpty,
                error: hasError,
                onCompleted: () => _verify(email),
              ),
            ),
          ),
          AnimatedSize(
            duration: AuthMotion.base,
            curve: AuthMotion.ease,
            child: _otpError == null
                ? const SizedBox(width: double.infinity, height: AuthSpace.s24)
                : Padding(
                    padding: const EdgeInsets.only(
                      top: AuthSpace.s12,
                      bottom: AuthSpace.s12,
                    ),
                    child: Text(
                      _otpError!,
                      textAlign: TextAlign.center,
                      style: AuthType.caption(p).copyWith(color: p.danger),
                    ),
                  ),
          ),
          AuthErrorBanner(
            message: authState.errorMessage,
            onDismiss: () => ref.read(authProvider.notifier).clearError(),
          ),
          AuthReveal(
            index: 5,
            child: AuthPrimaryButton(
              label: context.tr(AuthL10n.verify),
              loading: loading && !_resendBusy,
              onPressed: email.isEmpty || loading ? null : () => _verify(email),
            ),
          ),
          const SizedBox(height: AuthSpace.s24),
          AuthReveal(
            index: 6,
            child: Column(
              children: [
                Text(context.tr(AuthL10n.noCode), style: AuthType.caption(p)),
                AuthTextLink(
                  emphasis: canResend,
                  icon: _resendBusy ? null : Icons.refresh_rounded,
                  label: _resendBusy
                      ? context.tr(AuthL10n.pleaseWait)
                      : _cooldown > 0
                      ? context.tr(AuthL10n.resendIn, {
                          'time': _formatCooldown(),
                        })
                      : context.tr(AuthL10n.resendCode),
                  onPressed: canResend ? () => _resend(email) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AuthSpace.s16),
          AuthReveal(
            index: 7,
            child: Center(
              child: AuthTextLink(
                icon: Icons.arrow_back_rounded,
                label: context.tr(AccountCommerceL10n.backToLogin),
                onPressed: loading
                    ? null
                    : () => context.go(AppRouteNames.login),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
