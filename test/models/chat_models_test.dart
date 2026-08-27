import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/models/chat_models.dart';

void main() {
  group('Chat & Appointment Model Tests', () {
    test('parses Conversation json correctly', () {
      final json = {
        'id': 10,
        'property_id': 101,
        'buyer_id': 55,
        'homeowner_id': 77,
        'last_message': 'Is this available for a weekend tour?',
        'last_message_at': '2026-08-27T10:00:00Z',
        'created_at': '2026-08-27T08:00:00Z',
        'unread_count': 2,
        'other_user': {
          'id': 77,
          'full_name': 'Victoria Sterling',
          'email': 'victoria@luxuryestates.com',
          'role': 'homeowner',
          'profile_pic': 'https://example.com/victoria.jpg',
        },
        'property': {
          'id': 101,
          'name': 'The Obsidian Villa',
          'location': 'Damansara Heights, KL',
          'price': 4850000.0,
          'image_path': 'https://example.com/obsidian.jpg',
          'model_path': 'https://example.com/obsidian.glb',
        },
      };

      final conv = Conversation.fromJson(json);

      expect(conv.id, 10);
      expect(conv.propertyId, 101);
      expect(conv.buyerId, 55);
      expect(conv.homeownerId, 77);
      expect(conv.lastMessage, 'Is this available for a weekend tour?');
      expect(conv.unreadCount, 2);
      expect(conv.otherUser.fullName, 'Victoria Sterling');
      expect(conv.otherUser.role, 'homeowner');
      expect(conv.property, isNotNull);
      expect(conv.property?.name, 'The Obsidian Villa');
      expect(conv.property?.price, 'RM 4,850,000');
    });

    test('parses ChatMessage text and viewing request correctly', () {
      final textJson = {
        'id': 1,
        'conversation_id': 10,
        'sender_id': 55,
        'message_text': 'Hello, I would love to ask about the maintenance fees.',
        'message_type': 'text',
        'is_read': true,
        'created_at': '2026-08-27T10:05:00Z',
      };

      final textMsg = ChatMessage.fromJson(textJson);
      expect(textMsg.id, 1);
      expect(textMsg.isViewingRequest, isFalse);
      expect(textMsg.isRead, isTrue);

      final viewingJson = {
        'id': 2,
        'conversation_id': 10,
        'sender_id': 55,
        'message_text': 'Requested viewing on Sat, Aug 29, 2026 (2:00 PM)',
        'message_type': 'viewing_request',
        'viewing_date': 'Sat, Aug 29, 2026',
        'viewing_time': '2:00 PM',
        'viewing_mode': 'virtual_ar',
        'viewing_status': 'pending',
        'is_read': false,
        'created_at': '2026-08-27T10:10:00Z',
      };

      final viewingMsg = ChatMessage.fromJson(viewingJson);
      expect(viewingMsg.id, 2);
      expect(viewingMsg.isViewingRequest, isTrue);
      expect(viewingMsg.viewingMode, 'virtual_ar');
      expect(viewingMsg.viewingStatus, 'pending');
      expect(viewingMsg.isRead, isFalse);
    });
  });
}
