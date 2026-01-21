import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import '../screens/chat_room_screen.dart';
import '../utils/colors.dart';
import '../models/post.dart';
import '../utils/chat_utils.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isPressed = false;
  bool _isHovered = false; // Works primarily on Desktop/Web or with mouse

  @override
  Widget build(BuildContext context) {
    // 1. Determine the transform based on state (Matching your CSS)
    double scale = 1.0;
    double rotation = 0.0;

    if (_isPressed) {
      scale = 0.95; // .card:active { transform: scale(0.95) }
      rotation = 0.03; // .card:active { rotateZ(1.7deg) } -> ~0.03 radians
    } else if (_isHovered) {
      scale = 1.02; // .card:hover { transform: scale(1.05) }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          // transition: all 0.5s
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(scale)
            ..rotateZ(rotation),
          transformAlignment: Alignment.center,
          child: _getLayoutByCategory(), // Your existing layout logic
        ),
      ),
    );
  }

  Widget _getLayoutByCategory() {
    switch (widget.post.category) {
      case 'Marketplace':
        return _buildMarketplaceCard(context, widget.post);
      case 'Newsletters':
        return _buildNewsletterCard(widget.post);
      case 'Events':
        return _buildEventCard(widget.post);
      default:
        return _buildDefaultCard(widget.post);
    }
  }
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Carpooling':
        return AppColors.punchyCoral;    // RED
      case 'Marketplace':
        return AppColors.electricYellow; // YELLOW
      case 'Jobs':
        return AppColors.neonLime;       // GREEN
      case 'Events':
        return AppColors.electricBlue;   // BLUE
      case 'Newsletters':
        return AppColors.electricYellow; // Keep Yellow or choose Purple
      default:
        return AppColors.neonLime;       // Default Green
    }
  }
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Carpooling':
        return Icons.directions_car;
      case 'Market Sell':
        return Icons.shopping_bag;
      case 'Jobs':
        return Icons.work;
      case 'Events':
        return Icons.event;
      case 'Newsletters':
        return Icons.article;
      default:
        return Icons.info;
    }
  }

  Widget _buildEventCard(Post post) {
    final Color eventColor = AppColors.electricBlue; // BLUE for Events
    final DateTime date = post.eventDate ?? post.createdAt;

    return Container(
      margin: const EdgeInsets.only(left: 20, top: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: eventColor, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: IntrinsicHeight( // Ensures the divider matches the content height
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. CALENDAR DATE BLOCK (Left)
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: eventColor.withOpacity(0.1),
                border: Border(right: BorderSide(color: eventColor, width: 2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(), // e.g., MON
                    style: TextStyle(color: eventColor, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd').format(date), // e.g., 12
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
                  ),
                  Text(
                    DateFormat('MMM').format(date).toUpperCase(), // e.g., JAN
                    style: TextStyle(color: eventColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),

            // 2. EVENT DETAILS (Middle)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person, color: AppColors.greyText, size: 12),
                        const SizedBox(width: 4),
                        Text(post.authorName, style: const TextStyle(color: AppColors.greyText, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3. PRICE/ACTION (Right)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: eventColor,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    post.eventFee == 0 || post.eventFee == null ? "FREE" : "Rs.${post.eventFee!.toInt()}",
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDefaultCard(Post post) {
    final Color categoryColor = _getCategoryColor(post.category);
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: categoryColor, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Row (Category + Price)
            Row(
              children: [
                Icon(_getCategoryIcon(post.category), color: categoryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  post.category.toUpperCase(),
                  style: TextStyle(color: categoryColor, fontWeight: FontWeight.w900, fontSize: 12),
                ),
                const Spacer(),
                if (post.category == 'Carpooling' && post.eventFee != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.punchyCoral,
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Text(
                      "Rs.${post.eventFee!.toInt()}",
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 2. Title & Description
            Text(
              post.title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              post.description,
              style: const TextStyle(fontSize: 14, color: AppColors.greyText),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // 3. Footer Row (Author)
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: categoryColor,
                  child: const Icon(Icons.person, color: Colors.black, size: 12),
                ),
                const SizedBox(width: 8),
                Text(post.authorName, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),

            // 4. MESSAGE BUTTON (Moved inside the Column)
            if (post.authorId != currentUser?.uid) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: post.category == 'Carpooling' ? AppColors.punchyCoral : categoryColor,
                        width: 2
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          chatId: getChatId(currentUser!.uid, post.authorId),
                          otherUserId: post.authorId,
                          otherUserName: post.authorName,
                          postTitle: post.title, postCategory: '',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    post.category == 'Carpooling' ? "Message" : "MESSAGE AUTHOR",
                    style: TextStyle(
                        color: post.category == 'Carpooling' ? AppColors.punchyCoral : categoryColor,
                        fontWeight: FontWeight.w900
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarketplaceCard(BuildContext context, Post post) {
    final double fee = post.eventFee ?? 0;
    final Color badgeColor = fee > 500 ? AppColors.neonLime : AppColors.electricYellow;
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Matching Carpooling margin
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: badgeColor, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. IMAGE SECTION (Matching Newsletter/Default logic)
          if (post.images.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(post.images[0], fit: BoxFit.cover),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. HEADER ROW (Exactly like Carpooling/Jobs)
                Row(
                  children: [
                    Icon(Icons.shopping_bag, color: badgeColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      post.category.toUpperCase(),
                      style: TextStyle(color: badgeColor, fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Text(
                        "Rs.${fee.toInt()}",
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. TITLE
                Text(
                  post.title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  post.description,
                  style: const TextStyle(fontSize: 14, color: AppColors.greyText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // 4. MESSAGE BUTTON
                _buildMessageButton(context, post, badgeColor, currentUser),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Small helper for the Price Sticker UI
  Widget _buildPriceBadge(double fee, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, border: Border.all(color: Colors.black, width: 2)),
      child: Text("Rs.${fee.toInt()}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 12)),
    );
  }

// 4. THE BRUTALIST ALERT DIALOG
  void _showOwnPostAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCharcoal,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.electricYellow, width: 3),
          borderRadius: BorderRadius.circular(5),
        ),
        title: const Text("YOUR POST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: const Text("YOU CANNOT START A CHAT WITH YOURSELF.",
            style: TextStyle(color: AppColors.greyText, fontSize: 12, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("GOT IT", style: TextStyle(color: AppColors.electricYellow, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
  Widget _buildNewsletterCard(Post post) {
    // Simple calculation for read time based on description length
    final int readTime = (post.description
        .split(' ')
        .length / 200).ceil().clamp(1, 10);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black, // Deep black background
          border: Border.all(
              color: Colors.white10, width: 1), // Subtle outer border
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE SECTION
            if (post.images.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.white24, width: 1)),
                  ),
                  child: Image.network(
                    post.images[0],
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // 2. CONTENT SECTION
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Info: Yellow Text
                  Text(
                    "TODAY • $readTime MIN READ",
                    style: const TextStyle(
                      color: AppColors.electricYellow,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title: Large White Uppercase
                  Text(
                    post.title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Link: Underlined Text + Arrow
                  Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(
                              color: Colors.white, width: 2)),
                        ),
                        padding: const EdgeInsets.only(right:4, bottom: 4),
                        child: const Text(
                          "READ ARTICLE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                          Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildMessageButton(BuildContext context, Post post, Color badgeColor, firebase_auth.User? currentUser) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: badgeColor, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        onPressed: () {
          if (post.authorId == currentUser?.uid) {
            _showOwnPostAlert(context);
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoomScreen(
                chatId: getChatId(currentUser!.uid, post.authorId),
                otherUserId: post.authorId,
                otherUserName: post.authorName,
                postTitle: post.title,
                postCategory: post.category,
                postImage: post.images.isNotEmpty ? post.images[0] : null,
              ),
            ),
          );
        },
        child: Text(
          "MESSAGE",
          style: TextStyle(color: badgeColor, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
