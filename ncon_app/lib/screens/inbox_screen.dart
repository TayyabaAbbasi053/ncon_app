import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/chat_utils.dart';
import '../utils/colors.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
import 'chat_room_screen.dart';
import 'package:ncon_app/models/post.dart'; // Adjust path to your file

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.darkCharcoal,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("MESSAGES", style: TextStyle(color: AppColors.neonLime, fontWeight: FontWeight.w900, letterSpacing: 2)),
        shape: const Border(bottom: BorderSide(color: AppColors.neonLime, width: 2)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query chats where the current user (Buyer or Seller) is a participant
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser?.uid)
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.neonLime));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("NO MESSAGES YET", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900)),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chatDoc = snapshot.data!.docs[index];
              return _buildChatTile(context, chatDoc);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.electricYellow, width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppColors.electricYellow,
          child: const Icon(Icons.person, color: Colors.black),
        ),
        title: Text(
          // Safely check if key exists
          (data.containsKey('postTitle') ? data['postTitle'] : "INQUIRY").toString().toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
        ),
        subtitle: Text(
          doc['lastMessage'] ?? "No messages yet",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.greyText),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.electricYellow, size: 14),
        onTap: () async {
          final myUid = FirebaseAuth.instance.currentUser?.uid;
          final List participants = doc.data().toString().contains('participants')
              ? doc['participants'] : [];

          // Find the ID in the list that IS NOT mine
          final otherUserId = participants.firstWhere(
                  (id) => id != myUid,
                  orElse: () => ""
          );
          // Fetch the full post object from Firestore to pass it to the ChatRoom
          String correctChatId = getChatId(myUid!, otherUserId);

          // 4. Mark messages as read for this specific chat
          await FirebaseFirestore.instance.collection('chats').doc(doc.id).update({
            'unreadBy': FieldValue.arrayRemove([myUid]),
          });

          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatRoomScreen(
                  chatId: correctChatId,
                  otherUserId: otherUserId,
                  otherUserName: doc['postTitle'] ?? "User", postTitle: '', postCategory: '', // Or doc['otherUserName'] if you store it
                ),
              ),
            );
          }
          else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("This post is no longer available.")),
            );
          }
        },
      ),
    );
  }
}