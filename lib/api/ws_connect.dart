// Opens a websocket with a reported user agent where the platform allows it.
//
// `dart:io` can report it in the handshake, browsers cannot, so the web
// implementation is swapped in here instead.
export 'ws_connect_io.dart' if (dart.library.js_interop) 'ws_connect_web.dart';
