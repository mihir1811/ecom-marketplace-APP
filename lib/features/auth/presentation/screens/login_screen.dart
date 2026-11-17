import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_validators.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_system_back_scope.dart';
import '../widgets/kit/auth_kit.dart';

/// Sign in with username/email + password.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _didAutoRedirect = false;
  int _shake = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(authProvider.notifier);
    if (ref.read(authProvider).isLoading) return;
    notifier.clearError();

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      AppHaptics.error();
      setState(() => _shake++);
      return;
    }

    await notifier.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    final after = ref.read(authProvider);
    if (after.isAuthenticated) {
      AppHaptics.success();
      TextInput.finishAutofillContext();
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
          isAuthenticated: s.isAuthenticated,
          isLoading: s.isLoading,
          errorMessage: s.errorMessage,
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

    return AppSystemBackScope(
      child: AuthShell(
        showBack: GoRouter.of(context).canPop(),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHero(
                  eyebrow: context.tr(AccountCommerceL10n.signInToGemWorld),
                  title: context.tr(AuthL10n.welcomeTitle),
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
                          controller: _usernameController,
                          label: context.tr(AuthL10n.usernameOrEmail),
                          icon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                          enabled: !loading,
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) {
                              return context.tr(
                                AccountCommerceL10n.enterUsername,
                              );
                            }
                            if (v.contains('@') && !isValidEmail(v)) {
                              return context.tr(
                                AccountCommerceL10n.validEmailOrUsername,
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AuthSpace.s12),
                        AuthPasswordField(
                          controller: _passwordController,
                          label: context.tr(AccountCommerceL10n.password),
                          enabled: !loading,
                          onSubmitted: (_) => _submit(),
                          validator: (value) {
                            final v = value ?? '';
                            if (v.isEmpty) {
                              return context.tr(
                                AccountCommerceL10n.enterPassword,
                              );
                            }
                            if (v.length < 6) {
                              return context.tr(
                                AccountCommerceL10n.passwordMin6,
                              );
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: AuthTextLink(
                            label: context.tr(
                              AccountCommerceL10n.forgotPasswordAction,
                            ),
                            onPressed: loading
                                ? null
                                : () => context.push(
                                    AppRouteNames.forgotPassword,
                                  ),
                          ),
                        ),
                        const SizedBox(height: AuthSpace.s8),
                        AuthErrorBanner(
                          message: authState.errorMessage,
                          onDismiss: () =>
                              ref.read(authProvider.notifier).clearError(),
                        ),
                        AuthPrimaryButton(
                          label: context.tr(AuthL10n.signIn),
                          loading: loading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AuthSpace.s32),
                AuthReveal(
                  index: 5,
                  child: _OrDivider(label: context.tr(AuthL10n.newHere)),
                ),
                const SizedBox(height: AuthSpace.s16),
                AuthReveal(
                  index: 6,
                  child: AuthSecondaryButton(
                    label: context.tr(AuthL10n.createAccount),
                    icon: Icons.person_add_alt_outlined,
                    onPressed: loading
                        ? null
                        : () => context.switchAuthRoute(AppRouteNames.register),
                  ),
                ),
                const SizedBox(height: AuthSpace.s20),
                AuthReveal(
                  index: 7,
                  child: Center(
                    child: AuthTextLink(
                      icon: Icons.history_rounded,
                      label: context.tr(
                        AccountCommerceL10n.recoverDeletedAccount,
                      ),
                      onPressed: loading
                          ? null
                          : () => context.push(AppRouteNames.recoverAccount),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: p.hairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AuthSpace.s16),
          child: Text(label, style: AuthType.caption(p)),
        ),
        Expanded(child: Container(height: 1, color: p.hairline)),
      ],
    );
  }
}
