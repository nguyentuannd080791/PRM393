import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clone_facebook/core/router/route_names.dart';
import 'package:clone_facebook/core/router/main_navigation_scaffold.dart';
import 'package:clone_facebook/core/router/router_refresh_notifier.dart';
import 'package:clone_facebook/features/auth/presentation/providers/auth_state_provider.dart';

// Presentation Screen Placeholders
import 'package:clone_facebook/features/auth/presentation/pages/splash_page.dart';
import 'package:clone_facebook/features/auth/presentation/pages/login_page.dart';
import 'package:clone_facebook/features/auth/presentation/pages/register_page.dart';
import 'package:clone_facebook/features/auth/presentation/pages/forgot_password_page.dart';

import 'package:clone_facebook/features/feed/presentation/pages/feed_page.dart';
import 'package:clone_facebook/features/friends/presentation/pages/friends_page.dart';
import 'package:clone_facebook/features/friends/presentation/pages/people_search_page.dart';
import 'package:clone_facebook/features/friends/presentation/pages/all_friends_list_page.dart';

import 'package:clone_facebook/features/notifications/presentation/pages/notifications_page.dart';
import 'package:clone_facebook/features/menu/presentation/pages/menu_page.dart';

import 'package:clone_facebook/features/post/presentation/pages/create_post_page.dart';
import 'package:clone_facebook/features/post/presentation/pages/edit_post_page.dart';
import 'package:clone_facebook/features/profile/presentation/pages/profile_page.dart';
import 'package:clone_facebook/features/profile/presentation/pages/edit_profile_page.dart';

// Global Navigator Keys
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final feedNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'feedBranch');
final friendsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'friendsBranch');
final notificationsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'notificationsBranch');
final menuNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'menuBranch');

/// Declarative GoRouter provider for fb_clone.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutePaths.splash,
    refreshListenable: refreshNotifier,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final location = state.matchedLocation;

      final isSplash = location == AppRoutePaths.splash;
      final isAuthRoute = location == AppRoutePaths.login ||
          location == AppRoutePaths.register ||
          location == AppRoutePaths.forgotPassword;

      // 1. Session check in progress -> stay on splash or route to splash
      if (authState.isLoading) {
        return isSplash ? null : AppRoutePaths.splash;
      }

      final isAuthenticated = authState.isAuthenticated;

      // 2. User is authenticated -> prevent viewing login/register/forgot-password/splash
      if (isAuthenticated) {
        if (isSplash || isAuthRoute || location == '/') {
          return AppRoutePaths.feed;
        }
        return null; // allow deep-linking or active route
      }

      // 3. User is unauthenticated -> allow auth routes, redirect all else to login
      if (isAuthRoute) {
        return null;
      }

      return AppRoutePaths.login;
    },
    routes: [
      // Standalone Root Routes
      GoRoute(
        path: AppRoutePaths.splash,
        name: AppRouteNames.splash,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutePaths.login,
        name: AppRouteNames.login,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutePaths.register,
        name: AppRouteNames.register,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutePaths.forgotPassword,
        name: AppRouteNames.forgotPassword,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // Stateful Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return MainNavigationScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Feed
          StatefulShellBranch(
            navigatorKey: feedNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutePaths.feed,
                name: AppRouteNames.feed,
                builder: (context, state) => const FeedPage(),
              ),
            ],
          ),

          // Branch 1: Friends
          StatefulShellBranch(
            navigatorKey: friendsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutePaths.friends,
                name: AppRouteNames.friends,
                builder: (context, state) => const FriendsTabPage(),
                routes: [
                  GoRoute(
                    path: 'all',
                    name: AppRouteNames.allFriends,
                    builder: (context, state) => const AllFriendsListPage(),
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Notifications
          StatefulShellBranch(
            navigatorKey: notificationsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutePaths.notifications,
                name: AppRouteNames.notifications,
                builder: (context, state) => const NotificationsPage(),
              ),
            ],
          ),

          // Branch 3: Menu
          StatefulShellBranch(
            navigatorKey: menuNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutePaths.menu,
                name: AppRouteNames.menu,
                builder: (context, state) => const MenuPage(),
              ),
            ],
          ),
        ],
      ),

      // Full-Screen Modals & Sub-routes (Pushed on rootNavigatorKey over the shell)
      GoRoute(
        path: AppRoutePaths.friendsSearch,
        name: AppRouteNames.friendsSearch,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PeopleSearchPage(),
      ),
      GoRoute(
        path: AppRoutePaths.createPost,
        name: AppRouteNames.createPost,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreatePostPage(),
      ),
      GoRoute(
        path: AppRoutePaths.editPost,
        name: AppRouteNames.editPost,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EditPostPage(postId: id);
        },
      ),
      // IMPORTANT: /profile/edit MUST be defined before /profile/:userId
      GoRoute(
        path: AppRoutePaths.profileEdit,
        name: AppRouteNames.profileEdit,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutePaths.profile,
        name: AppRouteNames.profile,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? 'me';
          return ProfilePage(userId: userId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.error?.toString() ?? 'Page not found.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutePaths.feed),
              child: const Text('Return to Feed'),
            ),
          ],
        ),
      ),
    ),
  );
});
