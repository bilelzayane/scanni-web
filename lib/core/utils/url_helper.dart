/// Conditional export: uses dart:html on web, stub on all other platforms.
/// Import THIS file everywhere — never import _web or _stub directly.
export 'url_helper_stub.dart' if (dart.library.html) 'url_helper_web.dart';
