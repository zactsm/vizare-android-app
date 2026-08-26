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
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      homeownerId: int.tryParse(json['homeowner_id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'Unnamed Estate',
      location: json['location']?.toString() ?? 'Location unavailable',
      price: json['price']?.toString() ?? 'Price on request',
      description: json['description']?.toString() ?? '',
      imagePath: json['image_path']?.toString() ?? '',
      modelPath: json['model_path']?.toString() ?? '',
      isFeatured: json['is_featured'] == 1 ||
          json['is_featured'] == true ||
          json['is_featured']?.toString().toLowerCase() == 'true' ||
          json['is_featured']?.toString() == '1',
      createdAt: json['created_at']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
    );
  }
}
