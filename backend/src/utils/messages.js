// backend/src/utils/messages.js

const MSG = {
  NO_INTERNET: 'No internet connection. Please check your network and try again.', // MSG-01
  SOMETHING_WENT_WRONG: 'Something went wrong. Please try again.',                 // MSG-02
  ACCOUNT_EXISTS: 'An account with this phone number already exists.',            // MSG-03
  INVALID_CREDENTIALS: 'The email or password is incorrect.',                     // MSG-04
  TOO_MANY_ATTEMPTS: 'Too many attempts. Try again in 5 minutes.',                 // MSG-05
  OFFLINE_SAVED_CONTENT: 'You are offline. Showing saved content.',                // MSG-07
  POST_SHARED: 'Post shared to your timeline.',                                    // MSG-08
  WRITE_SOMETHING_OR_PHOTO: 'Write something or add a photo to post.',             // MSG-09
  DELETE_POST_CONFIRM: 'Delete this post? This cannot be undone.',                 // MSG-10
  UPLOAD_FAILED: 'Upload failed. Tap to retry.',                                   // MSG-11
  IMAGE_TOO_LARGE: 'The image is too large. The maximum size is 10 MB.',           // MSG-12
  FRIEND_REQUEST_SENT: 'Friend request sent.',                                     // MSG-13
  REMOVE_FRIEND_CONFIRM: 'Remove this person from your friends?',                  // MSG-14
  PROFILE_UPDATED: 'Profile updated.',                                             // MSG-15
  NO_RESULTS_FOUND: 'No results found.',                                           // MSG-16
  NO_NOTIFICATIONS: 'You have no notifications yet.',                              // MSG-17
  CONTENT_UNAVAILABLE: 'This content is no longer available.',                     // MSG-18
  DELETE_COMMENT_CONFIRM: 'Delete this comment?',                                  // MSG-19
};

module.exports = { MSG };
