import 'package:equatable/equatable.dart';

enum AuthProvider { google, phone, guest }

/// Domain-level representation of an authenticated user. Deliberately does
/// not know anything about Firebase, mock storage, or any specific backend —
/// that's the point of Clean Architecture: this entity is what the rest of
/// the app depends on, and the data layer is free to change underneath it.
class AppUser extends Equatable {
  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;
  final AuthProvider provider;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    required this.provider,
    required this.createdAt,
  });

  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!;
    if (email != null) return email!.split('@').first;
    if (phoneNumber != null) return phoneNumber!;
    return 'there';
  }

  String get initials {
    final n = displayName.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? photoUrl,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, email, phoneNumber, photoUrl, provider, createdAt];
}
