import 'package:flutter/material.dart';
import 'package:clone_facebook/core/widgets/feature_placeholder_view.dart';

/// Integration point; this screen's business feature is supplied by Member 2.
class PostInsightsScreen extends FeaturePlaceholderView {
  const PostInsightsScreen({super.key})
    : super(
        title: 'Post Insights',
        icon: Icons.insights,
        message: 'Member 2: Post Insights is awaiting integration.',
      );
}
