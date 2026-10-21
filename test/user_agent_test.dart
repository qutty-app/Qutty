import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/web_socket_service.dart';

import 'support/fake_api.dart';

void main() {
  group('user agent', () {
    test('has the product-token shape the backend parses', () {
      expect(
        userAgent,
        matches(
          RegExp(
            r'^Qutty/[0-9]+\.[0-9]+ '
            r'\((IOS|MACOS|NT|WINMOB|LINUX|ANDROID|BSD|OTHER) '
            r'(NO|MEDIUM|HIGH)\) '
            r'QuttyFlux/[0-9]+\.[0-9]+$',
          ),
        ),
      );
      expect(userAgent, contains('Qutty/$kApiServiceVersion'));
      expect(userAgent, contains('QuttyFlux/$kAppVersion'));
    });

    test('reports the platform the build runs on', () {
      // `dart:io` knows the OS outright; only the web has to guess, and this
      // test never runs there.
      final expected = switch (Platform.operatingSystem) {
        'ios' => 'IOS',
        'macos' => 'MACOS',
        'windows' => 'NT',
        'linux' => 'LINUX',
        'android' => 'ANDROID',
        String os when os.contains('bsd') => 'BSD',
        String os when os.contains('winmo') || os.contains('wince') => 'WINMOB',
        _ => 'OTHER',
      };
      expect(quttyPlatform.token, expected);
      expect(userAgent, contains('(${quttyPlatform.token} '));
    });

    test('enforce follows StoreBuild and the platform', () {
      final platformLevel = switch (quttyPlatform) {
        QuttyPlatform.ios || QuttyPlatform.macos => QuttyEnforce.high,
        QuttyPlatform.android => QuttyEnforce.medium,
        _ => QuttyEnforce.no,
      };
      expect(quttyEnforce, StoreBuild ? platformLevel : QuttyEnforce.no);
      expect(userAgent, contains(' ${quttyEnforce.token}) '));
    });
  });

  group('reporting to the backend', () {
    test('every API request carries the user agent', () async {
      final overrides = FakeApiHttpOverrides(routes: {'/v1/chats': '[]'});
      HttpOverrides.global = overrides;
      addTearDown(() => HttpOverrides.global = null);

      final api = ApiService(baseUrl: 'https://example.test');
      await api.chats();

      final headers = overrides.requests.single.headers;
      expect(headers['User-Agent'] ?? headers['user-agent'], userAgent);
    });

    test('the websocket handshake carries the user agent', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      String? handshakeUserAgent;
      server.listen((request) async {
        handshakeUserAgent = request.headers.value(HttpHeaders.userAgentHeader);
        try {
          final socket = await WebSocketTransformer.upgrade(request);
          socket.listen((_) {});
        } catch (_) {
          // The test only cares about the headers of a rejected handshake.
        }
      });

      final socket = WebSocketService(
        baseUrl: 'http://${server.address.address}:${server.port}',
        token: 'token',
      );
      await socket.connect();
      addTearDown(socket.dispose);

      expect(socket.status, ConnectionStatus.connected);
      expect(handshakeUserAgent, userAgent);
    });
  });
}
