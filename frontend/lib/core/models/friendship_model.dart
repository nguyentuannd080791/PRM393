import '../enums/app_enums.dart';

/// 5. Friendship Table Model (SDD §III.2.4)
class FriendshipModel {
  final String id;
  final String requesterId;
  final String receiverId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const FriendshipModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  FriendshipModel copyWith({
    String? id,
    String? requesterId,
    String? receiverId,
    FriendshipStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendshipModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'requester_id': requesterId,
    'receiver_id': receiverId,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'responded_at': respondedAt?.toIso8601String(),
  };

  factory FriendshipModel.fromJson(Map<String, dynamic> json) => FriendshipModel(
    id: json['id']?.toString() ?? '',
    requesterId: (json['requester_id'] ?? json['requesterId'] ?? '').toString(),
    receiverId: (json['receiver_id'] ?? json['receiverId'] ?? '').toString(),
    status: FriendshipStatus.fromString(json['status'] as String? ?? 'none'),
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    respondedAt: json['responded_at'] != null ? DateTime.tryParse(json['responded_at'] as String) : null,
  );

  @override
  bool operator ==(Object other) => identical(this, other) || other is FriendshipModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
