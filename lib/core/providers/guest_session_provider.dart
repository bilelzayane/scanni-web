import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the current session is an unauthenticated guest session.
/// When true, gated features (History, Account) show a login prompt.
class GuestNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setGuest(bool value) => state = value;
}

final isGuestProvider = NotifierProvider<GuestNotifier, bool>(GuestNotifier.new);
