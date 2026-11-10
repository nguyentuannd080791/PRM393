import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clone_facebook/app/app_router.dart';
import 'package:clone_facebook/app/app_theme.dart';

/// Root application widget with a fixed light appearance.
class FbCloneApp extends ConsumerWidget {
  const FbCloneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Mini Social',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      // Mobile-first app: on a wide browser window keep it a centred phone-width column.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFE9EDF5),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ClipRect(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}
