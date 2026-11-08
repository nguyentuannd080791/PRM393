import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clone_facebook/core/router/app_router.dart';
import 'package:clone_facebook/core/theme/app_theme.dart';
import 'package:clone_facebook/core/theme/theme_provider.dart';

/// Root application widget configuring routing and dynamic Material 3 themes.
class FbCloneApp extends ConsumerWidget {
  const FbCloneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
