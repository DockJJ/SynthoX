import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_config.dart';

class SocketService {
  IO.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String accessToken) {
    if (_socket != null && _socket!.connected) return;
    _socket = IO.io(
      ApiConfig.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
    _socket!.onConnect((_) => print('[Socket] Connected'));
    _socket!.onConnectError((e) => print('[Socket] Connect error: $e'));
    _socket!.onDisconnect((_) => print('[Socket] Disconnected'));
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  // ── Messages ──────────────────────────────────────────

  void sendMessage({
    required String conversationId,
    required String content,
    String? tempId,
    required Function(Map<String, dynamic>) onAck,
  }) {
    _socket?.emitWithAck(
      'message:send',
      {
        'conversationId': conversationId,
        'content': content,
        if (tempId != null) 'tempId': tempId,
      },
      ack: (data) => onAck(Map<String, dynamic>.from(data as Map)),
    );
  }

  void markDelivered({
    required String messageId,
    required String conversationId,
  }) =>
      _socket?.emit('message:delivered', {
        'messageId': messageId,
        'conversationId': conversationId,
      });

  void markRead({required String conversationId}) =>
      _socket?.emit('message:read', {'conversationId': conversationId});

  void startTyping({required String conversationId}) =>
      _socket?.emit('typing:start', {'conversationId': conversationId});

  void stopTyping({required String conversationId}) =>
      _socket?.emit('typing:stop', {'conversationId': conversationId});

  void onNewMessage(Function(Map<String, dynamic>) callback) =>
      _socket?.on('message:new',
          (data) => callback(Map<String, dynamic>.from(data as Map)));

  void onMessageDelivered(Function(Map<String, dynamic>) callback) =>
      _socket?.on('message:delivered',
          (data) => callback(Map<String, dynamic>.from(data as Map)));

  void onMessageRead(Function(Map<String, dynamic>) callback) =>
      _socket?.on('message:read',
          (data) => callback(Map<String, dynamic>.from(data as Map)));

  void onTypingStart(Function(Map<String, dynamic>) callback) =>
      _socket?.on('typing:start',
          (data) => callback(Map<String, dynamic>.from(data as Map)));

  void onTypingStop(Function(Map<String, dynamic>) callback) =>
      _socket?.on('typing:stop',
          (data) => callback(Map<String, dynamic>.from(data as Map)));

  void onPresenceUpdate(Function(Map<String, dynamic>) callback) =>
      _socket?.on('presence:update',
          (data) => callback(Map<String, dynamic>.from(data as Map)));

  // ── Calls ─────────────────────────────────────────────

  void inviteCall({required String calleeId, required String callType}) =>
      _socket?.emit('call:invite', {'calleeId': calleeId, 'callType': callType});

  void acceptCall({required String callId}) =>
      _socket?.emit('call:accept', {'callId': callId});

  void rejectCall({required String callId, String? reason}) =>
      _socket?.emit('call:reject', {
        'callId': callId,
        if (reason != null) 'reason': reason,
      });

  void sendOffer({required String callId, required Map<String, dynamic> sdp}) =>
      _socket?.emit('call:offer', {'callId': callId, 'sdp': sdp});

  void sendAnswer(
          {required String callId, required Map<String, dynamic> sdp}) =>
      _socket?.emit('call:answer', {'callId': callId, 'sdp': sdp});

  void sendIceCandidate({
    required String callId,
    required Map<String, dynamic> candidate,
  }) =>
      _socket?.emit(
          'call:ice-candidate', {'callId': callId, 'candidate': candidate});

  void hangup({required String callId, String? reason}) =>
      _socket?.emit('call:hangup', {
        'callId': callId,
        if (reason != null) 'reason': reason,
      });

  void onCallInvite(Function(Map<String, dynamic>) callback) =>
      _socket?.on('call:invite',
          (data) => callback(Map<String, dynamic>.from(data as Map)));

  void onCallAccept(Function(Map<String, dynamic>) callback) =>
      _socket?.on('call:accept',
          (data) => callback(Map<String, dynamic>.from(data as Map)));

  void onCallReject(Function(Map<String, dynamic>) callback) =>
      _socket?.on('call:reject',
          (data) => callback(Map<String, dynamic>.from(data as Map)));

  void onCallBusy(Function(Map<String, dynamic>) callback) =>
      _socket?.on('call:busy',
          (data) => callback(Map<String, dynamic>.from(data as Map)));

  void onCallOffer(Function(Map<String, dynamic>) callback) =>
      _socket?.on('call:offer',
          (data) => callback(Map<String, dynamic>.from(data as Map)));

  void onCallAnswer(Function(Map<String, dynamic>) callback) =>
      _socket?.on('call:answer',
          (data) => callback(Map<String, dynamic>.from(data as Map)));

  void onCallIceCandidate(Function(Map<String, dynamic>) callback) =>
      _socket?.on('call:ice-candidate',
          (data) => callback(Map<String, dynamic>.from(data as Map)));

  void onCallHangup(Function(Map<String, dynamic>) callback) =>
      _socket?.on('call:hangup',
          (data) => callback(Map<String, dynamic>.from(data as Map)));
}
