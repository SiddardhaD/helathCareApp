import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import 'auth_providers.dart';

enum LoginStep { selectMethod, enterPhone, enterOtp }

class LoginState {
  final LoginStep step;
  final bool isLoading;
  final Failure? failure;
  final String phoneNumber;
  final String? verificationId;
  final AppUser? signedInUser;

  const LoginState({
    this.step = LoginStep.selectMethod,
    this.isLoading = false,
    this.failure,
    this.phoneNumber = '',
    this.verificationId,
    this.signedInUser,
  });

  LoginState copyWith({
    LoginStep? step,
    bool? isLoading,
    Failure? failure,
    bool clearFailure = false,
    String? phoneNumber,
    String? verificationId,
    AppUser? signedInUser,
  }) {
    return LoginState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      signedInUser: signedInUser ?? this.signedInUser,
    );
  }
}

/// ViewModel for the login screen flow. Holds UI state (current step,
/// loading, error) and delegates all actual auth logic to use cases —
/// keeping the widget layer purely declarative.
class LoginViewModel extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await ref.read(signInWithGoogleUseCaseProvider)();
    result.when(
      ok: (user) => state = state.copyWith(isLoading: false, signedInUser: user),
      err: (failure) => state = state.copyWith(isLoading: false, failure: failure),
    );
  }

  void startPhoneEntry() {
    state = state.copyWith(step: LoginStep.enterPhone, clearFailure: true);
  }

  void backToMethodSelect() {
    state = state.copyWith(step: LoginStep.selectMethod, clearFailure: true);
  }

  Future<void> submitPhoneNumber(String phoneNumber) async {
    state = state.copyWith(isLoading: true, clearFailure: true, phoneNumber: phoneNumber);
    final result = await ref.read(sendOtpUseCaseProvider)(phoneNumber);
    result.when(
      ok: (verificationId) => state = state.copyWith(
        isLoading: false,
        step: LoginStep.enterOtp,
        verificationId: verificationId,
      ),
      err: (failure) => state = state.copyWith(isLoading: false, failure: failure),
    );
  }

  Future<void> resendOtp() => submitPhoneNumber(state.phoneNumber);

  Future<void> verifyOtp(String otp) async {
    if (state.verificationId == null) return;
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await ref.read(verifyOtpUseCaseProvider)(
      verificationId: state.verificationId!,
      otp: otp,
      phoneNumber: state.phoneNumber,
    );
    result.when(
      ok: (user) => state = state.copyWith(isLoading: false, signedInUser: user),
      err: (failure) => state = state.copyWith(isLoading: false, failure: failure),
    );
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await ref.read(continueAsGuestUseCaseProvider)();
    result.when(
      ok: (user) => state = state.copyWith(isLoading: false, signedInUser: user),
      err: (failure) => state = state.copyWith(isLoading: false, failure: failure),
    );
  }
}

final loginViewModelProvider = NotifierProvider<LoginViewModel, LoginState>(
  LoginViewModel.new,
);
