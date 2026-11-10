import 'user_model.dart';

/// Search result model representing a discovered user along with their
/// relationship status relative to the searching viewer and mutual friends count.
class UserSearchResult extends UserModel {
  final String relationshipStatus;
  final int mutualFriendsCount;

  UserSearchResult({
    required super.id,
    required super.fullName,
    super.email = '',
    super.phone,
    super.passwordHash = '',
    DateTime? birthday,
    super.gender = 'other',
    super.avatarUrl,
    super.coverUrl,
    super.bio,
    super.city,
    super.workplace,
    DateTime? createdAt,
    this.relationshipStatus = 'none',
    this.mutualFriendsCount = 0,
  }) : super(
         birthday: birthday ?? DateTime(2000, 1, 1),
         createdAt: createdAt ?? DateTime.now(),
       );

  const UserSearchResult.raw({
    required super.id,
    required super.fullName,
    super.email = '',
    super.phone,
    super.passwordHash = '',
    required super.birthday,
    super.gender = 'other',
    super.avatarUrl,
    super.coverUrl,
    super.bio,
    super.city,
    super.workplace,
    required super.createdAt,
    this.relationshipStatus = 'none',
    this.mutualFriendsCount = 0,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) => UserSearchResult(
    id: json['id'].toString(),
    fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? 'Unknown user',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String?,
    passwordHash: json['password_hash'] as String? ?? '',
    birthday: json['birthday'] != null
        ? DateTime.tryParse(json['birthday'] as String) ?? DateTime(2000, 1, 1)
        : DateTime(2000, 1, 1),
    gender: json['gender'] as String? ?? 'other',
    avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
    coverUrl: json['cover_url'] as String? ?? json['coverUrl'] as String?,
    bio: json['bio'] as String?,
    city: json['city'] as String?,
    workplace: json['workplace'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
        : DateTime.now(),
    relationshipStatus: json['relationship_status'] as String? ??
        json['relationshipStatus'] as String? ??
        'none',
    mutualFriendsCount: (json['mutual_friends_count'] as num?)?.toInt() ??
        (json['mutualFriendsCount'] as num?)?.toInt() ??
        0,
  );

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'relationship_status': relationshipStatus,
    'mutual_friends_count': mutualFriendsCount,
  };
}
