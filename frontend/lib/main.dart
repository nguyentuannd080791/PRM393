import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clone_facebook/app/app.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/core/storage/preferences_provider.dart';
import 'package:clone_facebook/features/feed/feed_provider.dart';
import 'package:clone_facebook/features/friends/repositories/search_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-load SharedPreferences before mounting widget tree
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        // Cross-member integration points (Member 1 ← Member 3, Member 4 ← Member 1).
        commentsPathBuilderProvider.overrideWithValue(
          AppRoutePaths.commentsPath,
        ),
        postDetailPathBuilderProvider.overrideWithValue(
          AppRoutePaths.postDetailPath,
        ),
      ],
      child: const FbCloneApp(),
    ),
  );
}
