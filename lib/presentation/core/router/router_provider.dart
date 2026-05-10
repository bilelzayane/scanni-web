import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/providers/guest_session_provider.dart';
import '../../features/home/home_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/scan/scan_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/result/result_screen.dart';
import '../../features/account/profile_screen.dart';
import '../widgets/main_shell.dart';

import 'package:flutter/material.dart';
import 'dart:async';

class RouterListenable extends ChangeNotifier {
  final Ref _ref;
  ProviderSubscription? _subscription;

  RouterListenable(this._ref) {
    _subscription = _ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    }, fireImmediately: true);
    
    // Also listen to guest state changes
    _ref.listen(isGuestProvider, (previous, next) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}

final routerListenableProvider = Provider<RouterListenable>((ref) {
  final listenable = RouterListenable(ref);
  ref.onDispose(() => listenable.dispose());
  return listenable;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  final listenable = ref.watch(routerListenableProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isGuestState = ref.read(isGuestProvider);
      
      final isOnAuthPage = state.uri.toString() == '/auth';

      // 1. If still loading initial data, don't redirect anywhere
      if (authState.isLoading || isGuestState.isLoading) {
        return null;
      }

      // 2. Determine authentication status with multi-source check
      // Check: Stream value OR Synchronous Current Session OR Synchronous Current User
      final session = authState.value?.session ?? Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null || Supabase.instance.client.auth.currentUser != null;
      final isGuest = isGuestState.value ?? false;

      // Debugging logs (Check your browser console)
      print('DEBUG: Router Redirect - Auth: $isAuthenticated, Guest: $isGuest, Loading: ${authState.isLoading}, Path: ${state.uri}');

      // 3. Redirection Logic
      if (isAuthenticated || isGuest) {
        // If authenticated/guest and trying to go to auth page, send home
        if (isOnAuthPage) return '/';
        // Otherwise, stay where we are
        return null;
      }

      // 4. Not authenticated and not guest: send to auth page
      if (!isOnAuthPage) {
        // If authState is currently refreshing/loading, wait a bit more before forcing login
        if (authState.isRefreshing) return null;
        return '/auth';
      }

      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scan',
                builder: (context, state) => const ScanScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/result/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ResultScreen(id: id);
        },
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
