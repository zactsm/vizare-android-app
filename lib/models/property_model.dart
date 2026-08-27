import 'package:intl/intl.dart';

class PropertyTypeItem {
  final int id;
  final String name;
  final String icon;

  PropertyTypeItem({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory PropertyTypeItem.fromJson(Map<String, dynamic> json) {
    return PropertyTypeItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'home_work_rounded',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }
}

class Property {
  final int id;
  final int homeownerId;
  final String name;
  final String location;
  final String propertyType;
  final String price;
  final double numericPrice;
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
    this.propertyType = 'Modern Luxury',
    required this.price,
    this.numericPrice = 0.0,
    required this.description,
    required this.imagePath,
    required this.modelPath,
    required this.isFeatured,
    required this.createdAt,
    required this.status,
  });

  static String formatPrice(dynamic rawValue) {
    if (rawValue == null) return 'Price on request';
    if (rawValue is num) {
      final formatter = NumberFormat('#,##0.##');
      return 'RM ${formatter.format(rawValue)}';
    }
    final str = rawValue.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'price on request') {
      return 'Price on request';
    }
    // Clean string from $, RM, spaces, commas
    final cleaned = str.replaceAll(RegExp(r'[^0-9.]'), '');
    final parsed = double.tryParse(cleaned);
    if (parsed != null) {
      final formatter = NumberFormat('#,##0.##');
      return 'RM ${formatter.format(parsed)}';
    }
    return str.startsWith('RM ') ? str : 'RM $str';
  }

  static double parseNumericPrice(dynamic rawValue) {
    if (rawValue == null) return 0.0;
    if (rawValue is num) return rawValue.toDouble();
    final str = rawValue.toString().trim();
    final cleaned = str.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  // Factory constructor: Creates a Property instance from a JSON map
  factory Property.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final rawType = json['property_type']?.toString().trim();
    final propType = (rawType != null && rawType.isNotEmpty) ? rawType : 'Modern Luxury';

    return Property(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      homeownerId: int.tryParse(json['homeowner_id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'Unnamed Estate',
      location: json['location']?.toString() ?? 'Location unavailable',
      propertyType: propType,
      price: formatPrice(rawPrice),
      numericPrice: parseNumericPrice(rawPrice),
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
