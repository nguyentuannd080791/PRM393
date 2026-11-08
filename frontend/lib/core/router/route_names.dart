/// Route path definitions for the fb_clone application.
abstract class AppRoutePaths {
  // Standalone / Root Routes
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Bottom Navigation Shell Tabs (Branches)
  static const feed = '/feed';
  static const friends = '/friends';
  static const notifications = '/notifications';
  static const menu = '/menu';

  // Sub-routes & Full-screen Modals
  static const createPost = '/post/create';
  static const editPost = '/post/:id/edit';
  static String editPostPath(String id) => '/post/$id/edit';

  static const profileEdit = '/profile/edit';
  static const profile = '/profile/:userId';
  static String profilePath(String userId) => '/profile/$userId';

  static const friendsSearch = '/friends/search';
  static const allFriends = '/friends/all';
}

/// Route name definitions for typed navigation.
abstract class AppRouteNames {
  static const splash = 'splash';
  static const login = 'login';
  static const register = 'register';
  static const forgotPassword = 'forgotPassword';

  static const feed = 'feed';
  static const friends = 'friends';
  static const notifications = 'notifications';
  static const menu = 'menu';

  static const createPost = 'createPost';
  static const editPost = 'editPost';
  static const profileEdit = 'profileEdit';
  static const profile = 'profile';

  static const friendsSearch = 'friendsSearch';
  static const allFriends = 'allFriends';
}
