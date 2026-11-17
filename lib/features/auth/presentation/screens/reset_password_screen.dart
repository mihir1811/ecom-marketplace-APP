import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_validators.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../widgets/kit/auth_kit.dart';

/// Reset password screen opened from email deep link (`?token=`).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.resetToken});

  final String? resetToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
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
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit(String token) async {
    final notifier = ref.read(authProvider.notifier);
    if (ref.read(authProvider).isLoading || token.isEmpty) return;
    notifier.clearError();
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      AppHaptics.error();
      setState(() => _shake++);
      return;
    }
    await notifier.resetPassword(
      resetToken: token,
      newPassword: _passwordController.text,
    );
    if (!mounted) return;
    final after = ref.read(authProvider);
    if (after.passwordResetSuccess) {
      AppHaptics.success();
      setState(() => _submitted = true);
    } else if (after.errorMessage != null) {
      AppHaptics.error();
      setState(() => _shake++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(
      authProvider.select(
        (s) => (
          isLoading: s.isLoading,
          errorMessage: s.errorMessage,
          passwordResetSuccess: s.passwordResetSuccess,
        ),
      ),
    );

    final token = widget.resetToken?.trim() ?? '';
    final loading = authState.isLoading;
    final done = _submitted && authState.passwordResetSuccess;

    final Widget body;
    if (token.isEmpty) {
      body = AuthResultView(
        key: const ValueKey('invalid'),
        tone: AuthResultTone.problem,
        title: context.tr(AuthL10n.linkInvalidTitle),
        body: context.tr(AccountCommerceL10n.missingResetToken),
        actions: [
          AuthPrimaryButton(
            label: context.tr(AuthL10n.requestNewLink),
            onPressed: () => context.go(AppRouteNames.forgotPassword),
          ),
          Center(
            child: AuthTextLink(
              icon: Icons.arrow_back_rounded,
              label: context.tr(AccountCommerceL10n.backToLogin),
              onPressed: () => context.go(AppRouteNames.login),
            ),
          ),
        ],
      );
    } else if (done) {
      body = AuthResultView(
        key: const ValueKey('done'),
        title: context.tr(AuthL10n.passwordUpdated),
        body: context.tr(AccountCommerceL10n.passwordResetSuccess),
        actions: [
          AuthPrimaryButton(
            label: context.tr(AccountCommerceL10n.goToLogin),
            onPressed: () => context.go(AppRouteNames.login),
          ),
        ],
      );
    } else {
      body = _ResetForm(
        key: const ValueKey('form'),
        formKey: _formKey,
        password: _passwordController,
        confirm: _confirmController,
        shake: _shake,
        loading: loading,
        errorMessage: authState.errorMessage,
        onSubmit: () => _submit(token),
      );
    }

    return AuthShell(
      child: AnimatedSwitcher(
        duration: AuthMotion.slow,
        switchInCurve: AuthMotion.ease,
        child: body,
      ),
    );
  }
}

class _ResetForm extends ConsumerWidget {
  const _ResetForm({
    super.key,
    required this.formKey,
    required this.password,
    required this.confirm,
    required this.shake,
    required this.loading,
    required this.errorMessage,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController password;
  final TextEditingController confirm;
  final int shake;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AuthPalette.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHero(
            eyebrow: context.tr(AccountCommerceL10n.resetPassword),
            title: context.tr(AuthL10n.resetTitle),
            subtitle: Text(context.tr(AccountCommerceL10n.chooseNewPassword)),
          ),
          const SizedBox(height: AuthSpace.s32),
          AuthReveal(
            index: 4,
            child: AuthShake(
              trigger: shake,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthPasswordField(
                    controller: password,
                    label: context.tr(AccountCommerceL10n.newPassword),
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !loading,
                    validator: (value) {
                      final strength = evaluatePasswordStrength(value ?? '');
                      if (!strength.isStrong) {
                        return localizePasswordStrength(context, strength);
                      }
                      return null;
                    },
                  ),
                  ListenableBuilder(
                    listenable: password,
                    builder: (context, _) =>
                        AuthPasswordMeter(password: password.text),
                  ),
                  const SizedBox(height: AuthSpace.s20),
                  AuthPasswordField(
                    controller: confirm,
                    label: context.tr(AccountCommerceL10n.confirmPassword),
                    icon: Icons.lock_reset_rounded,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !loading,
                    onSubmitted: (_) => onSubmit(),
                    validator: (value) {
                      if (value != password.text) {
                        return context.tr(
                          AccountCommerceL10n.passwordsDoNotMatch,
                        );
                      }
                      return null;
                    },
                  ),
                  ListenableBuilder(
                    listenable: Listenable.merge([password, confirm]),
                    builder: (context, _) {
                      final match =
                          confirm.text.isNotEmpty &&
                          confirm.text == password.text;
                      return AnimatedSize(
                        duration: AuthMotion.base,
                        curve: AuthMotion.ease,
                        child: match
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  top: AuthSpace.s8,
                                  left: AuthSpace.s4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 15,
                                      color: p.success,
                                    ),
                                    const SizedBox(width: AuthSpace.s6),
                                    Text(
                                      context.tr(AuthL10n.passwordsMatch),
                                      style: AuthType.caption(
                                        p,
                                      ).copyWith(color: p.success),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(width: double.infinity),
                      );
                    },
                  ),
                  const SizedBox(height: AuthSpace.s24),
                  AuthErrorBanner(
                    message: errorMessage,
                    onDismiss: () =>
                        ref.read(authProvider.notifier).clearError(),
                  ),
                  AuthPrimaryButton(
                    label: context.tr(AuthL10n.updatePassword),
                    loading: loading,
                    onPressed: onSubmit,
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
    );
  }
}
