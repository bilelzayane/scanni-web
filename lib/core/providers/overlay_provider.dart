import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether an overlay (bottom sheet, modal, etc.) is currently active.
/// When true, the CustomGlassNavbar should be hidden/scaled down.
class OverlayNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setActive(bool value) => state = value;
}

final overlayActiveProvider = NotifierProvider<OverlayNotifier, bool>(
  OverlayNotifier.new,
);
