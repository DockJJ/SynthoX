import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0D47A1)),
        title: const Text(
          'Messages',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: 4,
        separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 1),
        itemBuilder: (context, index) {
          final chats = [
            {'name': 'Dr. Olivia Carter', 'role': 'Cardiologist', 'msg': 'Your test results are ready.', 'time': '10:30 AM', 'unread': true},
            {'name': 'City Pharmacy', 'role': 'Pharmacy', 'msg': 'Your order has been dispatched.', 'time': 'Yesterday', 'unread': false},
            {'name': 'Dr. Marcus Webb', 'role': 'Dentist', 'msg': 'See you next week!', 'time': 'Monday', 'unread': false},
            {'name': 'Lab Center', 'role': 'Diagnostics', 'msg': 'Please fast for 12 hours prior.', 'time': 'Jan 12', 'unread': false},
          ];
          
          final chat = chats[index];
          final isUnread = chat['unread'] as bool;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Stack(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    chat['role'] == 'Pharmacy' ? Icons.local_pharmacy : Icons.person,
                    color: const Color(0xFF1976D2),
                  ),
                ),
                if (isUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      height: 14,
                      width: 14,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  )
              ],
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  chat['name'] as String,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF0D47A1),
                  ),
                ),
                Text(
                  chat['time'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnread ? const Color(0xFF0D47A1) : Colors.grey,
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                chat['msg'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isUnread ? Colors.black87 : Colors.grey,
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatDetailScreen(name: chat['name'] as String, conversationId: 'conv_$index')),
              );
            },
          );
        },
      ),
    );
  }
}
