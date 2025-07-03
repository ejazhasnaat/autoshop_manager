// lib/features/auth/presentation/auth_providers.dart
import 'package:autoshop_manager/core/setup_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/repositories/auth_repository.dart';
import 'package:autoshop_manager/data/repositories/preference_repository.dart';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/services/secure_storage_service.dart';
import 'package:autoshop_manager/core/providers.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;
  bool get isAdmin => user?.role == 'Admin';

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final allUsersProvider = StreamProvider.autoDispose<List<User>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getAllUsers();
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  Future<void> tryAutoLogin() async {
    final shouldKeepLoggedIn = await _ref.read(preferenceRepositoryProvider).getKeepMeLoggedIn();
    if (!shouldKeepLoggedIn) return;

    final username = await _ref.read(secureStorageServiceProvider).readUsername();
    final password = await _ref.read(secureStorageServiceProvider).readPassword();

    if (username != null && password != null) {
      await login(username, password);
    }
  }

  Future<bool> performInitialSetup({
    required String workshopName,
    required String managerName,
    required String phone,
    required String address,
    required String adminUsername,
    required String adminPassword,
    required String adminFullName,
    String? userUsername,
    String? userPassword,
    String? userFullName,
    String? userRole,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref.read(authRepositoryProvider).performInitialSetup(
            workshopName: workshopName,
            managerName: managerName,
            phone: phone,
            address: address,
            adminUsername: adminUsername,
            adminPassword: adminPassword,
            adminFullName: adminFullName,
            userUsername: userUsername,
            userPassword: userPassword,
            userFullName: userFullName,
            userRole: userRole,
          );

      await _ref.read(preferenceRepositoryProvider).markSetupAsComplete();
      _ref.read(setupCompleteProvider.notifier).state = true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _ref.read(authRepositoryProvider).login(username, password);
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
        await _ref.read(secureStorageServiceProvider).saveCredentials(username, password);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Invalid credentials');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(clearUser: true);
    await _ref.read(secureStorageServiceProvider).deleteCredentials();
    await _ref.read(preferenceRepositoryProvider).saveKeepMeLoggedIn(false);
  }

  Future<User?> signup(String username, String password, String role, {String? fullName}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userExists = await _ref.read(authRepositoryProvider).userExists(username);
      if (userExists) {
        state = state.copyWith(isLoading: false, error: 'Username already exists.');
        return null;
      }

      final newUser = await _ref.read(authRepositoryProvider).signup(username, password, role, fullName: fullName);
      _ref.invalidate(allUsersProvider);
      state = state.copyWith(isLoading: false);
      return newUser;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> deleteUser(int userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _ref.read(authRepositoryProvider).deleteUser(userId);
      _ref.invalidate(allUsersProvider);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  Future<bool> updateUser({
    required int userId,
    required String fullName,
    String? newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref.read(authRepositoryProvider).updateUser(
            userId: userId,
            fullName: fullName,
            newPassword: newPassword,
          );
      _ref.invalidate(allUsersProvider);
      state = state.copyWith(isLoading: false);
      return true; // Assume success if no exception was thrown.
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

