import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;


final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Use real Supabase authentication
  return SupabaseAuthRepository(Supabase.instance.client);
});


final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;
  User? get currentUser;
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  );
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: Use Supabase's native OAuth flow
      final origin = html.window.location.origin;
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: '$origin/',
        queryParams: {
          'prompt': 'select_account',
          'access_type': 'offline',
        },
      );
    } else {
      // Mobile: Use google_sign_in package
      const webClientId =
          'YOUR_WEB_CLIENT_ID'; // TODO: Replace with your actual web client ID
      const iosClientId =
          'YOUR_IOS_CLIENT_ID'; // TODO: Replace with your actual iOS client ID

      await GoogleSignIn.instance.initialize(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      final googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        throw 'Google sign in was canceled by the user.';
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'Missing Google Auth Token.';
      }

      final authResponse = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final user = authResponse.user;
      if (user != null) {
        final userProfile = await _client
            .from('user_profiles')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (userProfile == null) {
          await _client.from('user_profiles').insert({
            'user_id': user.id,
            'full_name': googleUser.displayName ?? 'Unknown User',
            'language_pref': 'en',
          });
        }
      }
    }
  }
}

