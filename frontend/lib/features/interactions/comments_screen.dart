import 'package:flutter/material.dart';
import 'package:clone_facebook/core/widgets/feature_placeholder_view.dart';

/// Integration point; this screen's business feature is supplied by Member 3.
class CommentsScreen extends FeaturePlaceholderView {
  const CommentsScreen({super.key})
    : super(
        title: 'Comments',
        icon: Icons.comment_outlined,
        message: 'Member 3: Comments is awaiting integration.',
      );
}
