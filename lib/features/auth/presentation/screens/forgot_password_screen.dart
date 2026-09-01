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
import '../widgets/auth_theme.dart';

/// Forgot password screen matching the provided UI reference.
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

  @override
  void dispose() {
    _emailController.dispose();
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

    return AppScaffold(
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
                      Text(
                        context.tr(AccountCommerceL10n.forgotPassword),
                        style: AppTypography.display.copyWith(
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        context.tr(AccountCommerceL10n.forgotInstructions),
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s24),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: context.tr(
                                  AccountCommerceL10n.email,
                                ),
                                prefixIcon: const Icon(Icons.mail_outline),
                              ),
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
                                            .sendResetLink(
                                              email: _emailController.text,
                                            );
                                      },
                                style: authFilledButtonStyle(context),
                                child: authState.isLoading
                                    ? authButtonSpinner(context)
                                    : Text(
                                        context.tr(
                                          AccountCommerceL10n.sendResetLink,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.s12),

                            if (authState.errorMessage != null) ...[
                              Text(
                                authState.errorMessage!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],

                            if (authState.resetLinkSent) ...[
                              const SizedBox(height: AppSpacing.s16),
                              Text(
                                context.tr(AccountCommerceL10n.resetLinkSent),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.s24),

                      Center(
                        child: TextButton(
                          onPressed: authState.isLoading
                              ? null
                              : () => context.go(AppRouteNames.login),
                          child: Text(
                            context.tr(AccountCommerceL10n.backToLogin),
                            style: AppTypography.label.copyWith(
                              color: AppColors.textPrimary(context),
                              decoration: TextDecoration.underline,
                            ),
                          ),
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
    );
  }
}
