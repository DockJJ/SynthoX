import 'package:flutter/material.dart';

class PharmacyChatListScreen extends StatelessWidget {
  const PharmacyChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Customer Chat',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.separated(
        itemCount: 3,
        separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 1),
        itemBuilder: (context, index) {
          final chats = [
            {'name': 'Sarah Jenkins', 'msg': 'Is the Paracetamol in stock?', 'time': '10:30 AM', 'unread': true},
            {'name': 'Michael Chen', 'msg': 'When can I pick up my order?', 'time': 'Yesterday', 'unread': false},
            {'name': 'Emily Davis', 'msg': 'Thank you for the fast delivery!', 'time': 'Monday', 'unread': false},
          ];
          final chat = chats[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE3F2FD),
              child: const Icon(Icons.person, color: Color(0xFF1976D2)),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(chat['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                Text(chat['time'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            subtitle: Text(chat['msg'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () {},
          );
        },
      ),
    );
  }
}
