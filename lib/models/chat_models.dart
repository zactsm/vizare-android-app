import 'package:untitled/models/property_model.dart';
import '../pages/utils/api_service.dart';

class ConversationParticipant {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? profilePic;

  const ConversationParticipant({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.profilePic,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    final rawPic = json['profile_pic']?.toString();
    final sanitizedPic = rawPic != null && rawPic.isNotEmpty
        ? ApiService.sanitizeImageUrl(rawPic)
        : null;

    return ConversationParticipant(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'homeowner',
      profilePic: sanitizedPic,
    );
  }
}

class Conversation {
  final int id;
  final int propertyId;
  final int buyerId;
  final int homeownerId;
  final String lastMessage;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final Property? property;
  final ConversationParticipant otherUser;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.propertyId,
    required this.buyerId,
    required this.homeownerId,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
    this.property,
    required this.otherUser,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    Property? prop;
    if (json['property'] != null && json['property'] is Map<String, dynamic>) {
      prop = Property.fromJson(json['property']);
    } else if (json['properties'] != null && json['properties'] is Map<String, dynamic>) {
      prop = Property.fromJson(json['properties']);
    }

    ConversationParticipant participant;
    if (json['other_user'] != null && json['other_user'] is Map<String, dynamic>) {
      participant = ConversationParticipant.fromJson(json['other_user']);
    } else {
      participant = const ConversationParticipant(
        id: 0,
        fullName: 'Estate Representative',
        email: '',
        role: 'homeowner',
      );
    }

    DateTime parsedLastMessageAt;
    try {
      parsedLastMessageAt = DateTime.parse(json['last_message_at']?.toString() ?? '');
    } catch (_) {
      parsedLastMessageAt = DateTime.now();
    }

    DateTime parsedCreatedAt;
    try {
      parsedCreatedAt = DateTime.parse(json['created_at']?.toString() ?? '');
    } catch (_) {
      parsedCreatedAt = DateTime.now();
    }

    return Conversation(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      propertyId: int.tryParse(json['property_id']?.toString() ?? '0') ?? 0,
      buyerId: int.tryParse(json['buyer_id']?.toString() ?? '0') ?? 0,
      homeownerId: int.tryParse(json['homeowner_id']?.toString() ?? '0') ?? 0,
      lastMessage: json['last_message']?.toString() ?? '',
      lastMessageAt: parsedLastMessageAt,
      createdAt: parsedCreatedAt,
      property: prop,
      otherUser: participant,
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String messageText;
  final String messageType; // 'text', 'viewing_request'
  final String? viewingDate;
  final String? viewingTime;
  final String? viewingMode; // 'in_person', 'virtual_ar'
  String? viewingStatus; // 'pending', 'confirmed', 'rescheduled', 'declined'
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageText,
    this.messageType = 'text',
    this.viewingDate,
    this.viewingTime,
    this.viewingMode,
    this.viewingStatus,
    this.isRead = false,
    required this.createdAt,
  });

  bool get isViewingRequest => messageType == 'viewing_request';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt;
    try {
      parsedCreatedAt = DateTime.parse(json['created_at']?.toString() ?? '');
    } catch (_) {
      parsedCreatedAt = DateTime.now();
    }

    return ChatMessage(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      conversationId: int.tryParse(json['conversation_id']?.toString() ?? '0') ?? 0,
      senderId: int.tryParse(json['sender_id']?.toString() ?? '0') ?? 0,
      messageText: json['message_text']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      viewingDate: json['viewing_date']?.toString(),
      viewingTime: json['viewing_time']?.toString(),
      viewingMode: json['viewing_mode']?.toString(),
      viewingStatus: json['viewing_status']?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read']?.toString() == 'true',
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message_text': messageText,
      'message_type': messageType,
      'viewing_date': viewingDate,
      'viewing_time': viewingTime,
      'viewing_mode': viewingMode,
      'viewing_status': viewingStatus,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
