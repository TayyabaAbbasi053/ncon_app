import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/bottom_nav.dart';
import '../services/firestore_service.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';
import 'add_post_screen.dart';
import 'chat_inbox_screen.dart';
import 'inbox_screen.dart';
import 'login_screen.dart';
import 'account_screen.dart';
import 'category_selection_screen.dart';
import 'notification_screen.dart';
import 'post_detail_screen.dart';
import 'package:intl/intl.dart';
import 'events_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String currentCategory = "All";
  final FirestoreService _firestoreService = FirestoreService();
  List<Post> _posts = [];
  List<Post> _filteredPosts = [];
  bool _isLoading = true;
  String _searchQuery = "";
  List<String> _selectedCategories = ['Carpooling', 'Marketplace', 'Jobs', 'Events', 'Newsletters'];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    setState(() => _isLoading = true);
    _firestoreService.
    getPosts().listen((posts) {
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _filteredPosts = posts;
        _isLoading = false;
      });
    });
  }

  void _filterPostsByCategory(int index) {
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
      if (index == 0) {
        _filteredPosts = _posts;
      } else {
        final category = _getCategoryForIndex(index);
        _filteredPosts = _posts.where((post) => post.category == category).toList();
      }
    });
  }
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCharcoal,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.neonLime, width: 3),
        borderRadius: BorderRadius.circular(5),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("FILTER BY TYPE",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
                  const Divider(color: AppColors.neonLime, thickness: 2),
                  const SizedBox(height: 10),
                  ...['Carpooling', 'Marketplace', 'Jobs', 'Events', 'Newsletters'].map((cat) {
                    return CheckboxListTile(
                      title: Text(cat.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      value: _selectedCategories.contains(cat),
                      activeColor: AppColors.neonLime,
                      checkColor: Colors.black,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true) {
                            _selectedCategories.add(cat);
                          } else {
                            _selectedCategories.remove(cat);
                          }
                        });
                        setState(() {}); // Refresh main screen
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getCategoryForIndex(int index) {
    switch (index) {
      case 1: return 'Carpooling';
      case 2: return 'Marketplace';
      case 3: return 'Jobs';
      case 4: return 'Events';
      case 5: return 'Newsletters';
      default: return 'All';
    }
  }

  void _navigateToAccount() {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
  }

  void _navigateToCreatePost() {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CategorySelectionScreen()));
  }

  Future<void> _refreshPosts() async {
    // Use the index to get the actual category name string
    String categoryName = _getCategoryForIndex(_currentIndex);
    await _fetchPostsByCategory(categoryName);
  }

  @override
  Widget build(BuildContext context) {
    // Filter logic for whichever posts are currently being displayed
    final displayedPosts = _filteredPosts.where((post) {
      bool matchesSearch = post.title.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesFilter = _selectedCategories.contains(post.category);
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'NCON',
          style: TextStyle(color: AppColors.neonLime, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2),
        ),
        shape: const Border(bottom: BorderSide(color: AppColors.neonLime, width: 3)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.neonLime),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.electricBlue),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatInboxScreen())),
          ),
          _buildNotificationButton(),
        ],
        leading: IconButton(
          icon: const Icon(Icons.account_circle, color: AppColors.punchyCoral),
          onPressed: _navigateToAccount,
        ),
        // Hide search bar on Events tab (Index 4)
        bottom: _currentIndex == 0
            ? PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "SEARCH...",
                hintStyle: const TextStyle(color: AppColors.greyText, fontWeight: FontWeight.bold),
                prefixIcon: const Icon(Icons.search, color: AppColors.electricYellow),
                filled: true,
                fillColor: Colors.black,
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.electricYellow, width: 2), borderRadius: BorderRadius.circular(5)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.neonLime, width: 2), borderRadius: BorderRadius.circular(5)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        )
            : null,
      ),
      // FIXED BODY: Checks if we are on the Events Tab (4) or a List Tab (0,1,2,3,5)
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.neonLime)))
          : (_currentIndex == 4)
          ? EventsScreen(allPosts: _posts)
          : Column(
        children: [
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: (_searchQuery.isNotEmpty || _selectedCategories.length < 5)
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildActiveFilters(),
            secondChild: const SizedBox.shrink(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPosts,
              color: AppColors.neonLime,
              child: displayedPosts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 80, top: 10),
                itemCount: displayedPosts.length,
                itemBuilder: (context, index) => PostCard(
                  post: displayedPosts[index],
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PostDetailScreen(post: displayedPosts[index]))
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _filterPostsByCategory, // This handles the actual category filtering logic
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildTabContent() {
    // If user is on the Events Tab (Index 4)
    if (_currentIndex == 4) {
      return EventsScreen(allPosts: _posts);
    }

    // For all other tabs, we filter the list based on the selected tab
    String activeCat = _getCategoryForIndex(_currentIndex);

    List<Post> tabPosts = _posts.where((post) {
      bool matchesCategory = (activeCat == "All") || (post.category == activeCat);
      bool matchesSearch = post.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      children: [
        if (_currentIndex == 0) _buildActiveFilters(), // Only show filter chips on Home
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshPosts,
            color: AppColors.neonLime,
            child: tabPosts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 10),
              itemCount: tabPosts.length,
              itemBuilder: (context, index) => PostCard(
                post: tabPosts[index],
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PostDetailScreen(post: tabPosts[index]))
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView( // Needs to be a ListView/Scrollable for RefreshIndicator to work
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(Icons.search_off, color: AppColors.greyText, size: 60),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'NO MATCHES FOUND',
            style: TextStyle(
                color: AppColors.greyText,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2
            ),
          ),
        ),
      ],
    );
  }
// THE UPDATED CHIPS WIDGET
  Widget _buildActiveFilters() {
    return Container(
      height: 50,
      color: Colors.black.withOpacity(0.3),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // CLEAR ALL BUTTON
          TextButton(
            onPressed: () => setState(() {
              _searchQuery = "";
              _selectedCategories = ['Carpooling', 'Marketplace', 'Jobs', 'Events', 'Newsletters'];
            }),
            child: const Text("Clear all", style: TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          // ACTIVE CHIPS
          ..._selectedCategories.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InputChip(
              label: Text(cat.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
              backgroundColor: Colors.black,
              shape: const RoundedRectangleBorder(side: BorderSide(color: Colors.white24)),
              deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
              onDeleted: () => setState(() => _selectedCategories.remove(cat)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // The Black "Shadow" Box
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.black, width: 3),
          ),
          margin: const EdgeInsets.only(left: 4, top: 4),
        ),
        // The Actual Button
        FloatingActionButton(
          onPressed: _navigateToCreatePost,
          backgroundColor: AppColors.neonLime,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5), // Sharp Brutalist corners
            side: BorderSide(color: Colors.black, width: 3),
          ),
          child: const Icon(Icons.add, color: Colors.black, size: 28),
        )
      ],
    );
  }

  Widget _buildNotificationButton() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: firebase_auth.FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        bool hasUnreadStuff = false;
        if (snapshot.hasData) {
          hasUnreadStuff = snapshot.data!.docs.any((doc) {
            final data = doc.data() as Map<String, dynamic>;
            List unreadList = data['unreadBy'] ?? [];
            return unreadList.contains(firebase_auth.FirebaseAuth.instance.currentUser?.uid);
          });
        }
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: AppColors.neonLime),
              onPressed: () async {
                final myUid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
                if (myUid != null) {
                  var unreadChats = await FirebaseFirestore.instance
                      .collection('chats')
                      .where('unreadBy', arrayContains: myUid)
                      .get();

                  for (var doc in unreadChats.docs) {
                    doc.reference.update({
                      'unreadBy': FieldValue.arrayRemove([myUid])
                    });
                  }
                }
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                }
              },
            ),
            if (hasUnreadStuff)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _fetchPostsByCategory(String category) async {
    try {
      setState(() => _isLoading = true);

      Query query = FirebaseFirestore.instance.collection('Posts');

      if (category != "All") {
        query = query.where('category', isEqualTo: category);
      }

      // This specific combination (where + orderBy) is what needs the index
      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();

      if (!mounted) return;

      setState(() {
        currentCategory = category;
        _posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Firestore Error: $e");
      setState(() => _isLoading = false);
      // Show a snackbar so you know it failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading posts. Checking indexes...")),
      );
    }
  }
}
