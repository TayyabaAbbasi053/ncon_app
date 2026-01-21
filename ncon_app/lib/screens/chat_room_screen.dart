import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'package:intl/intl.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String postTitle;
  final String postCategory;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.postTitle,
    required this.postCategory,
    this.postImage,
  });
  final String? postImage;
  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  Map<String, dynamic>? replyMessage;
  final TextEditingController _messageController = TextEditingController();
  final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String myUid = currentUser!.uid;

    // 1. Fetch your actual name from the 'users' collection
    final myUserDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
    final String myName = myUserDoc.data()?['name'] ?? "User";

    final messageData = {
      'text': _messageController.text.trim(),
      'senderId': myUid,
      'senderName': myName,
      'timestamp': FieldValue.serverTimestamp(),
      'replyTo': replyMessage, // Save reply context if it exists
    };

    // 2. Add the message to the subcollection
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add(messageData);

    // 3. Update the main chat document
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'postTitle': widget.postTitle,
      'postCategory': widget.postCategory,
      'lastMessage': _messageController.text.trim(),
      'lastTimestamp': FieldValue.serverTimestamp(),
      'lastSenderId': myUid,
      'participants': FieldValue.arrayUnion([myUid, widget.otherUserId]),
      'unreadBy': FieldValue.arrayUnion([widget.otherUserId]),
      'senderName': myName,
      'receiverName': widget.otherUserName,
    }, SetOptions(merge: true));

    // 4. Clear unread and reset UI
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'unreadBy': FieldValue.arrayRemove([myUid]),
    });

    _messageController.clear();
    setState(() => replyMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCharcoal,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserName.toUpperCase(),
              style: const TextStyle(color: AppColors.electricYellow, fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        shape: const Border(bottom: BorderSide(color: AppColors.electricYellow, width: 2)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    bool isMe = msg['senderId'] == currentUser?.uid;

                    return GestureDetector(
                      onLongPress: () {
                        setState(() => replyMessage = msg);
                      },
                      child: _buildMessageBubble(msg, isMe),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (msg['replyTo'] != null)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.black26,
                  border: Border(left: BorderSide(color: isMe ? Colors.white : AppColors.electricYellow, width: 2))
              ),
              child: Text(
                msg['replyTo']['text'],
                style: const TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            decoration: BoxDecoration(
              color: isMe ? AppColors.electricYellow : AppColors.surface,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: [
                BoxShadow(
                  color: isMe ? AppColors.electricYellow.withOpacity(0.3) : Colors.black,
                  offset: const Offset(4, 4),
                )
              ],
            ),
            child: Text(
              msg['text'],
              style: TextStyle(
                color: isMe ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (replyMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(left: BorderSide(color: AppColors.electricYellow, width: 4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "REPLYING TO ${replyMessage!['senderName']?.toString().toUpperCase() ?? 'USER'}",
                        style: const TextStyle(color: AppColors.electricYellow, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        replyMessage!['text'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.white),
                  onPressed: () => setState(() => replyMessage = null),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "TYPE MESSAGE...",
                    hintStyle: TextStyle(color: AppColors.greyText, fontWeight: FontWeight.w900, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surface,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.electricYellow, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  height: 54, width: 54,
                  decoration: BoxDecoration(
                    color: AppColors.electricYellow,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.send, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}