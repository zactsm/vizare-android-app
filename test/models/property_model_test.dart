import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/models/property_model.dart';

void main() {
  group('Property Model Tests', () {
    test('parses complete valid json correctly with float price and formats RM', () {
      final json = {
        'id': 42,
        'homeowner_id': 101,
        'name': 'Luxury Modern Villa',
        'location': 'Beverly Hills, CA',
        'price': 3500000.0,
        'description': 'Stunning 4 bedroom villa with pool and AR tour.',
        'image_path': 'https://example.com/villa.jpg',
        'model_path': 'https://example.com/villa.glb',
        'is_featured': 1,
        'created_at': '2026-08-25T12:00:00Z',
        'status': 'approved',
      };

      final property = Property.fromJson(json);

      expect(property.id, 42);
      expect(property.homeownerId, 101);
      expect(property.name, 'Luxury Modern Villa');
      expect(property.location, 'Beverly Hills, CA');
      expect(property.price, 'RM 3,500,000');
      expect(property.numericPrice, 3500000.0);
      expect(property.description,
          'Stunning 4 bedroom villa with pool and AR tour.');
      expect(property.imagePath, 'https://example.com/villa.jpg');
      expect(property.modelPath, 'https://example.com/villa.glb');
      expect(property.isFeatured, isTrue);
      expect(property.createdAt, '2026-08-25T12:00:00Z');
      expect(property.status, 'approved');
    });

    test('handles legacy string-based and numeric prices gracefully', () {
      final json = {
        'id': '99',
        'homeowner_id': '888',
        'name': 'Skyline Penthouse',
        'location': 'New York, NY',
        'price': '\$5,000,000',
        'description': 'Panoramic views of Central Park.',
        'image_path': 'https://example.com/penthouse.jpg',
        'model_path': null,
        'is_featured': false,
        'created_at': '2026-08-20T10:00:00Z',
        'status': 'pending',
      };

      final property = Property.fromJson(json);

      expect(property.id, 99);
      expect(property.homeownerId, 888);
      expect(property.price, 'RM 5,000,000');
      expect(property.numericPrice, 5000000.0);
      expect(property.modelPath, '');
      expect(property.isFeatured, isFalse);
      expect(property.status, 'pending');
    });

    test('handles boolean and integer variations of is_featured', () {
      final jsonIntTrue = {
        'id': 1,
        'homeowner_id': 1,
        'name': 'A',
        'location': 'B',
        'price': 100000,
        'description': 'C',
        'image_path': 'D',
        'is_featured': 1,
        'created_at': '2026-01-01',
      };
      expect(Property.fromJson(jsonIntTrue).isFeatured, isTrue);
      expect(Property.fromJson(jsonIntTrue).price, 'RM 100,000');

      final jsonBoolTrue = {
        ...jsonIntTrue,
        'is_featured': true,
      };
      expect(Property.fromJson(jsonBoolTrue).isFeatured, isTrue);

      final jsonIntFalse = {
        ...jsonIntTrue,
        'is_featured': 0,
      };
      expect(Property.fromJson(jsonIntFalse).isFeatured, isFalse);

      final jsonBoolFalse = {
        ...jsonIntTrue,
        'is_featured': false,
      };
      expect(Property.fromJson(jsonBoolFalse).isFeatured, isFalse);

      final jsonNullFeatured = {
        ...jsonIntTrue,
        'is_featured': null,
      };
      expect(Property.fromJson(jsonNullFeatured).isFeatured, isFalse);
    });

    test('falls back to default values for missing optional fields', () {
      final json = {
        'id': 'invalid_id',
        'homeowner_id': null,
        'name': 'Cozy Cottage',
        'location': 'Aspen, CO',
        'price': '750000',
        'description': 'Rustic wooden cottage in the mountains.',
        'image_path': 'https://example.com/cottage.jpg',
        'created_at': '2026-05-15',
      };

      final property = Property.fromJson(json);

      expect(property.id, 0);
      expect(property.homeownerId, 0);
      expect(property.price, 'RM 750,000');
      expect(property.numericPrice, 750000.0);
      expect(property.modelPath, '');
      expect(property.status, 'pending');
      expect(property.isFeatured, isFalse);
    });
  });
}
