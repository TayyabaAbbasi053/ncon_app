class Place {
  final String id;
  final String name;
  final String description;
  final String imageUrl;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  factory Place.fromMap(Map<String, dynamic> data, String id) {
    return Place(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}
