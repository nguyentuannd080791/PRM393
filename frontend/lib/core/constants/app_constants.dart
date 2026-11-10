/// Application-wide constants, constraints, and standard messages.
/// Adheres to Section IV.4.4 (Generic "Connect" branding, no Facebook trademarks).
class AppConstants {
  AppConstants._();

  static const String appName = 'Connect';
  static const String appTagline =
      'Connect with friends and the world around you.';

  // Pagination & Debounce
  static const int feedPageLimit = 10;
  static const int commentsPageLimit = 20;
  static const int searchDebounceMs = 300;

  // Validation Limits (SRS Data Constraints)
  static const int minNameLength = 1;
  static const int maxNameLength = 50;
  static const int minPasswordLength = 8;
  static const int maxBioLength = 150;
  static const int maxCommentLength = 1000;
  static const int maxPostLength = 5000;
  static const int minimumUserAgeYears = 13;

  // Messages (SRS Section III & IV)
  static const String msgContentUnavailable = 'Nội dung này hiện không khả dụng';
  static const String msgGenericError = 'Something went wrong. Please try again.';
  static const String msgNetworkError = 'Network error. Please check your connection.';
  static const String msgLoginFailed = 'Invalid email/phone or password.';
}
