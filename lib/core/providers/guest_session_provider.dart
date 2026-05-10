import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the current session is an unauthenticated guest session.
class GuestNotifier extends AsyncNotifier<bool> {
  static const _key = 'is_guest_mode';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> setGuest(bool value) async {
    state = const AsyncLoading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    state = AsyncData(value);
  }
}

final isGuestProvider = AsyncNotifierProvider<GuestNotifier, bool>(GuestNotifier.new);
