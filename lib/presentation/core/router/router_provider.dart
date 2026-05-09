import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      final currentUser = authRepository.currentUser;
      final isGuest = ref.read(isGuestProvider);
      final isAuthenticated = currentUser != null;
      final isOnAuthPage = state.uri.toString() == '/auth';

      // Allow through if authenticated OR in guest mode
      if (isAuthenticated || isGuest) {
        // Don't let authenticated/guest users sit on /auth
        if (isOnAuthPage) return '/';
        return null;
      }

      // Unauthenticated non-guest: redirect to /auth (except when already there)
      if (!isOnAuthPage) return '/auth';
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
