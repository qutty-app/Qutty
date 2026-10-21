import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Minimal in-memory stand-in for the API transport.
///
/// Serves canned bodies by request path so widget tests can mount screens that
/// talk to the backend without touching the network. The parts of the
/// `HttpClient` surface the app never uses fall through `noSuchMethod`.
class FakeApiHttpOverrides extends HttpOverrides {
  FakeApiHttpOverrides({this.failAll = false, this.routes = const {}});

  /// When true every request throws, to exercise offline behaviour.
  bool failAll;

  /// Response bodies keyed by request path, e.g. `{'/v1/chats': '[]'}`.
  ///
  /// A key may instead be qualified with the method, e.g.
  /// `{'POST /v1/chats/7/messages': '{...}'}`, for a path whose GET and POST
  /// return different shapes.
  ///
  /// A value of the form `b64:<base64>` is served as raw binary with no
  /// content type, which is how tests get a real decodable image out of
  /// `Image.network` instead of a decode failure.
  final Map<String, String> routes;
  final Map<String, int> statusCodes = {};

  /// Every request the client made, in order, so a test can assert that a
  /// favourite was actually saved rather than only that the heart filled in.
  final List<FakeRequest> requests = [];

  @override
  HttpClient createHttpClient(SecurityContext? context) => FakeHttpClient(
    failAll: failAll,
    routes: routes,
    statusCodes: statusCodes,
    requests: requests,
  );
}

/// One recorded request.
class FakeRequest {
  FakeRequest(this.method, this.path, this.query);

  final String method;
  final String path;
  final Map<String, String> query;

  /// The request body as UTF-8 text, filled in when the request closes.
  String body = '';

  /// The headers the client actually sent, filled in when the request closes.
  ///
  /// Recorded at close rather than at open because the client sets headers after
  /// it has the request object, so at open time they are still empty.
  final Map<String, String> headers = {};

  @override
  String toString() => '$method $path${query.isEmpty ? '' : ' $query'}';
}

class FakeHttpClient implements HttpClient {
  FakeHttpClient({
    required this.failAll,
    required this.routes,
    required this.statusCodes,
    List<FakeRequest>? requests,
  }) : requests = requests ?? <FakeRequest>[];

  final bool failAll;
  final Map<String, String> routes;
  final Map<String, int> statusCodes;
  final List<FakeRequest> requests;

  @override
  Future<HttpClientRequest> getUrl(Uri url) => _open('GET', url);
  @override
  Future<HttpClientRequest> postUrl(Uri url) => _open('POST', url);
  @override
  Future<HttpClientRequest> putUrl(Uri url) => _open('PUT', url);
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => _open('DELETE', url);
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _open('PATCH', url);
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      _open(method, url);

  @override
  void close({bool force = false}) {}

  Future<HttpClientRequest> _open(String method, Uri url) async {
    if (failAll) throw const SocketException('network down');
    final record = FakeRequest(method, url.path, Map.of(url.queryParameters));
    requests.add(record);

    final path = url.path;
    // A key may be `"GET /v1/chats/7/messages"` when a path needs a different
    // body per method, which is the case for the chat message collection: a GET
    // returns a list of messages and a POST returns the one that was created.
    final String? canned = routes["$method $path"] ?? routes[path];
    if (canned != null) {
      return FakeHttpClientRequest(
        method,
        _encodeBody(canned),
        record,
        statusCodes["$method $path"] ?? statusCodes[path] ?? 200,
      );
    }

    // GIF defaults, so tests only have to state the responses they actually
    // care about. The shape matches the backend's own responses.
    final dynamic fallback = switch (path) {
      '/v1/auth/login' => {'token': 'token-abc'},
      '/v1/chats' => <dynamic>[],
      '/v1/gifs/search' => {
        'items': [
          _gif(id: 1, slug: 'funny-cat-1', title: 'Chatty Cat'),
          _gif(id: 2, slug: 'happy-dog-2', title: 'Happy Dog'),
        ],
        'page': 1,
        'has_next': false,
      },
      // One saved GIF, because this is the view the tab opens on: an empty
      // default would leave every test with a blank grid. `id` is 0, which is
      // how the backend returns a row it serves from its own favourites table
      // rather than from KLIPY.
      '/v1/gifs/favorites' => {
        'items': [_favoriteGif(slug: 'funny-cat-1', title: 'Chatty Cat')],
        'page': 1,
        'has_next': false,
      },
      _ => <String, dynamic>{},
    };
    return FakeHttpClientRequest(
      method,
      utf8.encode(jsonEncode(fallback)),
      record,
      statusCodes["$method $path"] ?? statusCodes[path] ?? 200,
    );
  }

