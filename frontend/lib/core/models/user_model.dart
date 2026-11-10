/// 1. User Table Model (SDD §III.2.4)
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String passwordHash;
  final DateTime birthday;
  final String gender;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? city;
  final String? workplace;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.passwordHash,
    required this.birthday,
    required this.gender,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.city,
    this.workplace,
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? passwordHash,
    DateTime? birthday,
    String? gender,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    String? city,
    String? workplace,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      workplace: workplace ?? this.workplace,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'password_hash': passwordHash,
    'birthday': birthday.toIso8601String(),
    'gender': gender,
    'avatar_url': avatarUrl,
    'cover_url': coverUrl,
    'bio': bio,
    'city': city,
    'workplace': workplace,
    'created_at': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'].toString(),
    fullName: json['full_name'] as String? ?? 'Unknown user',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String?,
    passwordHash: json['password_hash'] as String? ?? '',
    birthday: json['birthday'] != null
        ? DateTime.tryParse(json['birthday'] as String) ?? DateTime(2000, 1, 1)
        : DateTime(2000, 1, 1),
    gender: json['gender'] as String? ?? 'other',
    avatarUrl: json['avatar_url'] as String?,
    coverUrl: json['cover_url'] as String?,
    bio: json['bio'] as String?,
    city: json['city'] as String?,
    workplace: json['workplace'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
        : DateTime.now(),
  );

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
