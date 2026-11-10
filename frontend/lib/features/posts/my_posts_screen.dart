import 'package:flutter/material.dart';
import 'package:clone_facebook/core/widgets/feature_placeholder_view.dart';

/// Integration point; this screen's business feature is supplied by Member 2.
class MyPostsScreen extends FeaturePlaceholderView {
  const MyPostsScreen({super.key})
    : super(
        title: 'My Posts',
        icon: Icons.article_outlined,
        message: 'Member 2: My Posts is awaiting integration.',
      );
}