  /// Decodes a `b64:` body to raw bytes, and otherwise encodes as UTF-8.
  static List<int> _encodeBody(String body) {
    if (body.startsWith('b64:')) {
      return base64Decode(body.substring(4));
    }
    return utf8.encode(body);
  }

  /// One canned GIF, shaped like the backend's item but with no file
  /// renditions, which the picker does not read before resolving.
  /// A saved GIF as the server serves it from its own table: no `files`, just
  /// the stored animation URL and the still preview.
  static Map<String, dynamic> _favoriteGif({
    required String slug,
    required String title,
  }) => {
    'id': 0,
    'slug': slug,
    'title': title,
    'preview': 'https://static.klipy.com/$slug.jpg',
    'animation_url': 'https://static.klipy.com/$slug-xs.webp',
    'width': 220,
    'height': 220,
    'tags': <String>[],
    'files': <String, dynamic>{},
  };

  static Map<String, dynamic> _gif({
    required int id,
    required String slug,
    required String title,
    bool animated = true,
  }) => {
    'id': id,
    'slug': slug,
    'title': title,
    // Always a still JPEG, because that is what the backend sends and using it
    // is exactly the bug that made every result look frozen.
    'preview': 'https://static.klipy.com/$slug.jpg',
    'width': 220,
    'height': 220,
    'tags': <String>[],
    'files': {
      'xs': animated
          ? {
              'webp': {
                'url': 'https://static.klipy.com/$slug-xs.webp',
                'width': 90,
                'height': 90,
                'size': 1024,
              },
            }
          : <String, dynamic>{},
      'sm': <String, dynamic>{},
      'md': <String, dynamic>{},
      'hd': <String, dynamic>{},
    },
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpClientRequest implements HttpClientRequest {
  FakeHttpClientRequest(
    this.method,
    this.bodyBytes,
    this.record,
    this.statusCode,
  );

  @override
  final String method;
  final List<int> bodyBytes;

  /// The entry this request will fill its headers into.
  final FakeRequest record;
  final int statusCode;

  @override
  final HttpHeaders headers = FakeHttpHeaders();

  /// Bytes written through the [IOSink] surface, which is how `package:http`
  /// hands over the encoded body. Consumed into [record] at close, so a test can
  /// assert what was actually sent rather than only that a request happened.
  final List<int> _requestBody = [];

  @override
  int contentLength = 0;

  @override
  bool persistentConnection = true;
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  Future<HttpClientResponse> close() async {
    // Headers are only final at this point, which is why they are collected here
    // and not when the request is opened.
    headers.forEach((name, values) {
      for (final value in values) {
        record.headers.putIfAbsent(name, () => value);
      }
    });
    record.body = utf8.decode(_requestBody, allowMalformed: true);
    return FakeHttpClientResponse(statusCode, bodyBytes);
  }

  @override
  void add(List<int> data) => _requestBody.addAll(data);

  @override
  void write(Object? object) => add(utf8.encode(object?.toString() ?? ''));

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _requestBody.addAll(chunk);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpClientResponse implements HttpClientResponse {
  FakeHttpClientResponse(this._statusCode, this._body);

  final int _statusCode;
  final List<int> _body;

  @override
  int get statusCode => _statusCode;
  @override
  String get reasonPhrase => _statusCode == 200 ? 'OK' : 'Error';
  @override
  HttpHeaders get headers => FakeHttpHeaders();
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => false;
  @override
  int get contentLength => _body.length;
  @override
  List<RedirectInfo> get redirects => const [];

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> data)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.fromIterable([_body]).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = {};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _values.putIfAbsent(name, () => []).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name] = [value.toString()];
  }

  @override
  void forEach(void Function(String name, List<String> values) f) =>
      _values.forEach(f);

  @override
  String? value(String name) => _values[name]?.firstOrNull;

  @override
  void remove(String name, Object? value) => _values.remove(name);
  @override
  void removeAll(String name) => _values.remove(name);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
