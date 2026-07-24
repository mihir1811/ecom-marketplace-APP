import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_validators.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Forgot password screen matching the provided UI reference.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
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
    final authState = ref.watch(authProvider);

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
                        'Forgot Password',
                        style: AppTypography.display.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: AppSpacing.s12),
                      Text(
                        'Enter your registered email and we will send you a reset link.',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      SizedBox(height: AppSpacing.s24),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) return 'Email is required';
                                if (!isValidEmail(v)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: AppSpacing.s16),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () async {
                                        ref
                                            .read(authProvider.notifier)
                                            .clearError();

                                        final ok = _formKey.currentState
                                                ?.validate() ??
                                            false;
                                        if (!ok) return;

                                        await ref
                                            .read(authProvider.notifier)
                                            .sendResetLink(
                                              email: _emailController.text,
                                            );
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.charcoal,
                                  foregroundColor: AppColors.warmWhite,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.s16,
                                    horizontal: AppSpacing.s24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppSpacing.r8),
                                  ),
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.warmWhite,
                                        ),
                                      )
                                    : const Text('Send Reset Link'),
                              ),
                            ),

                            SizedBox(height: AppSpacing.s12),

                            if (authState.errorMessage != null) ...[
                              Text(
                                authState.errorMessage!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],

                            if (authState.resetLinkSent) ...[
                              SizedBox(height: AppSpacing.s16),
                              Text(
                                'Reset link sent. Please check your email.',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: AppSpacing.s24),

                      Center(
                        child: TextButton(
                          onPressed: authState.isLoading
                              ? null
                              : () => context.go(AppRouteNames.login),
                          child: Text(
                            'Back to login',
                            style: AppTypography.label.copyWith(
                              color: AppColors.charcoal,
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

