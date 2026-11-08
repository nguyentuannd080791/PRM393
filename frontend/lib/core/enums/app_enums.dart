/// Audience visibility for posts (SRS BR-09, SDD Data Dictionary).
enum PostAudience {
  public,
  friends,
  onlyMe;

  String get displayName {
    switch (this) {
      case PostAudience.public:
        return 'Public';
      case PostAudience.friends:
        return 'Friends';
      case PostAudience.onlyMe:
        return 'Only me';
    }
  }

  static PostAudience fromString(String value) {
    switch (value.toLowerCase()) {
      case 'public':
        return PostAudience.public;
      case 'only_me':
      case 'onlyme':
        return PostAudience.onlyMe;
      case 'friends':
      default:
        return PostAudience.friends;
    }
  }

  String toDbString() {
    switch (this) {
      case PostAudience.public:
        return 'public';
      case PostAudience.friends:
        return 'friends';
      case PostAudience.onlyMe:
        return 'only_me';
    }
  }
}

/// 6 Reaction types supported on posts (SRS BR-12, SDD Data Dictionary).
/// Uses standard Unicode emojis to strictly comply with Section IV.4.4.
enum ReactionType {
  like('Like', '👍', 0xFF2563EB),
  love('Love', '❤️', 0xFFDC2626),
  haha('Haha', '😆', 0xFFF59E0B),
  wow('Wow', '😮', 0xFFF59E0B),
  sad('Sad', '😢', 0xFFF59E0B),
  angry('Angry', '😡', 0xFFEA580C);

  final String label;
  final String emoji;
  final int colorValue;

  const ReactionType(this.label, this.emoji, this.colorValue);

  static ReactionType? fromString(String? value) {
    if (value == null) return null;
    for (final type in ReactionType.values) {
      if (type.name.toLowerCase() == value.toLowerCase()) {
        return type;
      }
    }
    return null;
  }
}

/// Friendship status between two users (SRS BR-15, SDD Data Dictionary).
enum FriendshipStatus {
  none,
  pending,
  accepted;

  static FriendshipStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'accepted':
        return FriendshipStatus.accepted;
      case 'pending':
        return FriendshipStatus.pending;
      case 'none':
      default:
        return FriendshipStatus.none;
    }
  }
}

/// User-to-User friendship relationship view relative to viewer.
enum UserRelationshipStatus {
  self,
  friends,
  pendingSent,     // Viewer sent request to target
  pendingReceived, // Target sent request to viewer
  none;            // Not friends, eligible for "Add Friend"
}

/// Notification event categories (SRS BR-19, SDD Data Dictionary).
enum NotificationType {
  reaction,
  comment,
  friendRequest,
  friendAccept;

  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'reaction':
        return NotificationType.reaction;
      case 'comment':
        return NotificationType.comment;
      case 'friend_request':
      case 'friendrequest':
        return NotificationType.friendRequest;
      case 'friend_accept':
      case 'friendaccept':
        return NotificationType.friendAccept;
      default:
        return NotificationType.reaction;
    }
  }

  String toDbString() {
    switch (this) {
      case NotificationType.reaction:
        return 'reaction';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.friendRequest:
        return 'friend_request';
      case NotificationType.friendAccept:
        return 'friend_accept';
    }
  }
}
