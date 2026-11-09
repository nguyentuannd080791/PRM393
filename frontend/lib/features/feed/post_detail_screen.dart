import 'package:flutter/material.dart';
import 'package:clone_facebook/core/widgets/feature_placeholder_view.dart';

/// Integration point; this screen's business feature is supplied by Member 1.
class PostDetailScreen extends FeaturePlaceholderView {
  const PostDetailScreen({super.key, required this.postId})
    : super(
        title: 'Post Detail',
        icon: Icons.article_outlined,
        message: 'Member 1: Post Detail is awaiting integration.',
      );
  final String postId;
}
