import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

enum WsEventType { taskCreated, taskUpdated, taskDeleted, connectedCount, unknown }

class WsEvent {
  const WsEvent({required this.type, this.data});
  final WsEventType type;
  final dynamic data;
}

class WebSocketService {
  WebSocketService(this._url);

  final String _url;
  WebSocketChannel? _channel;
  StreamController<WsEvent>? _controller;
  Timer? _reconnectTimer;
  bool _disposed = false;

  Stream<WsEvent> get events => _controller!.stream;

  void connect() {
    _controller ??= StreamController<WsEvent>.broadcast();
    _doConnect();
  }

  void _doConnect() {
    if (_disposed) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      _channel!.stream.listen(
        _onMessage,
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final map = json.decode(raw as String) as Map<String, dynamic>;
      final type = switch (map['type']) {
        'task_created' => WsEventType.taskCreated,
        'task_updated' => WsEventType.taskUpdated,
        'task_deleted' => WsEventType.taskDeleted,
        'connected_count' => WsEventType.connectedCount,
        _ => WsEventType.unknown,
      };
      _controller?.add(WsEvent(type: type, data: map['data'] ?? map));
    } catch (_) {}
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _doConnect);
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _controller?.close();
  }
}
