import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'create_post_screen.dart';

class CategorySelectionScreen extends StatelessWidget {
  const CategorySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.neonLime, width: 2)),
        title: const Text(
          'Create New Post',
          style: TextStyle(color: AppColors.neonLime, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: AppColors.neonLime),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a category:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.electricYellow,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: AppConstants.categories.length,
                itemBuilder: (context, index) {
                  final category = AppConstants.categories[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatePostScreen(selectedCategory: category),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: _getCategoryColor(category), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            offset: const Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Icon(
                              _getCategoryIcon(category),
                              color: Colors.black,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getCategoryDescription(category),
                                  style: const TextStyle(fontSize: 12, color: AppColors.greyText),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.electricYellow),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Carpooling': return AppColors.punchyCoral;
      case 'Marketplace': return AppColors.electricYellow;
      case 'Jobs': return AppColors.neonLime;
      case 'Events': return AppColors.electricBlue;
      case 'Newsletters': return AppColors.neonPurple;
      default: return AppColors.electricYellow;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Carpooling': return Icons.directions_car;
      case 'Marketplace': return Icons.shopping_cart;
      case 'Jobs': return Icons.work;
      case 'Events': return Icons.event;
      case 'Newsletters': return Icons.article;
      default: return Icons.category;
    }
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case 'Carpooling': return 'Share your ride details';
      case 'Marketplace': return 'Buy and sell items';
      case 'Jobs': return 'Post job opportunities';
      case 'Events': return 'Share event details';
      case 'Newsletters': return 'Create newsletters';
      default: return 'Create a new post';
    }
  }
}
