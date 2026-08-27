import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/models/chat_models.dart';
import 'package:untitled/pages/utils/api_service.dart';

class ChatService {
  static final _logger = Logger();

  static Future<Conversation?> getOrCreateConversation(int propertyId) async {
    try {
      final response = await ApiService.post(
        'get_or_create_conversation.php',
        body: {'property_id': propertyId.toString()},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Conversation.fromJson(data);
      } else {
        _logger.e("Failed to get/create conversation: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      _logger.e("Error getting or creating conversation", error: e);
      return null;
    }
  }

  static Future<List<Conversation>> getConversations() async {
    try {
      final response = await ApiService.get('get_conversations.php', {});
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => Conversation.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      _logger.e("Error fetching conversations", error: e);
      return [];
    }
  }

  static Future<List<ChatMessage>> getMessages(int conversationId) async {
    try {
      final response = await ApiService.get(
        'get_messages.php',
        {'conversation_id': conversationId.toString()},
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => ChatMessage.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      _logger.e("Error fetching messages", error: e);
      return [];
    }
  }

  static Future<ChatMessage?> sendMessage({
    required int conversationId,
    required String messageText,
    String messageType = 'text',
    String? viewingDate,
    String? viewingTime,
    String? viewingMode,
  }) async {
    try {
      final body = {
        'conversation_id': conversationId.toString(),
        'message_text': messageText,
        'message_type': messageType,
      };
      if (viewingDate != null) body['viewing_date'] = viewingDate;
      if (viewingTime != null) body['viewing_time'] = viewingTime;
      if (viewingMode != null) body['viewing_mode'] = viewingMode;

      final response = await ApiService.post('send_message.php', body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatMessage.fromJson(data);
      }
      return null;
    } catch (e) {
      _logger.e("Error sending message", error: e);
      return null;
    }
  }

  static Future<bool> updateViewingStatus({
    required int messageId,
    required String status,
  }) async {
    try {
      final response = await ApiService.post(
        'update_viewing_status.php',
        body: {
          'message_id': messageId.toString(),
          'status': status,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      _logger.e("Error updating viewing status", error: e);
      return false;
    }
  }

  /// Subscribe to Realtime messages for a specific conversation using Supabase Realtime
  static RealtimeChannel? subscribeToConversation(
    int conversationId, {
    required void Function(ChatMessage message) onNewMessage,
    required void Function(ChatMessage updatedMessage) onUpdatedMessage,
  }) {
    try {
      final supabase = Supabase.instance.client;
      final channel = supabase
          .channel('public:messages:$conversationId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord.isNotEmpty) {
                onNewMessage(ChatMessage.fromJson(newRecord));
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord.isNotEmpty) {
                onUpdatedMessage(ChatMessage.fromJson(newRecord));
              }
            },
          );

      channel.subscribe();
      return channel;
    } catch (e) {
      _logger.e("Supabase Realtime subscription error: $e");
      return null;
    }
  }

  static void unsubscribeChannel(RealtimeChannel? channel) {
    if (channel != null) {
      try {
        Supabase.instance.client.removeChannel(channel);
      } catch (_) {}
    }
  }
}
