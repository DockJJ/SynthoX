import 'api_service.dart';

class ConversationsService {
  final ApiService _api = ApiService();

  Future<dynamic> createConversation(String recipientId) async {
    return _api.post('/api/conversations', {'recipientId': recipientId});
  }

  Future<dynamic> listConversations() async {
    return _api.get('/api/conversations');
  }

  Future<dynamic> getConversation(String id) async {
    return _api.get('/api/conversations/$id');
  }
}
