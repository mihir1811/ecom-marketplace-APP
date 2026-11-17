import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_validators.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../widgets/kit/auth_kit.dart';

/// Public screen to recover a scheduled-for-deletion account.
class RecoverAccountScreen extends ConsumerStatefulWidget {
  const RecoverAccountScreen({super.key, this.recoveryToken});

  final String? recoveryToken;

  @override
  ConsumerState<RecoverAccountScreen> createState() =>
      _RecoverAccountScreenState();
}

class _RecoverAccountScreenState extends ConsumerState<RecoverAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _useToken = true;
  bool _didAutoRedirect = false;
  bool _submitted = false;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    final token = widget.recoveryToken?.trim() ?? '';
    if (token.isNotEmpty) {
      _tokenController.text = token;
      _useToken = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pasteToken() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty || !mounted) return;
    AppHaptics.selection();
    _tokenController.text = text;
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

    _submitted = true;
    await notifier.recoverAccount(
      token: _useToken ? _tokenController.text : null,
      email: _useToken ? null : _emailController.text,
      password: _useToken ? null : _passwordController.text,
    );
    if (!mounted) return;
    final after = ref.read(authProvider);
    if (after.accountRecovered) {
      AppHaptics.success();
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
          accountRecovered: s.accountRecovered,
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

    if (_submitted && authState.accountRecovered && !_didAutoRedirect) {
      _didAutoRedirect = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        AuthToast.show(
          context,
          context.tr(AccountCommerceL10n.accountRecovered),
        );
        context.go(AppRouteNames.login);
      });
    }

    final loading = authState.isLoading;

    return AuthShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHero(
              eyebrow: context.tr(AccountCommerceL10n.recoverAccount),
              title: context.tr(AuthL10n.recoverTitle),
            ),
            const SizedBox(height: AuthSpace.s24),
            AuthReveal(
              index: 4,
              child: AuthNotice(
                icon: Icons.hourglass_bottom_rounded,
                title: context.tr(AuthL10n.recoverWindow),
                body: context.tr(AuthL10n.recoverWindowBody),
              ),
            ),
            const SizedBox(height: AuthSpace.s24),
            AuthReveal(
              index: 5,
              child: AuthSegmented<bool>(
                value: _useToken,
                enabled: !loading,
                segments: [
                  AuthSegment(
                    value: true,
                    label: context.tr(AuthL10n.useToken),
                    icon: Icons.vpn_key_outlined,
                  ),
                  AuthSegment(
                    value: false,
                    label: context.tr(AuthL10n.useCredentials),
                    icon: Icons.alternate_email_rounded,
                  ),
                ],
                onChanged: (next) {
                  AppHaptics.selection();
                  setState(() => _useToken = next);
                  ref.read(authProvider.notifier).clearError();
                },
              ),
            ),
            const SizedBox(height: AuthSpace.s20),
            AuthReveal(
              index: 6,
              child: AuthShake(
                trigger: _shake,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedSize(
                      duration: AuthMotion.base,
                      curve: AuthMotion.ease,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: AuthMotion.base,
                        child: _useToken
                            ? AuthTextField(
                                key: const ValueKey('token'),
                                controller: _tokenController,
                                label: context.tr(
                                  AccountCommerceL10n.recoveryToken,
                                ),
                                icon: Icons.vpn_key_outlined,
                                textInputAction: TextInputAction.done,
                                enabled: !loading,
                                onSubmitted: (_) => _submit(),
                                suffix: IconButton(
                                  tooltip: context.tr(AuthL10n.paste),
                                  icon: const Icon(
                                    Icons.content_paste_rounded,
                                    size: 19,
                                  ),
                                  onPressed: loading ? null : _pasteToken,
                                ),
                                validator: (value) {
                                  if (!_useToken) return null;
                                  if ((value?.trim() ?? '').isEmpty) {
                                    return context.tr(
                                      AccountCommerceL10n.recoveryTokenRequired,
                                    );
                                  }
                                  return null;
                                },
                              )
                            : Column(
                                key: const ValueKey('credentials'),
                                children: [
                                  AuthTextField(
                                    controller: _emailController,
                                    label: context.tr(
                                      AccountCommerceL10n.email,
                                    ),
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    enabled: !loading,
                                    validator: (value) {
                                      if (_useToken) return null;
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
                                  const SizedBox(height: AuthSpace.s12),
                                  AuthPasswordField(
                                    controller: _passwordController,
                                    label: context.tr(
                                      AccountCommerceL10n.password,
                                    ),
                                    enabled: !loading,
                                    onSubmitted: (_) => _submit(),
                                    validator: (value) {
                                      if (_useToken) return null;
                                      if ((value ?? '').isEmpty) {
                                        return context.tr(
                                          AccountCommerceL10n.passwordRequired,
                                        );
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: AuthSpace.s20),
                    AuthErrorBanner(
                      message: authState.errorMessage,
                      onDismiss: () =>
                          ref.read(authProvider.notifier).clearError(),
                    ),
                    AuthPrimaryButton(
                      label: context.tr(AuthL10n.recoverAction),
                      loading: loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AuthSpace.s24),
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
      ),
    );
  }
}
