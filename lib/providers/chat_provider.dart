import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _currentConversationId;
  String _currentUserId = '';
  bool _isOtherTyping = false;

  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isOtherTyping => _isOtherTyping;

  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  void initSocket(SocketService socketService) {
    socketService.onNewMessage(_onNewMessage);
    socketService.onTypingStart(_onTypingStart);
    socketService.onTypingStop(_onTypingStop);
  }

  Future<void> enterConversation(String conversationId) async {
    _currentConversationId = conversationId;
    _messages = [];
    _isOtherTyping = false;
    notifyListeners();
    await fetchHistory(conversationId);
  }

  Future<void> fetchHistory(String conversationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService()
          .get('/api/conversations/$conversationId/messages?limit=50');
      final raw = data['messages'] as List<dynamic>? ?? [];
      _messages = raw
          .map((e) => MessageModel.fromJson(
                e as Map<String, dynamic>,
                currentUserId: _currentUserId,
              ))
          .toList();
    } catch (_) {
      _messages = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendMessage(SocketService socketService, String content) async {
    if (_currentConversationId == null) return false;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = MessageModel(
      id: tempId,
      conversationId: _currentConversationId!,
      senderId: _currentUserId,
      sender: MessageSender(
        id: _currentUserId,
        username: '',
        displayName: 'Me',
      ),
      content: content,
      createdAt: DateTime.now(),
      isMe: true,
    );

    _messages.add(tempMessage);
    notifyListeners();

    final completer = _Completer<bool>();

    socketService.sendMessage(
      conversationId: _currentConversationId!,
      content: content,
      tempId: tempId,
      onAck: (data) {
        final success = data['success'] as bool? ?? false;
        if (success) {
          final msgData = data['message'] as Map<String, dynamic>?;
          final idx = _messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            if (msgData != null) {
              final serverMsg = MessageModel.fromJson(
                msgData,
                currentUserId: _currentUserId,
              );
              _messages[idx] = serverMsg;
            }
          }
          completer.complete(true);
        } else {
          _messages.removeWhere((m) => m.id == tempId);
          completer.complete(false);
        }
        notifyListeners();
      },
    );

    return completer.future;
  }

  void _onNewMessage(Map<String, dynamic> data) {
    final msgData = data['message'] as Map<String, dynamic>?;
    if (msgData == null) return;
    final convId = msgData['conversationId'] as String?;
    if (convId != _currentConversationId) return;
    final msg = MessageModel.fromJson(msgData, currentUserId: _currentUserId);
    // Avoid duplicates (in case the sender also receives message:new)
    if (!_messages.any((m) => m.id == msg.id)) {
      _messages.add(msg);
      notifyListeners();
    }
  }

  void _onTypingStart(Map<String, dynamic> data) {
    final convId = data['conversationId'] as String?;
    if (convId == _currentConversationId) {
      _isOtherTyping = true;
      notifyListeners();
    }
  }

  void _onTypingStop(Map<String, dynamic> data) {
    final convId = data['conversationId'] as String?;
    if (convId == _currentConversationId) {
      _isOtherTyping = false;
      notifyListeners();
    }
  }
}

/// Minimal completer-like helper to bridge socket ack callback to Future.
class _Completer<T> {
  T? _value;
  bool _isCompleted = false;
  final List<void Function(T)> _callbacks = [];

  void complete(T value) {
    if (_isCompleted) return;
    _isCompleted = true;
    _value = value;
    for (final cb in _callbacks) {
      cb(value);
    }
  }

  Future<T> get future async {
    if (_isCompleted) return _value as T;
    return await Future<T>(() async {
      while (!_isCompleted) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return _value as T;
    });
  }
}
