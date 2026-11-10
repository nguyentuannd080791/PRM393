import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/features/auth/providers/auth_provider.dart';

/// A [ChangeNotifier] that listens to Riverpod's [authStateProvider]
/// and triggers [notifyListeners] to cause GoRouter to re-evaluate redirects.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}
