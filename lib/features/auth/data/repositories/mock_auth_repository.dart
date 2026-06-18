import 'dart:async';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Mock implementation of [AuthRepository].
///
/// This simulates real auth flows (network delay, OTP verification, a fixed
/// debug OTP of "1234") and persists the signed-in user locally via Hive so
/// sessions survive app restarts — but performs no real network calls.
///
/// MIGRATION PATH: to move to real Firebase Auth, create
/// `FirebaseAuthRepository implements AuthRepository`, wire up
/// `firebase_auth` + `google_sign_in` inside it, and swap the provider
/// binding in `auth_providers.dart`. Nothing in the domain or presentation
/// layers needs to change.
class MockAuthRepository implements AuthRepository {
  static const _boxName = 'auth_session';
  static const _userKey = 'current_user';
  static const _debugOtp = '1234';

  final _authStateController = StreamController<AppUser?>.broadcast();
  final _uuid = const Uuid();

  // In-memory map of verificationId -> phone number, simulating a pending
  // OTP session server-side.
  final Map<String, String> _pendingVerifications = {};

  Box get _box => Hive.box(_boxName);

  static Future<void> ensureBoxOpen() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  @override
  Stream<AppUser?> authStateChanges() => _authStateController.stream;

  @override
  AppUser? get currentUser {
    final raw = _box.get(_userKey);
    if (raw == null) return null;
    return _decodeUser(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 900));
    try {
      // Simulated Google account — in the real implementation this would
      // come back from google_sign_in's GoogleSignInAccount.
      final user = AppUser(
        id: _uuid.v4(),
        name: 'Alex Morgan',
        email: 'alex.morgan@gmail.com',
        photoUrl: null,
        provider: AuthProvider.google,
        createdAt: DateTime.now(),
      );
      await _persist(user);
      _authStateController.add(user);
      return Ok(user);
    } catch (e) {
      return const Err(AuthFailure('Google sign-in failed. Please try again.'));
    }
  }

  @override
  Future<Result<String>> sendOtp(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final verificationId = _uuid.v4();
    _pendingVerifications[verificationId] = phoneNumber;
    // In a real implementation this triggers an actual SMS via Firebase.
    // For MVP/demo purposes the debug code is always "1234".
    return Ok(verificationId);
  }

  @override
  Future<Result<AppUser>> verifyOtp({
    required String verificationId,
    required String otp,
    required String phoneNumber,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final pendingPhone = _pendingVerifications[verificationId];
    if (pendingPhone == null) {
      return const Err(AuthFailure('Your code expired. Please request a new one.'));
    }
    if (otp.trim() != _debugOtp) {
      return const Err(AuthFailure('Incorrect code. Please try again.'));
    }

    final user = AppUser(
      id: _uuid.v4(),
      phoneNumber: pendingPhone,
      provider: AuthProvider.phone,
      createdAt: DateTime.now(),
    );
    await _persist(user);
    _authStateController.add(user);
    _pendingVerifications.remove(verificationId);
    return Ok(user);
  }

  @override
  Future<Result<AppUser>> continueAsGuest() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final user = AppUser(
      id: _uuid.v4(),
      name: 'Guest',
      provider: AuthProvider.guest,
      createdAt: DateTime.now(),
    );
    await _persist(user);
    _authStateController.add(user);
    return Ok(user);
  }

  @override
  Future<Result<void>> updateProfile({String? name, String? email}) async {
    final existing = currentUser;
    if (existing == null) {
      return const Err(AuthFailure('No signed-in user.'));
    }
    final updated = existing.copyWith(name: name, email: email);
    await _persist(updated);
    _authStateController.add(updated);
    return const Ok(null);
  }

  @override
  Future<Result<void>> signOut() async {
    await _box.delete(_userKey);
    _authStateController.add(null);
    return const Ok(null);
  }

  Future<void> _persist(AppUser user) async {
    await _box.put(_userKey, _encodeUser(user));
  }

  Map<String, dynamic> _encodeUser(AppUser u) => {
        'id': u.id,
        'name': u.name,
        'email': u.email,
        'phoneNumber': u.phoneNumber,
        'photoUrl': u.photoUrl,
        'provider': u.provider.name,
        'createdAt': u.createdAt.toIso8601String(),
      };

  AppUser _decodeUser(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String,
        name: m['name'] as String?,
        email: m['email'] as String?,
        phoneNumber: m['phoneNumber'] as String?,
        photoUrl: m['photoUrl'] as String?,
        provider: AuthProvider.values.firstWhere((p) => p.name == m['provider']),
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}

/// Utility kept here for tests / demo to avoid importing dart:math at the
/// call site for a one-off use.
int debugRandomDelayMs() => 300 + Random().nextInt(400);
