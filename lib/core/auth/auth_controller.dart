import 'dart:async';

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

/// Auth session controller: login, register/OTP, logout, password reset, cold start.
class AuthController extends Notifier<AuthState> {
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
      if (token == null || token.isEmpty) {
        state = const AuthState(isBootstrapping: false);
        return;
      }

      final claims = JwtUtils.decodePayload(token);
      if (claims == null || JwtUtils.isExpired(token)) {
        await _store.clear();
        state = const AuthState(isBootstrapping: false);
        return;
      }

      final cachedUserId = await _store.readUserId();
      final cachedUserName = await _store.readUserName();
      final cachedRole = await _store.readRole();
      final cachedSellerId = await _store.readSellerId();

      final user = AuthUser.fromJwtClaims(
        claims,
        cachedUserId: cachedUserId,
        cachedUserName: cachedUserName,
        cachedRole: cachedRole,
      );
      if (user.id.isEmpty) {
        await _store.clear();
        state = const AuthState(isBootstrapping: false);
        return;
      }

      final sellerId = cachedSellerId ?? JwtUtils.readSellerId(claims);

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

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setLoading();
    _clearEphemeralFlags();

    final u = username.trim();
    if (u.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Username is required.',
        isLoading: false,
      );
      return false;
    }
    if (password.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Password is required.',
        isLoading: false,
      );
      return false;
    }
    if (password.length < 6) {
      state = state.copyWith(
        errorMessage: 'Password must be at least 6 characters.',
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
      return _fail('Username is required.');
    }
    if (!isValidEmail(e)) {
      return _fail('Enter a valid email address.');
    }
    final strength = evaluatePasswordStrength(password);
    if (!strength.isStrong) {
      return _fail(strength.message);
    }
    if (!acceptTerms) {
      return _fail(
        'Please agree to the Terms of Service (including chatbot data use) and Ethical Sourcing Policy.',
      );
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

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading();
    state = state.copyWith(errorMessage: null);

    final e = email.trim();
    final code = otp.trim();
    if (!isValidEmail(e)) {
      return _fail('Enter a valid email address.');
    }
    if (code.length != 6) {
      return _fail('Enter the 6-digit OTP.');
    }

    final result = await _repo.verifyOtp(email: e, otp: code);
    return switch (result) {
      Success(:final value) => _applySession(
          value,
          clearPendingEmail: true,
        ),
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
    state = state.copyWith(
      errorMessage: null,
      resetLinkSent: false,
    );

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
    state = state.copyWith(
      errorMessage: null,
      passwordResetSuccess: false,
    );

    final token = resetToken.trim();
    if (token.isEmpty) {
      return _fail('Reset link is invalid or expired.');
    }
    final strength = evaluatePasswordStrength(newPassword);
    if (!strength.isStrong) {
      return _fail(strength.message);
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
    state = const AuthState();
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

  bool _applySession(
    AuthSession session, {
    bool clearPendingEmail = false,
  }) {
    state = AuthState(
      user: session.user,
      sellerId: session.sellerId,
      rememberDevice: session.rememberDevice,
      isLoading: false,
      pendingVerificationEmail:
          clearPendingEmail ? null : state.pendingVerificationEmail,
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
    await _store.clear();
    state = const AuthState();
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
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );
  }

  void _clearEphemeralFlags() {
    state = state.copyWith(
      resetLinkSent: false,
      passwordResetSuccess: false,
      errorMessage: null,
    );
  }
}
