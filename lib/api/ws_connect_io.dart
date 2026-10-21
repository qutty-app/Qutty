import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Opens [uri] as a websocket, reporting [userAgent] in the handshake.
///
/// Passing `User-Agent` as a plain header does not work: `dart:io` keeps its
/// own default user agent and appends it in front of the value, which would
/// prefix the product token the backend parses. The value therefore goes in
/// as the client's user agent, which it then reports on its own.
WebSocketChannel connectWs(Uri uri, {String? userAgent}) =>
    IOWebSocketChannel.connect(
      uri,
      customClient: userAgent == null
          ? null
          : (HttpClient()..userAgent = userAgent),
    );
