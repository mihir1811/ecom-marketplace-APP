import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_validators.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_system_back_scope.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_theme.dart';

/// Login screen (Username + Password) matching the provided UI reference.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _didAutoRedirect = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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

    return AppSystemBackScope(
      child: AppScaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthBrandHeader(
                        eyebrow: context.tr(AccountCommerceL10n.welcomeBack),
                        subtitle: context.tr(
                          AccountCommerceL10n.signInToGemWorld,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      Text(
                        'Login',
                        style: AppTypography.display.copyWith(
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s24),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: context.tr(
                                  AccountCommerceL10n.username,
                                ),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
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
                            const SizedBox(height: AppSpacing.s16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: context.tr(
                                  AccountCommerceL10n.password,
                                ),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? context.tr(
                                          AccountCommerceL10n.showPassword,
                                        )
                                      : context.tr(
                                          AccountCommerceL10n.hidePassword,
                                        ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
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
                            const SizedBox(height: AppSpacing.s12),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () => context.push(
                                        AppRouteNames.forgotPassword,
                                      ),
                                child: Text(
                                  context.tr(
                                    AccountCommerceL10n.forgotPasswordAction,
                                  ),
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.textPrimary(context),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () => context.push(
                                        AppRouteNames.recoverAccount,
                                      ),
                                child: Text(
                                  context.tr(
                                    AccountCommerceL10n.recoverDeletedAccount,
                                  ),
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.textPrimary(context),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),

                            if (authState.errorMessage != null) ...[
                              const SizedBox(height: AppSpacing.s16),
                              Text(
                                authState.errorMessage!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],

                            const SizedBox(height: AppSpacing.s16),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () async {
                                        ref
                                            .read(authProvider.notifier)
                                            .clearError();

                                        final ok =
                                            _formKey.currentState?.validate() ??
                                            false;
                                        if (!ok) return;

                                        await ref
                                            .read(authProvider.notifier)
                                            .login(
                                              username:
                                                  _usernameController.text,
                                              password:
                                                  _passwordController.text,
                                            );
                                      },
                                style: authFilledButtonStyle(context),
                                child: authState.isLoading
                                    ? authButtonSpinner(context)
                                    : Text(
                                        'Sign in \u2192',
                                        style: AppTypography.label.copyWith(
                                          color: AppColors.onSelected(context),
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.s24),

                            Center(
                              child: TextButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () =>
                                          context.push(AppRouteNames.register),
                                child: Text(
                                  context.tr(
                                    AccountCommerceL10n.createAccountPrompt,
                                  ),
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
