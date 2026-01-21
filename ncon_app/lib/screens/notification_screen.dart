import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/chat_utils.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import 'chat_room_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCharcoal,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("NOTIFICATIONS", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: FirebaseAuth.instance.currentUser!.uid)
            //.orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Check for message-based notifications
          final messageDocs = snapshot.data?.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['lastSenderId'] != FirebaseAuth.instance.currentUser?.uid;
          }).toList() ?? [];

          // If we add 'likes' or 'system alerts' later, they go here:
          final otherAlerts = [];

          if (messageDocs.isEmpty && otherAlerts.isEmpty) {
            return const Center(
              child: Text("NO NEW NOTIFICATIONS",
                  style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (messageDocs.isNotEmpty) ...[
                const Text("UNREAD MESSAGES", style: TextStyle(color: AppColors.neonLime, fontWeight: FontWeight.w900, fontSize: 12)),
                const SizedBox(height: 10),
                ...messageDocs.map((doc) => _buildNotificationTile(context, doc)),
              ],
              // Future sections for 'Likes', 'Updates' etc. can be added here
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {}; // Use map from start
    final String myUid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;

    // 1. Get Fields Safely
    final String postTitle = data['postTitle'] ?? 'Discussion';
    final String lastMessage = data['lastMessage'] ?? '';

    // 2. Determine Display Name
    // If the last sender was NOT me, show their name.
    // If the last sender WAS me, we need a 'receiverName' field or just show 'Chat'.
    String displayName = data['senderName'] ?? "User";
    if (data['lastSenderId'] == myUid) {
      displayName = "You: ${data['lastMessage']}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(left: BorderSide(color: AppColors.neonLime, width: 4)),
      ),
      child: ListTile(
          title: Text(postTitle.toUpperCase(), style: const TextStyle(color: AppColors.neonLime, fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 11)), // Show who it's from
          trailing: const Icon(Icons.chevron_right, color: AppColors.neonLime),
          onTap: () {
            try {
              final List<dynamic> participants = data['participants'] ?? [];

              // Find the ID that IS NOT mine
              final String otherUid = participants.firstWhere(
                      (id) => id != myUid,
                  orElse: () => data['senderId'] ?? ''
              );

              if (otherUid.isEmpty) return;

              String correctChatId = getChatId(myUid, otherUid);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatRoomScreen(
                    chatId: correctChatId,
                    otherUserId: otherUid,
                    // We pass the name we want to see at the top of the chat room
                    otherUserName: (data['lastSenderId'] != myUid)
                        ? (data['senderName'] ?? "User")
                        : "Chat",
                    postTitle: postTitle, postCategory: '',
                  ),
                ),
              );
            } catch (e) {
              print("Navigation Error: $e");
            }
          }
      ),
    );
  }
}