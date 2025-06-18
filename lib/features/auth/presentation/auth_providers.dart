// lib/features/auth/presentation/auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoshop_manager/data/repositories/auth_repository.dart'; // <--- NEW: Import AuthRepository
import 'package:autoshop_manager/data/database/app_database.dart'; // For the User type (Drift generated)

// AuthUser class (defines the authenticated user structure)
class AuthUser {
  final int id;
  final String username;
  final String role;

  AuthUser({required this.id, required this.username, required this.role});
}

// AuthState class (defines the authentication state)
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;

  AuthState({this.status = AuthStatus.unknown, this.user});

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isAdmin => isAuthenticated && user?.role == 'Admin';

  AuthState copyWith({AuthStatus? status, AuthUser? user}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
    );
  }
}

// AuthNotifierProvider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  // Pass ref into the notifier so it can invalidate other providers
  return AuthNotifier(ref.read(authRepositoryProvider), ref);
});

// Provider to get all users for management (e.g., in signup screen)
final allUsersProvider = FutureProvider<List<User>>((ref) async {
  return ref.read(authRepositoryProvider).getAllUsers();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final Ref _ref; // Store the Ref for invalidation

  AuthNotifier(this._authRepository, this._ref) : super(AuthState()) {
    _initializeAuth();
  }

  // Initialize Auth: Ensure admin user exists and seed initial data
  Future<void> _initializeAuth() async {
    await _authRepository.initializeAdminUser();
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }

  Future<bool> login(String username, String password) async {
    final user = await _authRepository.login(username, password);
    if (user != null) {
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
  }

  Future<AuthUser?> createUser(String username, String password, {required String role}) async {
    final newUser = await _authRepository.signup(username, password, role);
    if (newUser != null) {
      _ref.invalidate(allUsersProvider); // Invalidate using the stored Ref
    }
    return newUser;
  }

  Future<bool> deleteUser(int userId) async {
    final success = await _authRepository.deleteUser(userId);
    if (success) {
      _ref.invalidate(allUsersProvider); // Invalidate using the stored Ref
    }
    return success;
  }
}

