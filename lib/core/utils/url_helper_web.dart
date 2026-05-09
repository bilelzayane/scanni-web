/// Web implementation — clears OAuth query params while keeping the #/auth fragment.
/// Only acts when the URL actually contains ?code= or ?error= to avoid
/// resetting the app state for guests who have a clean URL.
import 'dart:html' as html;

void clearAuthUrl() {
  try {
    final search = html.window.location.search ?? '';
    if (search.contains('code=') || search.contains('error=')) {
      html.window.history.replaceState(null, '', '/#/auth');
    }
  } catch (e) {
    // Silently fail if HTML APIs are not available
  }
}
