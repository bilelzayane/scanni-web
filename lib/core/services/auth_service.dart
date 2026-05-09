import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/locale_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});

class AuthService {
  final Ref ref;

  AuthService(this.ref);

  User? get currentUser => Supabase.instance.client.auth.currentUser;

  Stream<AuthState> get authStateChanges =>
      Supabase.instance.client.auth.onAuthStateChange;

  Future<void> initializeAuthListener() async {
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen(
        (data) {
          final session = data.session;

          if (session != null && data.event == AuthChangeEvent.signedIn) {
            // User just signed in, fetch profile data and navigate
            _handleSignIn(session.user);
          } else if (session == null &&
              data.event == AuthChangeEvent.signedOut) {
            // User signed out, handle cleanup if needed
            _handleSignOut();
          }
        },
        onError: (error) {
          // Handle auth state change errors
          if (error.toString().contains('Code verifier') ||
              error.toString().contains('code_verifier')) {
            print(
              'DEBUG: Code verifier error in auth listener, forcing sign-out',
            );
            Supabase.instance.client.auth.signOut();
          }
        },
      );
    } catch (e) {
      print('DEBUG: Error initializing auth listener: $e');
      if (e.toString().contains('Code verifier') ||
          e.toString().contains('code_verifier')) {
        print('DEBUG: Code verifier error during init, forcing sign-out');
        await Supabase.instance.client.auth.signOut();
      }
    }
  }

  Future<void> _handleSignIn(User user) async {
    try {
      // Fetch user profile data
      final profile = await Supabase.instance.client
          .from('user_profiles')
          .select('full_name, language_pref')
          .eq('user_id', user.id)
          .maybeSingle();

      if (profile != null) {
        // Update locale if language preference exists
        final languagePref = profile['language_pref'] as String?;
        if (languagePref != null) {
          ref.read(localeProvider.notifier).setLocale(languagePref);
        }
      }
    } catch (e) {
      print('Error fetching user profile after sign-in: $e');
    }
  }

  void _handleSignOut() {
    // Handle any cleanup needed after sign out
    print('User signed out');
  }
}
