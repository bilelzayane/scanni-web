import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/scan_repository.dart';

class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({this.isLoading = false, this.error});
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> signIn(String email, String password) async {
    state = const AuthState(isLoading: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithEmail(email, password);
      
      // Sync guest scans if any
      final userId = repository.currentUser?.id;
      if (userId != null) {
        await ref.read(scanRepositoryProvider).syncGuestScans(userId);
      }
      
      state = const AuthState(isLoading: false);
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    state = const AuthState(isLoading: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signUpWithEmail(email, password, displayName);
      
      // Sync guest scans if any (signUp might auto-login in some configs)
      final userId = repository.currentUser?.id;
      if (userId != null) {
        await ref.read(scanRepositoryProvider).syncGuestScans(userId);
      }
      
      state = const AuthState(isLoading: false);
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState(isLoading: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithGoogle();
      
      // Sync guest scans if any
      final userId = repository.currentUser?.id;
      if (userId != null) {
        await ref.read(scanRepositoryProvider).syncGuestScans(userId);
      }
      
      state = const AuthState(isLoading: false);
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
