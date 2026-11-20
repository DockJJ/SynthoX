import 'package:flutter/material.dart';
import 'doctor_chat_detail_screen.dart';

class DoctorChatListScreen extends StatelessWidget {
  const DoctorChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Patient Messages',
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
            {'name': 'Sarah Jenkins', 'msg': 'Thank you, doctor. I will take the medication.', 'time': '10:30 AM', 'unread': true},
            {'name': 'Michael Chen', 'msg': 'Can we reschedule?', 'time': 'Yesterday', 'unread': false},
            {'name': 'Emily Davis', 'msg': 'The pain is much better now.', 'time': 'Monday', 'unread': false},
            {'name': 'Alex Johnson', 'msg': 'When should I come in?', 'time': 'Jan 12', 'unread': false},
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
                  child: const Icon(Icons.person, color: Color(0xFF1976D2)),
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
                MaterialPageRoute(
                  builder: (context) => DoctorChatDetailScreen(
                    patientName: chat['name'] as String,
                    conversationId: 'doc_conv_$index',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
