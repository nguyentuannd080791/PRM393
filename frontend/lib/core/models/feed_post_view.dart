import '../enums/app_enums.dart';
import 'post_model.dart';
import 'user_model.dart';

/// Aggregated Feed Post with joined Author, Counters, and Current Viewer Reaction State.
class FeedPostView {
  final PostModel post;
  final UserModel author;
  final int reactionCount;
  final Map<ReactionType, int> reactionTypeCounts;
  final ReactionType? currentUserReaction;
  final int commentCount;
  final int shareCount;
  final FeedPostView? sharedPost;
  final bool isOriginalDeleted;

  const FeedPostView({
    required this.post,
    required this.author,
    required this.reactionCount,
    required this.reactionTypeCounts,
    this.currentUserReaction,
    required this.commentCount,
    required this.shareCount,
    this.sharedPost,
    this.isOriginalDeleted = false,
  });

  FeedPostView copyWith({
    PostModel? post,
    UserModel? author,
    int? reactionCount,
    Map<ReactionType, int>? reactionTypeCounts,
    ReactionType? currentUserReaction,
    int? commentCount,
    int? shareCount,
    FeedPostView? sharedPost,
    bool? isOriginalDeleted,
  }) {
    return FeedPostView(
      post: post ?? this.post,
      author: author ?? this.author,
      reactionCount: reactionCount ?? this.reactionCount,
      reactionTypeCounts: reactionTypeCounts ?? this.reactionTypeCounts,
      currentUserReaction: currentUserReaction ?? this.currentUserReaction,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      sharedPost: sharedPost ?? this.sharedPost,
      isOriginalDeleted: isOriginalDeleted ?? this.isOriginalDeleted,
    );
  }

  factory FeedPostView.fromJson(Map<String, dynamic> json) {
    final postData = json['post'] is Map<String, dynamic>
        ? json['post'] as Map<String, dynamic>
        : json;
    final authorData = json['author'] as Map<String, dynamic>? ?? {};
    final reactionTypeCountsRaw = json['reaction_type_counts'] as Map<String, dynamic>? ?? {};
    final reactionTypeCounts = <ReactionType, int>{};
    reactionTypeCountsRaw.forEach((k, v) {
      final rType = ReactionType.fromString(k);
      if (rType != null) {
        reactionTypeCounts[rType] = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
      }
    });

    return FeedPostView(
      post: PostModel.fromJson(postData),
      author: UserModel.fromJson(authorData),
      reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0,
      reactionTypeCounts: reactionTypeCounts,
      currentUserReaction: ReactionType.fromString(
        json['current_user_reaction'] as String? ?? json['user_reaction'] as String?,
      ),
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
      sharedPost: json['shared_post'] != null && json['shared_post'] is Map<String, dynamic>
          ? FeedPostView.fromJson(json['shared_post'] as Map<String, dynamic>)
          : null,
      isOriginalDeleted: json['is_original_deleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'post': post.toJson(),
    'author': author.toJson(),
    'reaction_count': reactionCount,
    'reaction_type_counts': reactionTypeCounts.map((k, v) => MapEntry(k.name, v)),
    'current_user_reaction': currentUserReaction?.name,
    'comment_count': commentCount,
    'share_count': shareCount,
    'shared_post': sharedPost?.toJson(),
    'is_original_deleted': isOriginalDeleted,
  };
}
