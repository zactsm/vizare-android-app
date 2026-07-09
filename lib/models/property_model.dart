class Property {
  final int id;
  final int homeownerId;
  final String name;
  final String location;
  final String price;
  final String description;
  final String imagePath;
  final String modelPath;
  final bool isFeatured;
  final String createdAt;
  final String status;

  Property({
    required this.id,
    required this.homeownerId,
    required this.name,
    required this.location,
    required this.price,
    required this.description,
    required this.imagePath,
    required this.modelPath,
    required this.isFeatured,
    required this.createdAt,
    required this.status,
  });

  // Factory constructor: Creates a Property instance from a JSON map
  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: int.tryParse(json['id'].toString()) ?? 0,
      homeownerId: int.tryParse(json['homeowner_id'].toString()) ?? 0,
      name: json['name'],
      location: json['location'],
      price: json['price'],
      description: json['description'],
      imagePath: json['image_path'],
      modelPath: json['model_path'] ?? '',
      // Convert 0 or 1 from database to true/false
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      createdAt: json['created_at'],
      status: json['status'] ?? 'pending',
    );
  }
}
