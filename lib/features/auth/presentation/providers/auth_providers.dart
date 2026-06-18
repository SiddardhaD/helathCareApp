import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

/// Single source of truth for which [AuthRepository] implementation is
/// active. Swapping mock -> real backend later means changing only this
/// provider body.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final signInWithGoogleUseCaseProvider = Provider(
  (ref) => SignInWithGoogleUseCase(ref.watch(authRepositoryProvider)),
);

final sendOtpUseCaseProvider = Provider(
  (ref) => SendOtpUseCase(ref.watch(authRepositoryProvider)),
);

final verifyOtpUseCaseProvider = Provider(
  (ref) => VerifyOtpUseCase(ref.watch(authRepositoryProvider)),
);

final continueAsGuestUseCaseProvider = Provider(
  (ref) => ContinueAsGuestUseCase(ref.watch(authRepositoryProvider)),
);

final signOutUseCaseProvider = Provider(
  (ref) => SignOutUseCase(ref.watch(authRepositoryProvider)),
);

/// Streams the current auth state. The router and splash screen watch this
/// to decide whether to show onboarding/login or the main app shell.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  // Seed the stream with the current cached user immediately so app restart
  // doesn't show a login flicker before the stream emits.
  return repo.authStateChanges().map((u) => u ?? repo.currentUser);
});

/// Convenience synchronous accessor for the current user, used in places
/// that can't watch an AsyncValue easily (e.g. deciding ownership of a
/// document when creating it).
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull ?? ref.watch(authRepositoryProvider).currentUser;
});
