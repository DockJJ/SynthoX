import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  void connect({String? serverUrl}) {
    final url = serverUrl ?? ApiConfig.socketUrl;
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Connected to SynthoX WebSocket server');
    });

    _socket!.onDisconnect((_) {
      debugPrint('Disconnected from SynthoX WebSocket server');
    });

    _socket!.onConnectError((err) {
      debugPrint('WebSocket Connection Error: $err');
    });
  }

  void joinRoom(String roomId) {
    _socket?.emit('join_room', roomId);
  }

  void leaveRoom(String roomId) {
    _socket?.emit('leave_room', roomId);
  }

  void sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
  }) {
    final payload = {
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'content': content,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _socket?.emit('send_message', payload);
  }

  void onMessageReceived(Function(Map<String, dynamic>) callback) {
    _socket?.on('receive_message', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  void initiateCall({
    required String roomId,
    required String callerName,
    required String callerId,
    String callType = 'video',
  }) {
    _socket?.emit('initiate_call', {
      'roomId': roomId,
      'callerName': callerName,
      'callerId': callerId,
      'callType': callType,
    });
  }

  void onIncomingCall(Function(Map<String, dynamic>) callback) {
    _socket?.on('incoming_call', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  void endCall(String roomId) {
    _socket?.emit('end_call', {'roomId': roomId});
  }

  void onCallEnded(Function() callback) {
    _socket?.on('call_ended', (_) => callback());
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
