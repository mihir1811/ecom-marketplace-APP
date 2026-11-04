import '../l10n/translations/account_commerce_messages.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../error/result.dart';
import '../network/dio_provider.dart';
import 'auth_repository.dart';
import 'auth_session.dart';
import 'auth_state.dart';
import 'auth_token_store.dart';
import 'auth_user.dart';
import 'auth_validators.dart';
import 'business_registration_data.dart';
import 'jwt_utils.dart';
import 'seller_account_snapshot.dart';
import '../riverpod/dispose_tolerant.dart';

/// Auth session controller: login, register/OTP, logout, password reset, cold start.
class AuthController extends Notifier<AuthState>
    with DisposeTolerantNotifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  AuthTokenStore get _store => ref.read(authTokenStoreProvider);

  Timer? _expiryTimer;

  @override
  AuthState build() {
    ref.onDispose(() {
      _expiryTimer?.cancel();
      _expiryTimer = null;
    });
    ref.listen<int>(authSessionInvalidatorProvider, (prev, next) {
      if (prev != next) {
        _cancelExpiryTimer();
        // Storage is already cleared by AuthInterceptor; reset auth UI state.
        state = const AuthState();
      }
    });
    Future.microtask(_bootstrap);
    return const AuthState(isBootstrapping: true);
  }

  /// Restores a persisted session from storage by decoding JWT `exp` / claims.
  Future<void> _bootstrap() async {
    try {
      final token = await _store.readAccessToken();
      if (!ref.mounted) return;
      if (token == null || token.isEmpty) {
        state = const AuthState(isBootstrapping: false);
        return;
      }

      final claims = JwtUtils.decodePayload(token);
      if (claims == null || JwtUtils.isExpired(token)) {
        await _clearLocalSession();
        if (!ref.mounted) return;
        state = const AuthState(isBootstrapping: false);
        return;
      }

      final cachedUserId = await _store.readUserId();
      if (!ref.mounted) return;
      final cachedUserName = await _store.readUserName();
      if (!ref.mounted) return;
      final cachedRole = await _store.readRole();
      if (!ref.mounted) return;
      final cachedSellerId = await _store.readSellerId();
      if (!ref.mounted) return;
      final cachedIsVerified = await _store.readIsVerified();
      if (!ref.mounted) return;
      final cachedSellerAccount = _decodeSellerSnapshot(
        await _store.readSellerAccountSnapshot(),
      );
      if (!ref.mounted) return;

      // Only trust disk identity fields when they belong to this JWT subject.
      // Stale sellerId / snapshot from a prior account causes "not found" on
      // seller/buyer protected screens after account switch on device.
      final jwtUserId = _jwtSubject(claims);
      final cacheMatches =
          cachedUserId != null &&
          cachedUserId.isNotEmpty &&
          (jwtUserId == null || jwtUserId.isEmpty || cachedUserId == jwtUserId);

      final user = AuthUser.fromJwtClaims(
        claims,
        cachedUserId: cacheMatches ? cachedUserId : null,
        cachedUserName: cacheMatches ? cachedUserName : null,
        cachedRole: cacheMatches ? cachedRole : null,
        cachedIsVerified: cacheMatches ? cachedIsVerified : null,
        cachedSellerAccount: cacheMatches ? cachedSellerAccount : null,
      );
      if (user.id.isEmpty) {
        await _clearLocalSession();
        if (!ref.mounted) return;
        state = const AuthState(isBootstrapping: false);
        return;
      }

      final sellerId =
          JwtUtils.readSellerId(claims) ??
          (cacheMatches ? cachedSellerId : null);

      // Drop mismatched leftovers so the next cold start cannot revive them.
      if (!cacheMatches) {
        await _store.saveSession(
          accessToken: token,
          userId: user.id,
          sellerId: sellerId,
          userName: user.username.isEmpty ? null : user.username,
          role: user.role.isEmpty ? null : user.role,
          isVerified: user.isVerified,
          rememberDevice: true,
        );
        if (!ref.mounted) return;
        final snap = user.sellerAccount;
        await _store.saveSellerAccountSnapshot(
          snap == null || !snap.hasAnyField ? null : jsonEncode(snap.toJson()),
        );
        if (!ref.mounted) return;
      }

      state = AuthState(
        user: user,
        sellerId: sellerId,
        rememberDevice: true,
        isBootstrapping: false,
      );
      _scheduleExpiryLogout(token);
    } catch (_) {
      state = const AuthState(isBootstrapping: false);
    }
  }

  String? _jwtSubject(Map<String, dynamic> claims) {
    final sub = claims['sub'];
    if (sub is String && sub.trim().isNotEmpty) return sub.trim();
    final id = claims['id'];
    if (id is String && id.trim().isNotEmpty) return id.trim();
    return null;
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setLoading();
    _clearEphemeralFlags();

    final u = username.trim();
    if (u.isEmpty) {
      state = state.copyWith(
        errorMessage: AccountCommerceL10n.english(
          AccountCommerceL10n.usernameRequired,
        ),
        isLoading: false,
      );
      return false;
    }
    if (password.isEmpty) {
      state = state.copyWith(
        errorMessage: AccountCommerceL10n.english(
          AccountCommerceL10n.passwordRequired,
        ),
        isLoading: false,
      );
      return false;
    }
    if (password.length < 6) {
      state = state.copyWith(
        errorMessage: AccountCommerceL10n.english(
          AccountCommerceL10n.passwordMin6,
        ),
        isLoading: false,
      );
      return false;
    }

    // API `rememberDevice: true` issues a ~30-day session; always persist.
    final result = await _repo.login(
      userName: u,
      password: password,
      rememberDevice: true,
    );
    return switch (result) {
      Success(:final value) => _applySession(value),
      ResultFailure(:final failure) => _fail(failure.message),
    };
  }

  /// Returns `true` when OTP verification is required (navigate to verify-otp).
  Future<bool> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required bool acceptTerms,
    RegistrationAccountType registrationType =
        RegistrationAccountType.individual,
    BusinessRegistrationData? business,
    XFile? profilePicture,
    String? referralEmail,
    String? referralCode,
    DateTime? dateOfBirth,
  }) async {
    _setLoading();
    _clearEphemeralFlags();

    final name = fullName.trim();
    final u = username.trim();
    final e = email.trim();

    if (name.isEmpty) {
      return _fail('Full name is required.');
    }
    if (u.isEmpty) {
      return _fail(
        AccountCommerceL10n.english(AccountCommerceL10n.usernameRequired),
      );
    }
    if (!isValidEmail(e)) {
      return _fail('Enter a valid email address.');
    }
    final strength = evaluatePasswordStrength(password);
    if (!strength.isStrong) {
      return _fail(englishPasswordStrength(strength));
    }
    if (!acceptTerms) {
      return _fail(
        AccountCommerceL10n.english(AccountCommerceL10n.termsAgreement),
      );
    }

    String? dateOfBirthApi;
    if (registrationType == RegistrationAccountType.individual) {
      final dobError = validateDateOfBirth(dateOfBirth);
      if (dobError != null) {
        return _fail(dobError);
      }
      dateOfBirthApi = formatDateOfBirthForApi(dateOfBirth!);
    }

    if (registrationType == RegistrationAccountType.business) {
      final businessError = _validateBusiness(business);
      if (businessError != null) {
        return _fail(businessError);
      }
    }

    final result = await _repo.register(
      name: name,
      userName: u,
      email: e,
      password: password,
      registrationType: registrationType,
      business: registrationType == RegistrationAccountType.business
          ? business
          : null,
      profilePicture: profilePicture,
      referralEmail: referralEmail,
      referralCode: referralCode,
      dateOfBirth: dateOfBirthApi,
    );
    return switch (result) {
      Success(:final value) => () {
        state = state.copyWith(
          isLoading: false,
          pendingVerificationEmail: value.email,
          errorMessage: null,
        );
        return true;
      }(),
      ResultFailure(:final failure) => _fail(failure.message),
    };
  }

  String? _validateBusiness(BusinessRegistrationData? business) {
    if (business == null) {
      return 'Business registration details are required.';
    }
    if (business.companyName.trim().isEmpty) {
      return 'Company name is required.';
    }
    if (business.addressLine1.trim().isEmpty) {
      return 'Address line 1 is required.';
    }
    if (business.addressLine2.trim().isEmpty) {
      return 'Address line 2 is required.';
    }
    if (business.city.trim().isEmpty) {
      return 'City is required.';
    }
    if (business.state.trim().isEmpty) {
      return 'State is required.';
    }
    if (business.country.trim().isEmpty) {
      return 'Country is required.';
    }
    if (business.zipCode.trim().isEmpty) {
      return 'ZIP / postal code is required.';
    }
    if (business.phone1.trim().isEmpty) {
      return 'Primary phone is required.';
    }
    if (business.phone2.trim().isEmpty) {
      return 'Secondary phone is required.';
    }
    if (business.representativeName1.trim().isEmpty) {
      return 'Primary representative name is required.';
    }
    if (business.representativeName2.trim().isEmpty) {
      return 'Secondary representative name is required.';
    }
    if (!isValidPan(business.panCardNumber)) {
      return 'Enter a valid PAN (e.g. ABCDE1234F).';
    }
    if (!isValidAadhaar(business.aadhaarNumber)) {
      return 'Enter a valid 12-digit Aadhaar number.';
    }
    if (business.iecNumber.trim().isEmpty) {
      return 'IEC number is required.';
    }
    if (business.accountHolderName.trim().isEmpty) {
      return 'Account holder name is required.';
    }
    if (!isValidBankAccountNumber(business.accountNumber)) {
      return 'Account number must be 8–20 digits.';
    }
    if (!isValidIfsc(business.ifscCode)) {
      return 'Enter a valid IFSC code (e.g. HDFC0001234).';
    }
    if (business.bankName.trim().isEmpty) {
      return 'Bank name is required.';
    }
    return null;
  }

  Future<bool> verifyOtp({required String email, required String otp}) async {
    _setLoading();
    state = state.copyWith(errorMessage: null);

    final e = email.trim();
    final code = otp.trim();
    if (!isValidEmail(e)) {
      return _fail('Enter a valid email address.');
    }
    if (code.length != 6) {
      return _fail(AccountCommerceL10n.english(AccountCommerceL10n.enterOtp));
    }

    final result = await _repo.verifyOtp(email: e, otp: code);
    return switch (result) {
      Success(:final value) => _applySession(value, clearPendingEmail: true),
      ResultFailure(:final failure) => _fail(failure.message),
    };
  }

  Future<bool> resendOtp({required String email}) async {
    _setLoading();
    state = state.copyWith(errorMessage: null);

    final e = email.trim();
    if (!isValidEmail(e)) {
      return _fail('Enter a valid email address.');
    }

    final result = await _repo.resendOtp(email: e);
    return switch (result) {
      Success(:final value) => () {
        state = state.copyWith(
          isLoading: false,
          pendingVerificationEmail: value.email,
          errorMessage: null,
        );
        return true;
      }(),
      ResultFailure(:final failure) => _fail(failure.message),
    };
  }

  Future<bool> sendResetLink({required String email}) async {
    _setLoading();
    state = state.copyWith(errorMessage: null, resetLinkSent: false);

    final e = email.trim();
    if (!isValidEmail(e)) {
      return _fail('Enter a valid email address.');
    }

    final result = await _repo.forgetPassword(email: e);
    return switch (result) {
      Success() => () {
        state = state.copyWith(
          isLoading: false,
          resetLinkSent: true,
          errorMessage: null,
        );
        return true;
      }(),
      ResultFailure(:final failure) => _fail(failure.message),
    };
  }

  Future<bool> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    _setLoading();
    state = state.copyWith(errorMessage: null, passwordResetSuccess: false);

    final token = resetToken.trim();
    if (token.isEmpty) {
      return _fail('Reset link is invalid or expired.');
    }
    final strength = evaluatePasswordStrength(newPassword);
    if (!strength.isStrong) {
      return _fail(englishPasswordStrength(strength));
    }

    final result = await _repo.resetPassword(
      resetToken: token,
      newPassword: newPassword,
    );
    return switch (result) {
      Success() => () {
        state = state.copyWith(
          isLoading: false,
          passwordResetSuccess: true,
          errorMessage: null,
        );
        return true;
      }(),
      ResultFailure(:final failure) => _fail(failure.message),
    };
  }

  Future<void> logout() async {
    _cancelExpiryTimer();
    _setLoading();
    await _repo.logout();
    if (!ref.mounted) return;
    // Guarantee local wipe even if repository clear was skipped.
    await _clearLocalSession();
    if (!ref.mounted) return;
    state = const AuthState();
  }

  /// Schedules account deletion; clears session on success.
  Future<bool> requestAccountDeletion({required String password}) async {
    _cancelExpiryTimer();
    _setLoading();
    _clearEphemeralFlags();

    if (password.isEmpty) {
      return _fail('Password is required to delete your account.');
    }

    final result = await _repo.requestAccountDeletion(password: password);
    return switch (result) {
      Success(:final value) => () {
        state = AuthState(
          isLoading: false,
          accountDeletionMessage: value.message,
          accountDeletionRecoverUntil: value.recoverUntil,
        );
        return true;
      }(),
      ResultFailure(:final failure) => _fail(failure.message),
    };
  }

  /// Recovers a scheduled-for-deletion account (public).
  Future<bool> recoverAccount({
    String? token,
    String? email,
    String? password,
  }) async {
    _setLoading();
    state = state.copyWith(errorMessage: null, accountRecovered: false);

    final tokenValue = token?.trim() ?? '';
    final emailValue = email?.trim() ?? '';
    final hasToken = tokenValue.isNotEmpty;
    final hasCredentials =
        emailValue.isNotEmpty && (password?.isNotEmpty ?? false);

    if (!hasToken && !hasCredentials) {
      return _fail(
        'Enter the recovery token from your email, or your email and password.',
      );
    }
    if (!hasToken && !isValidEmail(emailValue)) {
      return _fail('Enter a valid email address.');
    }

    final result = await _repo.recoverAccount(
      token: hasToken ? tokenValue : null,
      email: hasToken ? null : emailValue,
      password: hasToken ? null : password,
    );
    return switch (result) {
      Success() => () {
        state = state.copyWith(
          isLoading: false,
          accountRecovered: true,
          errorMessage: null,
        );
        return true;
      }(),
      ResultFailure(:final failure) => _fail(failure.message),
    };
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void setErrorMessage(String message) {
    state = state.copyWith(errorMessage: message, isLoading: false);
  }

  void setPendingVerificationEmail(String email) {
    state = state.copyWith(pendingVerificationEmail: email.trim());
  }

  /// Merges profile API fields into the signed-in session.
  Future<void> applyAccountProfile({
    String? fullName,
    String? username,
    String? email,
    String? role,
    String? profilePicture,
    bool? isVerified,
    SellerAccountSnapshot? sellerAccount,
  }) async {
    final user = state.user;
    if (user == null) return;
    final nextAccount = SellerAccountSnapshot.merge(
      sellerAccount,
      user.sellerAccount,
    );
    final next = user.copyWith(
      fullName: fullName,
      username: username,
      email: email,
      role: role,
      profilePicture: profilePicture,
      isVerified: isVerified,
      sellerAccount: nextAccount,
    );
    state = state.copyWith(user: next);
    final token = await _store.readAccessToken();
    if (token == null || token.isEmpty) return;
    await _store.saveSession(
      accessToken: token,
      userId: next.id,
      sellerId: state.sellerId,
      userName: next.username,
      role: next.role,
      isVerified: next.isVerified,
      rememberDevice: true,
    );
    final snap = next.sellerAccount;
    await _store.saveSellerAccountSnapshot(
      snap == null || !snap.hasAnyField ? null : jsonEncode(snap.toJson()),
    );
  }

  bool _applySession(AuthSession session, {bool clearPendingEmail = false}) {
    final previousUserId = state.user?.id;
    final nextUserId = session.user.id;
    // New account after another session: drop in-memory identity immediately
    // so seller/buyer screens cannot keep using the prior sellerId/userId.
    if (previousUserId != null &&
        previousUserId.isNotEmpty &&
        previousUserId != nextUserId) {
      state = const AuthState(isLoading: true);
    }
    state = AuthState(
      user: session.user,
      sellerId: session.sellerId,
      rememberDevice: session.rememberDevice,
      isLoading: false,
      pendingVerificationEmail: clearPendingEmail
          ? null
          : state.pendingVerificationEmail,
    );
    _scheduleExpiryLogout(session.accessToken);
    return true;
  }

  void _scheduleExpiryLogout(String accessToken) {
    _cancelExpiryTimer();
    final remaining = JwtUtils.timeUntilExpiry(accessToken);
    if (remaining <= Duration.zero) {
      unawaited(_expireSession());
      return;
    }
    // Cap timer length for platforms with coarse timer limits; re-check on fire.
    final delay = remaining > const Duration(days: 1)
        ? const Duration(days: 1)
        : remaining;
    _expiryTimer = Timer(delay, () {
      if (JwtUtils.isExpired(accessToken)) {
        unawaited(_expireSession());
      } else {
        _scheduleExpiryLogout(accessToken);
      }
    });
  }

  Future<void> _expireSession() async {
    _cancelExpiryTimer();
    await _clearLocalSession();
    if (!ref.mounted) return;
    state = const AuthState();
  }

  Future<void> _clearLocalSession() async {
    try {
      await _store.clear();
      if (!ref.mounted) return;
    } catch (_) {
      // Best-effort; UI must still sign out.
    }
  }

  void _cancelExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
  }

  bool _fail(String message) {
    state = state.copyWith(errorMessage: message, isLoading: false);
    return false;
  }

  void _setLoading() {
    state = state.copyWith(isLoading: true, errorMessage: null);
  }

  void _clearEphemeralFlags() {
    state = state.copyWith(
      resetLinkSent: false,
      passwordResetSuccess: false,
      accountRecovered: false,
      clearAccountDeletion: true,
      errorMessage: null,
    );
  }

  SellerAccountSnapshot? _decodeSellerSnapshot(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return SellerAccountSnapshot.tryParse(decoded);
    } catch (_) {
      return null;
    }
  }
}
