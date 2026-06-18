import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Use cases are intentionally thin wrappers. Their value is twofold:
/// (1) they give each action a clear, testable, named entry point instead of
/// ViewModels calling repository methods directly, and (2) they're the
/// natural place to add business rules later (e.g. validating a phone
/// number format) without bloating the ViewModel or repository.

class SignInWithGoogleUseCase {
  final AuthRepository repository;
  const SignInWithGoogleUseCase(this.repository);

  Future<Result<AppUser>> call() => repository.signInWithGoogle();
}

class SendOtpUseCase {
  final AuthRepository repository;
  const SendOtpUseCase(this.repository);

  Future<Result<String>> call(String phoneNumber) {
    final trimmed = phoneNumber.trim();
    if (trimmed.length < 7) {
      return Future.value(
        const Err<String>(ValidationFailure('Please enter a valid phone number.')),
      );
    }
    return repository.sendOtp(trimmed);
  }
}

class VerifyOtpUseCase {
  final AuthRepository repository;
  const VerifyOtpUseCase(this.repository);

  Future<Result<AppUser>> call({
    required String verificationId,
    required String otp,
    required String phoneNumber,
  }) {
    return repository.verifyOtp(
      verificationId: verificationId,
      otp: otp,
      phoneNumber: phoneNumber,
    );
  }
}

class ContinueAsGuestUseCase {
  final AuthRepository repository;
  const ContinueAsGuestUseCase(this.repository);

  Future<Result<AppUser>> call() => repository.continueAsGuest();
}

class SignOutUseCase {
  final AuthRepository repository;
  const SignOutUseCase(this.repository);

  Future<Result<void>> call() => repository.signOut();
}
