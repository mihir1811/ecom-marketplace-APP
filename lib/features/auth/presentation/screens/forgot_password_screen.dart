import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_validators.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../widgets/kit/auth_kit.dart';

/// Request a password reset link; morphs into a "check your inbox" state.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _didAutoRedirect = false;

  /// Only show the sent state for a request made on this screen visit.
  bool _submitted = false;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send({bool resend = false}) async {
    final notifier = ref.read(authProvider.notifier);
    if (ref.read(authProvider).isLoading) return;
    notifier.clearError();

    if (!resend) {
      final ok = _formKey.currentState?.validate() ?? false;
      if (!ok) {
        AppHaptics.error();
        setState(() => _shake++);
        return;
      }
    }

    await notifier.sendResetLink(email: _emailController.text);
    if (!mounted) return;
    final after = ref.read(authProvider);
    if (after.resetLinkSent) {
      AppHaptics.success();
      setState(() => _submitted = true);
      if (resend) {
        AuthToast.show(context, context.tr(AccountCommerceL10n.resetLinkSent));
      }
    } else if (after.errorMessage != null) {
      AppHaptics.error();
      setState(() => _shake++);
      if (resend) {
        AuthToast.show(
          context,
          after.errorMessage!,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(
      authProvider.select(
        (s) => (
          isAuthenticated: s.isAuthenticated,
          isLoading: s.isLoading,
          errorMessage: s.errorMessage,
          resetLinkSent: s.resetLinkSent,
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

    final loading = authState.isLoading;
    final sent = _submitted && authState.resetLinkSent;

    return AuthShell(
      child: AnimatedSwitcher(
        duration: AuthMotion.slow,
        switchInCurve: AuthMotion.ease,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween(begin: 0.97, end: 1.0).animate(a),
            child: child,
          ),
        ),
        child: sent
            ? AuthResultView(
                key: const ValueKey('sent'),
                icon: Icons.mark_email_read_outlined,
                title: context.tr(AuthL10n.inboxTitle),
                body: context.tr(AuthL10n.inboxBody, {
                  'email': _emailController.text.trim(),
                }),
                actions: [
                  AuthPrimaryButton(
                    label: context.tr(AccountCommerceL10n.backToLogin),
                    onPressed: () => context.go(AppRouteNames.login),
                  ),
                  AuthSecondaryButton(
                    label: context.tr(AuthL10n.resendLink),
                    icon: Icons.refresh_rounded,
                    onPressed: loading ? null : () => _send(resend: true),
                  ),
                  Center(
                    child: AuthTextLink(
                      label: context.tr(AuthL10n.useDifferentEmail),
                      onPressed: loading
                          ? null
                          : () => setState(() => _submitted = false),
                    ),
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: Column(
                  key: const ValueKey('form'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHero(
                      eyebrow: context.tr(AccountCommerceL10n.resetPassword),
                      title: context.tr(AuthL10n.forgotTitle),
                      subtitle: Text(
                        context.tr(AccountCommerceL10n.forgotInstructions),
                      ),
                    ),
                    const SizedBox(height: AuthSpace.s32),
                    AuthReveal(
                      index: 4,
                      child: AuthShake(
                        trigger: _shake,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthTextField(
                              controller: _emailController,
                              label: context.tr(AccountCommerceL10n.email),
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.email],
                              enabled: !loading,
                              onSubmitted: (_) => _send(),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) {
                                  return context.tr(
                                    AccountCommerceL10n.emailRequired,
                                  );
                                }
                                if (!isValidEmail(v)) {
                                  return context.tr(
                                    AccountCommerceL10n.validEmail,
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AuthSpace.s20),
                            AuthErrorBanner(
                              message: authState.errorMessage,
                              onDismiss: () =>
                                  ref.read(authProvider.notifier).clearError(),
                            ),
                            AuthPrimaryButton(
                              label: context.tr(AuthL10n.sendLink),
                              loading: loading,
                              onPressed: _send,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AuthSpace.s24),
                    AuthReveal(
                      index: 5,
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
              ),
      ),
    );
  }
}
