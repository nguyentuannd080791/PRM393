import 'package:flutter/material.dart';

import 'interactions_provider.dart';
import 'liked_posts_screen.dart';

/// SCR09: saved posts. Unsave / open post come from the shared PostCard.
class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) => PostListScreen(
    title: 'Saved Posts',
    provider: savedPostsProvider,
    emptyMessage: 'You have no saved posts.',
    emptyIcon: Icons.bookmark_outline,
  );
}
