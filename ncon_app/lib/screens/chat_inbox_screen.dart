import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'chat_room_screen.dart';

class ChatInboxScreen extends StatelessWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black, // Matching your theme
      appBar: AppBar(
        iconTheme: const IconThemeData(color: AppColors.neonLime),
        title: const Text(
            "INBOX",
            style: TextStyle(color: AppColors.neonLime, fontWeight: FontWeight.bold, letterSpacing: 2)
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: AppColors.neonLime, height: 2),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: myUid)
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error loading chats: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.neonLime));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
                child: Text("NO CONVERSATIONS YET", style: TextStyle(color: AppColors.greyText, fontWeight: FontWeight.bold))
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String myUid = FirebaseAuth.instance.currentUser!.uid;
              final List participants = data['participants'] ?? [];

              // 1. Identify the OTHER user's UID
              final String otherUid = participants.firstWhere(
                      (id) => id != myUid,
                  orElse: () => ''
              );
              String displayName = "User";

              if (data['lastSenderId'] == myUid) {
                displayName = data['receiverName'] ?? "User";
              } else {
                displayName = data['senderName'] ?? "User";
              }
              print("--- CHAT DEBUG ---");
              print("Other Person Name: $displayName");
              print("Last Message: ${data['lastMessage']}");
              return Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A), width: 1)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: Container(
                    padding: const EdgeInsets.all(2), // This creates the border thickness
                    decoration: BoxDecoration(
                      color: AppColors.neonLime, // The border color
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.darkCharcoal, // Background inside the border
                      child: const Icon(Icons.person, color: AppColors.neonLime),
                    ),
                  ),
                  title: Text(
                    (data['postTitle'] ?? 'GENERAL').toUpperCase(),
                    style: const TextStyle(color: AppColors.neonLime, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "${displayName}: ${data['lastMessage'] ?? ''}",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.neonLime, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        chatId: docs[index].id, // This is already the sorted ID
                        otherUserId: otherUid,
                        otherUserName: displayName,
                        postTitle: data['postTitle'], postCategory: '',
                      ),
                    ),
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