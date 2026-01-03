import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'create_post_screen.dart';

class CategorySelectionScreen extends StatelessWidget {
  const CategorySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Create New Post',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a category for your post:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: AppConstants.categories.length,
                itemBuilder: (context, index) {
                  final category = AppConstants.categories[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        _getCategoryIcon(category),
                        color: AppColors.primary,
                        size: 28,
                      ),
                      title: Text(
                        category,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        _getCategoryDescription(category),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreatePostScreen(
                              selectedCategory: category,
                            ),
                          ),
                        );
                      },
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Carpooling':
        return Icons.directions_car;
      case 'Marketplace':
        return Icons.shopping_cart;
      case 'Jobs':
        return Icons.work;
      case 'Events':
        return Icons.event;
      case 'Newsletters':
        return Icons.article;
      default:
        return Icons.category;
    }
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case 'Carpooling':
        return 'Share your ride details and find carpool partners';
      case 'Marketplace':
        return 'Buy and sell items with images and descriptions';
      case 'Jobs':
        return 'Post job opportunities with links';
      case 'Events':
        return 'Share event details with images and links';
      case 'Newsletters':
        return 'Create detailed newsletters';
      default:
        return 'Create a new post';
    }
  }
}