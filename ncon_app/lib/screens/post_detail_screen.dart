import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../models/post.dart';
import 'add_post_screen.dart';
import 'chat_room_screen.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;
  PostDetailScreen({super.key, required this.post});

  final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

  // --- HELPER METHODS (Existing) ---
  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    // Check if this message has a post attached
    bool hasPostAttached = msg['attachedPostTitle'] != null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.electricYellow : AppColors.surface,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasPostAttached)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black.withOpacity(0.1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ONLY render the image if it exists
                    if (msg['attachedPostImage'] != null) ...[
                      Image.network(
                          msg['attachedPostImage'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover
                      ),
                      const SizedBox(width: 8),
                    ],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['attachedPostTitle'].toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          msg['attachedPostCategory'] ?? "",
                          style: const TextStyle(fontSize: 8, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            // ACTUAL TEXT MESSAGE
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                msg['text'],
                style: TextStyle(color: isMe ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _timeBlock(String label, DateTime? time) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.greyText, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 6),
        Text(time != null ? DateFormat('hh:mm a').format(time) : "--:--", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white)),
      ],
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color, border: Border.all(color: Colors.black, width: 2)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.black, size: 14),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
      ]),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Carpooling': return Icons.directions_car;
      case 'Marketplace': return Icons.shopping_bag;
      case 'Jobs': return Icons.work;
      case 'Events': return Icons.event;
      default: return Icons.info;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Carpooling': return AppColors.punchyCoral;
      case 'Marketplace': return AppColors.electricYellow;
      case 'Jobs': return AppColors.neonLime;
      case 'Events': return AppColors.electricBlue;
      default: return AppColors.neonLime;
    }
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AddPostScreen(postToEdit: post)));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCharcoal,
        shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.punchyCoral, width: 3), borderRadius: BorderRadius.circular(5)),
        title: const Text("DELETE POST?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: const Text("THIS ACTION CANNOT BE UNDONE.", style: TextStyle(color: AppColors.greyText, fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.punchyCoral),
            onPressed: () async {
              await FirestoreService().deletePost(post.postId);
              if (!context.mounted) return;
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleBuyTicket(BuildContext context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.darkCharcoal,
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.electricYellow, width: 4))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("CONFIRM PURCHASE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 10),
              Text("Pay Rs. ${post.eventFee} to join ${post.title}?", style: const TextStyle(color: AppColors.greyText)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonLime, minimumSize: const Size(double.infinity, 50)),
                onPressed: () => Navigator.pop(context),
                child: const Text("PROCEED TO PAY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        )
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.black, border: Border.all(color: color, width: 2)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isPaidEvent = post.category == 'Events' && post.eventFee != null && post.eventFee! > 0;

    return Scaffold(
      backgroundColor: AppColors.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.neonLime),
        shape: const Border(bottom: BorderSide(color: AppColors.neonLime, width: 2)),
        title: const Text('DETAILS', style: TextStyle(color: AppColors.neonLime, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                _buildBadge(post.category, _getCategoryIcon(post.category), _getCategoryColor(post.category)),
                const Spacer(),
                if (post.category != 'Jobs' && post.category != 'Newsletters' && post.eventFee != null)
                  Text("Rs. ${post.eventFee}", style: const TextStyle(color: AppColors.electricYellow, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 20),
            Text(post.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: AppColors.neonLime, letterSpacing: -1)),
            const SizedBox(height: 12),
            Text(post.description, style: const TextStyle(fontSize: 16, color: AppColors.greyText, height: 1.6)),
            const SizedBox(height: 24),

            if (isPaidEvent)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricYellow,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    side: const BorderSide(color: Colors.black, width: 3),
                  ),
                  onPressed: () => _handleBuyTicket(context),
                  child: const Text("BUY TICKET", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                ),
              ),

            if (post.category == 'Events' && post.eventDate != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.electricBlue, width: 3)),
                child: Column(
                  children: [
                    Row(children: [
                      const Icon(Icons.calendar_today, color: AppColors.electricBlue, size: 20),
                      const SizedBox(width: 16),
                      Text(DateFormat('EEEE, MMM d').format(post.eventDate!), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    ]),
                    const Divider(height: 40, color: AppColors.electricBlue),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _timeBlock("Starts", post.eventDate),
                      Container(height: 40, width: 2, color: AppColors.electricBlue),
                      _timeBlock("Ends", post.eventEndDate),
                    ]),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            if (post.images.isNotEmpty) ...[
              const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.electricYellow)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: post.images.length,
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(border: Border.all(color: AppColors.electricYellow, width: 3)),
                  child: Image.network(post.images[index], fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 30),
            ],

            // AUTHOR INFO BOX
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.punchyCoral, width: 3)),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.punchyCoral, border: Border.all(color: Colors.black, width: 2)),
                    child: const Icon(Icons.person, color: Colors.black),
                  ),
                  const SizedBox(width: 15),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Posted by', style: TextStyle(fontSize: 12, color: AppColors.greyText)),
                    Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- NEW: MESSAGE DRIVER BUTTON (Added Here) ---
            // --- UPDATED: MESSAGE BUTTON FOR CARPOOLING & MARKETPLACE ---
            if ((post.category == 'Carpooling' || post.category == 'Marketplace') && post.authorId != currentUser?.uid)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _buildActionButton(
                  label: post.category == 'Carpooling' ? "MESSAGE DRIVER" : "CONTACT SELLER",
                  icon: Icons.chat_bubble_outline,
                  color: AppColors.neonLime,
                  onTap: () {
                    List<String> ids = [currentUser!.uid, post.authorId];
                    ids.sort();
                    String chatRoomId = ids.join("_");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          chatId: chatRoomId,
                          otherUserId: post.authorId,
                          otherUserName: post.authorName,
                          postTitle: post.title,
                          postCategory: post.category,
                          postImage: post.images.isNotEmpty ? post.images[0] : null,
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            if (post.authorId == currentUser?.uid)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: _buildActionButton(label: "EDIT POST", icon: Icons.edit_note, color: AppColors.electricBlue, onTap: () => _navigateToEdit(context))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActionButton(label: "DELETE", icon: Icons.delete_outline, color: AppColors.punchyCoral, onTap: () => _confirmDelete(context))),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

