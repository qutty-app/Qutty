import 'package:web_socket_channel/web_socket_channel.dart';

/// Opens [uri] as a websocket.
///
/// Browsers do not let scripts choose the handshake headers, so [userAgent]
/// cannot be reported from the web and is dropped here.
WebSocketChannel connectWs(Uri uri, {String? userAgent}) =>
    WebSocketChannel.connect(uri);
