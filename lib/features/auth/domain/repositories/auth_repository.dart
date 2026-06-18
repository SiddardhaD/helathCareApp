import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';

/// Abstract contract for authentication. The domain and presentation layers
/// depend only on this interface. The MVP ships a mock implementation
/// ([MockAuthRepository]); swapping in real Firebase Auth later means
/// writing a new class that implements this same contract — no other code
/// needs to change.
abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<Result<AppUser>> signInWithGoogle();

  /// Starts phone verification. Returns a verification id used by
  /// [verifyOtp]. In the mock implementation this is simulated with a fixed
  /// delay and a fixed code, ready to be replaced by real SMS verification.
  Future<Result<String>> sendOtp(String phoneNumber);

  Future<Result<AppUser>> verifyOtp({
    required String verificationId,
    required String otp,
    required String phoneNumber,
  });

  Future<Result<AppUser>> continueAsGuest();

  Future<Result<void>> updateProfile({String? name, String? email});

  Future<Result<void>> signOut();
}
