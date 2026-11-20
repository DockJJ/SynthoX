import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import '../services/socket_service.dart';

class ChatProvider with ChangeNotifier {
  final SocketService _socketService = SocketService();
  
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _currentRoomId;
  String _currentUserId = 'pat123'; // Default current user ID fallback

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get currentRoomId => _currentRoomId;

  ChatProvider() {
    _socketService.connect();
    _listenToIncomingMessages();
  }

  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  void enterRoom(String roomId) {
    if (_currentRoomId == roomId) return;

    if (_currentRoomId != null) {
      _socketService.leaveRoom(_currentRoomId!);
    }

    _currentRoomId = roomId;
    _messages.clear();
    _socketService.joinRoom(roomId);
    fetchRoomHistory(roomId);
  }

  Future<void> fetchRoomHistory(String roomId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse('http://localhost:5000/api/chat/room/$roomId'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List list = body['data']['messages'] ?? [];
        _messages = list
            .map((m) => MessageModel.fromJson(m, currentUserId: _currentUserId))
            .toList();
      } else {
        _loadFallbackMessages(roomId);
      }
    } catch (_) {
      _loadFallbackMessages(roomId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadFallbackMessages(String roomId) {
    _messages = [
      MessageModel(
        id: '1',
        roomId: roomId,
        senderId: 'doc123',
        senderName: 'Dr. Olivia Carter',
        senderRole: 'doctor',
        content: 'Hello! How are you feeling today?',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isMe: false,
      ),
      MessageModel(
        id: '2',
        roomId: roomId,
        senderId: _currentUserId,
        senderName: 'Sarah Jenkins',
        senderRole: 'patient',
        content: 'Hi Doctor, I still have a slight headache.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        isMe: true,
      ),
      MessageModel(
        id: '3',
        roomId: roomId,
        senderId: 'doc123',
        senderName: 'Dr. Olivia Carter',
        senderRole: 'doctor',
        content: 'Did you take the medication I prescribed?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isMe: false,
      ),
    ];
  }

  void sendMessage(String content, {required String senderName, required String senderRole}) {
    if (_currentRoomId == null || content.trim().isEmpty) return;

    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: _currentRoomId!,
      senderId: _currentUserId,
      senderName: senderName,
      senderRole: senderRole,
      content: content.trim(),
      timestamp: DateTime.now(),
      isMe: true,
    );

    _messages.add(newMessage);
    notifyListeners();

    _socketService.sendMessage(
      roomId: _currentRoomId!,
      senderId: _currentUserId,
      senderName: senderName,
      senderRole: senderRole,
      content: content.trim(),
    );
  }

  void _listenToIncomingMessages() {
    _socketService.onMessageReceived((data) {
      final senderId = data['senderId'] ?? '';
      if (senderId != _currentUserId && data['roomId'] == _currentRoomId) {
        final incomingMsg = MessageModel.fromJson(data, currentUserId: _currentUserId);
        _messages.add(incomingMsg);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    if (_currentRoomId != null) {
      _socketService.leaveRoom(_currentRoomId!);
    }
    super.dispose();
  }
}
