import 'package:clone_facebook/core/models/app_models.dart';

/// Core user entity representing an authenticated session user or profile.
class User {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? city;
  final String? workplace;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.city,
    this.workplace,
    this.createdAt,
  });

  factory User.fromModel(UserModel model) {
    return User(
      id: model.id,
      email: model.email,
      fullName: model.fullName,
      avatarUrl: model.avatarUrl,
      coverUrl: model.coverUrl,
      bio: model.bio,
      city: model.city,
      workplace: model.workplace,
      createdAt: model.createdAt,
    );
  }

  UserModel toModel({
    String? passwordHash,
    DateTime? birthday,
    String? gender,
    String? phone,
  }) {
    return UserModel(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      passwordHash: passwordHash ?? 'demo_hash',
      birthday: birthday ?? DateTime(2000, 1, 1),
      gender: gender ?? 'Custom',
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      bio: bio,
      city: city,
      workplace: workplace,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    String? city,
    String? workplace,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      workplace: workplace ?? this.workplace,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
