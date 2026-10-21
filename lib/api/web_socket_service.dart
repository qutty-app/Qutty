import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart' show userAgent;
import 'ws_connect.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

/// Server -> client events surfaced to the UI layer.
class WsEvent {
  /// Server opcode (1=Ping, 2=Hello, 3=Send, 4=Messages, 7=Voice, 0=Error).
  final int opcode;
  final int? id;
  final Map<String, dynamic> payload;
  const WsEvent({required this.opcode, this.id, required this.payload});
}

class WebSocketService {
  WebSocketService({
    required this.baseUrl,
    required this.token,
    this.path = '/v1/ws',
  });

  final String baseUrl;
  final String token;
  final String path;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retryTimer;
  Timer? _pingTimer;
  bool _disposed = false;
  int _retryAttempt = 0;
  static const _maxRetryDelay = Duration(seconds: 30);

  ConnectionStatus _status = ConnectionStatus.disconnected;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _eventController = StreamController<WsEvent>.broadcast();

  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  Stream<WsEvent> get events => _eventController.stream;
  ConnectionStatus get status => _status;

  Future<void> connect() async {
    if (_disposed) return;
    if (_channel != null) return;
    _setStatus(ConnectionStatus.connecting);
    try {
      final wsUrl = baseUrl.startsWith('https')
          ? baseUrl.replaceFirst('https', 'wss')
          : baseUrl.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsUrl$path');
      final channel = connectWs(uri, userAgent: userAgent);
      await channel.ready;
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleIncoming,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
      _retryAttempt = 0;
      _setStatus(ConnectionStatus.connected);
      send(100, {'token': token});
      _startPingTimer();
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleIncoming(dynamic data) {
    if (data is! String) return;
    try {
      final raw = jsonDecode(data);
      if (raw is! Map<String, dynamic>) return;
      final opcode = (raw['o'] as num?)?.toInt() ?? 0;
      final id = (raw['id'] as num?)?.toInt();
      final payload = raw['p'];
      final p = payload is Map<String, dynamic> ? payload : <String, dynamic>{};
      _eventController.add(WsEvent(opcode: opcode, id: id, payload: p));
    } catch (_) {
      // Ignore malformed payloads.
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      send(1);
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _handleDisconnect() {
    _stopPingTimer();
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    if (_disposed) {
      _setStatus(ConnectionStatus.disconnected);
      return;
    }
    _setStatus(ConnectionStatus.error);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _retryTimer?.cancel();
    final delaySeconds = min(
      _maxRetryDelay.inSeconds,
      pow(2, _retryAttempt).toInt(),
    );
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      _retryAttempt++;
      if (!_disposed) {
        connect();
      }
    });
  }

  void send(int opcode, [Map<String, dynamic>? payload]) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(
      jsonEncode({
        'id': DateTime.now().microsecondsSinceEpoch,
        'o': opcode,
        'p': ?payload,
      }),
    );
  }

  Future<void> disconnect() async {
    _retryTimer?.cancel();
    _stopPingTimer();
    await _subscription?.cancel();
    _subscription = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      try {
        await channel.sink.close();
      } catch (_) {}
    }
    _setStatus(ConnectionStatus.disconnected);
  }

  void _setStatus(ConnectionStatus value) {
    _status = value;
    _statusController.add(value);
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    await _statusController.close();
    await _eventController.close();
  }
}
