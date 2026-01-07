import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/post_card.dart';
import '../services/firestore_service.dart';
import '../models/post.dart';
import 'login_screen.dart';
import 'account_screen.dart';
import 'category_selection_screen.dart';
import 'post_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();
  List<Post> _posts = [];
  List<Post> _filteredPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    setState(() => _isLoading = true);

    _firestoreService.getPosts().listen((posts) {
      if (!mounted) return;

      for (var post in posts) {
        debugPrint('📄 Post: ${post.title}');
        debugPrint('🖼️ Images: ${post.images}');
        if (post.eventDate != null) {
          debugPrint('📅 Event Date: ${post.eventDate}');
        }
      }

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
        _filteredPosts =
            _posts.where((post) => post.category == category).toList();
      }
    });
  }

  String _getCategoryForIndex(int index) {
    switch (index) {
      case 1:
        return 'Carpooling';
      case 2:
        return 'Marketplace';
      case 3:
        return 'Jobs';
      case 4:
        return 'Events';
      case 5:
        return 'Newsletters';
      default:
        return 'All';
    }
  }

  void _navigateToAccount() {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountScreen()),
    );
  }

  void _navigateToCreatePost() {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CategorySelectionScreen(),
      ),
    );
  }

  void _navigateToPostDetail(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: post),
      ),
    );
  }

  Future<void> _refreshPosts() async {
    _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'NCON',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPosts,
            tooltip: 'Refresh posts',
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: _navigateToAccount,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshPosts,
              child: _filteredPosts.isEmpty
                  ? const Center(
                      child: Text(
                        'No posts found.',
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = _filteredPosts[index];
                        return PostCard(
                          post: post,
                          onTap: () => _navigateToPostDetail(post),
                        );
                      },
                    ),
            ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _filterPostsByCategory,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
