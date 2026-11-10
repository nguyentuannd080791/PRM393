import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/session_storage.dart';
import 'auth_repository.dart';
import 'models/user.dart';

/// Immutable state representing authentication status and lockout state.
class AuthState {
  final bool isLoading;
  final User? user;
  final String? errorMessage;
  final int failedAttempts;
  final DateTime? lockoutUntil;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
    this.failedAttempts = 0,
    this.lockoutUntil,
  });

  bool get isAuthenticated => user != null;
  bool get isUnauthenticated => !isLoading && user == null;

  bool get isLockedOut =>
      lockoutUntil != null && DateTime.now().isBefore(lockoutUntil!);

  int get remainingLockoutSeconds =>
      isLockedOut ? lockoutUntil!.difference(DateTime.now()).inSeconds : 0;

  AuthState copyWith({
    bool? isLoading,
    User? Function()? user,
    String? Function()? errorMessage,
    int? failedAttempts,
    DateTime? Function()? lockoutUntil,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user != null ? user() : this.user,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: lockoutUntil != null ? lockoutUntil() : this.lockoutUntil,
    );
  }
}

/// Notifier handling session authentication events, lockout tracking, and repository integration.
class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Restore a saved login: show the splash while /auth/me verifies the stored token.
    final token = ref.read(sessionStorageProvider).getToken();
    if (token != null && token.isNotEmpty) {
      Future.microtask(checkSession);
      return const AuthState(isLoading: true, user: null);
    }
    return const AuthState(isLoading: false, user: null);
  }

  void setUser(User? user) {
    state = state.copyWith(user: () => user, isLoading: false);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: () => error, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(errorMessage: () => null);
  }

  void resetLockout() {
    state = state.copyWith(
      failedAttempts: 0,
      lockoutUntil: () => null,
      errorMessage: () => null,
    );
  }

  Future<void> checkSession() async {
    state = state.copyWith(isLoading: true);
    final authRepo = ref.read(authRepositoryProvider);
    final currentDbUser = await authRepo.getMe();
    if (currentDbUser != null) {
      state = state.copyWith(
        isLoading: false,
        user: () => User.fromModel(currentDbUser),
        errorMessage: () => null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        user: () => null,
        errorMessage: () => null,
      );
    }
  }

  Future<bool> login(String identifier, String password) async {
    if (state.isLockedOut) {
      state = state.copyWith(
        errorMessage: () => 'Too many attempts. Try again in 5 minutes.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userModel = await authRepo.login(identifier, password);

      state = state.copyWith(
        isLoading: false,
        user: () => User.fromModel(userModel),
        errorMessage: () => null,
        failedAttempts: 0,
        lockoutUntil: () => null,
      );
      return true;
    } catch (e) {
      final newFailed = state.failedAttempts + 1;
      final willLockout =
          newFailed >= 5 || e.toString().contains('Too many attempts');
      final lockoutTime = willLockout
          ? DateTime.now().add(const Duration(minutes: 5))
          : null;
      final errorMsg = willLockout
          ? 'Too many attempts. Try again in 5 minutes.'
          : (e.toString().replaceAll('Exception: ', '').isNotEmpty
                ? e.toString().replaceAll('Exception: ', '')
                : 'Invalid email/phone or password.');

      state = state.copyWith(
        isLoading: false,
        user: () => null,
        errorMessage: () => errorMsg,
        failedAttempts: newFailed,
        lockoutUntil: () => lockoutTime,
      );
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    String? email,
    required String phone,
    required String password,
    DateTime? birthday,
    String? gender,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userModel = await authRepo.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        birthday: birthday,
        gender: gender,
      );
      state = state.copyWith(
        isLoading: false,
        user: () => User.fromModel(userModel),
        errorMessage: () => null,
        failedAttempts: 0,
        lockoutUntil: () => null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.logout();
    } catch (_) {}
    state = const AuthState(isLoading: false, user: null);
  }
}

/// Provider for [AuthState].
final authStateProvider = NotifierProvider<AuthStateNotifier, AuthState>(
  AuthStateNotifier.new,
);

/// Convenience selector provider for the current logged-in [User].
final currentUserProvider = Provider<User?>((ref) {
  final authUser = ref.watch(authStateProvider).user;
  if (authUser != null) return authUser;
  final storageUser = ref.watch(sessionStorageProvider).getUser();
  if (storageUser != null) return User.fromModel(storageUser);
  return null;
});

/// Shared identity dependency used to reset feature state between accounts.
final sessionUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider.select((state) => state.user?.id)),
);
