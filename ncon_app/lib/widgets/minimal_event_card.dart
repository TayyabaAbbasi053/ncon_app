import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';
import '../utils/colors.dart'; // Assuming you have your AppColors here

class MinimalEventCard extends StatelessWidget {
  final Post event;
  final VoidCallback onTap;

  const MinimalEventCard({super.key, required this.event, required this.onTap});

  // Helper to get color based on category (matching your previous setup)
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Events': return AppColors.neonLime;
      case 'Jobs': return AppColors.electricBlue;
      case 'Marketplace': return AppColors.accentGreen;
    // Using punchy pink for urgency/other
      default: return AppColors.neonPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(event.category);
    final date = event.eventDate ?? DateTime.now();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        // Neobrutalist Decoration: Thick border, hard shadow feel
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4), // Hard shadow
              blurRadius: 0,
            )
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Color Stripe
              Container(
                width: 12,
                color: categoryColor,
              ),
              // Event Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time and Category Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('jm').format(date), // e.g., 5:30 PM
                            style: const TextStyle(
                              color: AppColors.neonLime,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: categoryColor),
                            ),
                            child: Text(
                              event.category.toUpperCase(),
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Location (if available)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: AppColors.greyText),
                          const SizedBox(width: 4),
                          Text(
                            event.location.isNotEmpty ? event.location : "No Location",
                            style: const TextStyle(color: AppColors.greyText, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}