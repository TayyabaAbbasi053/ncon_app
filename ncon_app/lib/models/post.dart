import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String postId;
  final String title;
  final String description;
  final double price;
  final String category;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final List<String> images;
  final List<String> links;
  final DateTime? eventDate;
  final DateTime? eventEndDate;
  final double? eventFee;
  final String location;

  Post({
    required this.postId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.images,
    required this.links,
    this.eventDate,
    this.eventEndDate,
    this.eventFee,
    this.location = "",
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Post(
      postId: doc.id, // Or data['postId']
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'All',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      // Handle price/eventFee safely (converts int to double if needed)
      price: (data['price'] ?? 0.0).toDouble(),
      eventFee: (data['eventFee'] ?? 0.0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(), links: [],
      // Add other fields as necessary...
    );
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    DateTime? parsedEventDate;
    
    // Parse event date if it exists
    if (map['eventDate'] != null) {
      if (map['eventDate'] is Timestamp) {
        parsedEventDate = (map['eventDate'] as Timestamp).toDate();
      } else if (map['eventDate'] is String) {
        parsedEventDate = DateTime.tryParse(map['eventDate']);
      }
    }

    // Parse createdAt
    DateTime parsedCreatedAt;
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedCreatedAt = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    // Ensure images is always a List<String>
    List<String> imageList = [];
    if (map['images'] != null) {
      if (map['images'] is List) {
        imageList = List<String>.from(map['images']!);
      }
    }

    return Post(
      postId: map['postId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: ((map['price'] != null && map['price'] != 0)
          ? map['price']
          : (map['eventFee'] ?? 0.0)).toDouble(),
      category: map['category'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      createdAt: parsedCreatedAt,
      images: imageList,
      links: List<String>.from(map['links'] ?? []),
      eventDate: map['eventDate'] != null ? (map['eventDate'] as Timestamp).toDate() : null,
      eventEndDate: map['eventEndDate'] != null ? (map['eventEndDate'] as Timestamp).toDate() : null,
      eventFee: map['eventFee']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'title': title,
      'description': description,
      'category': category,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt,
      'images': images,
      'links': links,
      'eventDate': eventDate,
      'eventEndDate': eventEndDate,
      'eventFee': eventFee,
    };
  }
}