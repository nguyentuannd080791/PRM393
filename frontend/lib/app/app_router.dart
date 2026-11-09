import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/core/widgets/app_bottom_nav.dart';
import 'package:clone_facebook/app/router_refresh_notifier.dart';
import 'package:clone_facebook/features/auth/auth_provider.dart';

// Presentation Screen Placeholders
import 'package:clone_facebook/features/auth/splash_screen.dart';
import 'package:clone_facebook/features/auth/login_screen.dart';
import 'package:clone_facebook/features/auth/register_screen.dart';
import 'package:clone_facebook/features/auth/forgot_password_screen.dart';

import 'package:clone_facebook/features/feed/home_feed_screen.dart';
import 'package:clone_facebook/features/friends/screens/friend_list_screen.dart';
import 'package:clone_facebook/features/friends/screens/search_screen.dart';
import 'package:clone_facebook/features/friends/screens/friend_requests_screen.dart';

import 'package:clone_facebook/features/feed/notifications_screen.dart';
import 'package:clone_facebook/features/feed/post_detail_screen.dart';
import 'package:clone_facebook/features/profile/account_settings_screen.dart';

import 'package:clone_facebook/features/posts/post_editor_screen.dart';
import 'package:clone_facebook/features/profile/profile_screen.dart';
import 'package:clone_facebook/features/profile/edit_profile_screen.dart';

// Global Navigator Keys
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final feedNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'feedBranch');
final friendsNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'friendsBranch',
);
final searchNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'searchBranch',
);
final profileNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'profileBranch',
);
final notificationsNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'notificationsBranch',
);
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
      final isAuthRoute =
          location == AppRoutePaths.login ||
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
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.login,
        name: AppRouteNames.login,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.register,
        name: AppRouteNames.register,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.forgotPassword,
        name: AppRouteNames.forgotPassword,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Stateful Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return AppBottomNav(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Feed
          StatefulShellBranch(
            navigatorKey: feedNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutePaths.feed,
                name: AppRouteNames.feed,
                builder: (context, state) => const HomeFeedScreen(),
              ),
            ],
          ),

          StatefulShellBranch(
            navigatorKey: searchNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutePaths.search,
                name: AppRouteNames.search,
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),

          // Branch 2: Friends
          StatefulShellBranch(
            navigatorKey: friendsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutePaths.friends,
                name: AppRouteNames.friends,
                builder: (context, state) => const FriendListScreen(),
                routes: [
                  GoRoute(
                    path: 'all',
                    name: AppRouteNames.allFriends,
                    redirect: (context, state) => AppRoutePaths.friends,
                  ),
                  GoRoute(
                    path: 'requests',
                    name: AppRouteNames.friendRequests,
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => FriendRequestsScreen(
                      initialSent: state.uri.queryParameters['tab'] == 'sent',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: existing own-profile screen (Member 5 integration).
          StatefulShellBranch(
            navigatorKey: profileNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutePaths.ownProfile,
                name: AppRouteNames.ownProfile,
                builder: (context, state) => const ProfileScreen(userId: 'me'),
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
        redirect: (context, state) => AppRoutePaths.search,
      ),
      GoRoute(
        path: AppRoutePaths.notifications,
        name: AppRouteNames.notifications,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.menu,
        name: AppRouteNames.menu,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.createPost,
        name: AppRouteNames.createPost,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreatePostPage(),
      ),
      // '/post/create' is declared above, so ':id' never captures it.
      GoRoute(
        path: AppRoutePaths.postDetail,
        name: AppRouteNames.postDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            PostDetailScreen(postId: state.pathParameters['id'] ?? ''),
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
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.profile,
        name: AppRouteNames.profile,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? 'me';
          return ProfileScreen(userId: userId);
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
