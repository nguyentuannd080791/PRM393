/// Route path definitions for the fb_clone application.
abstract class AppRoutePaths {
  // Standalone / Root Routes
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';

  // Bottom Navigation Shell Tabs (Branches)
  static const feed = '/feed';
  static const friends = '/friends';
  static const search = '/search';
  static const friendRequests = '/friends/requests';
  static const ownProfile = '/profile/me';
  static const notifications = '/notifications';
  static const menu = '/menu';

  // Sub-routes & Full-screen Modals
  static const createPost = '/post/create';
  static const postDetail = '/post/:id';
  static String postDetailPath(String id) => '/post/$id';
  static const editPost = '/post/:id/edit';
  static String editPostPath(String id) => '/post/$id/edit';
  static const postInsights = '/post/:id/insights';
  static String postInsightsPath(String id) => '/post/$id/insights';
  static const comments = '/post/:id/comments';
  static String commentsPath(String id) => '/post/$id/comments';

  static const myPosts = '/posts/my';
  static const likedPosts = '/posts/liked';
  static const savedPosts = '/posts/saved';

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

  static const feed = 'feed';
  static const friends = 'friends';
  static const search = 'search';
  static const friendRequests = 'friendRequests';
  static const ownProfile = 'ownProfile';
  static const notifications = 'notifications';
  static const menu = 'menu';

  static const createPost = 'createPost';
  static const postDetail = 'postDetail';
  static const editPost = 'editPost';
  static const postInsights = 'postInsights';
  static const comments = 'comments';
  static const myPosts = 'myPosts';
  static const likedPosts = 'likedPosts';
  static const savedPosts = 'savedPosts';
  static const profileEdit = 'profileEdit';
  static const profile = 'profile';

  static const friendsSearch = 'friendsSearch';
  static const allFriends = 'allFriends';
}
