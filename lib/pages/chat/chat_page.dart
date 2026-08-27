import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/models/chat_models.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/chat/schedule_viewing_dialog.dart';
import 'package:untitled/pages/property_details_page.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/chat_service.dart';
import 'package:untitled/pages/utils/abstract_background.dart';

class ChatPage extends StatefulWidget {
  final Conversation conversation;

  const ChatPage({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  int _currentUserId = 0;
  String _currentUserRole = '';
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadUserAndMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    ChatService.unsubscribeChannel(_realtimeChannel);
    super.dispose();
  }

  Future<void> _loadUserAndMessages() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserRole = (prefs.getString('user_type') ?? 'homebuyer').toLowerCase();

    // Determine current user profile id
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('id')
            .eq('auth_user_id', user.id)
            .maybeSingle();
        if (profileRes != null && profileRes['id'] != null) {
          _currentUserId = int.tryParse(profileRes['id'].toString()) ?? 0;
        }
      }
    } catch (_) {}

    if (_currentUserId == 0) {
      _currentUserId = _currentUserRole == 'homeowner'
          ? widget.conversation.homeownerId
          : widget.conversation.buyerId;
    }

    await _fetchMessages();
    _subscribeToRealtime();
  }

  Future<void> _fetchMessages() async {
    final msgs = await ChatService.getMessages(widget.conversation.id);
    if (mounted) {
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _subscribeToRealtime() {
    _realtimeChannel = ChatService.subscribeToConversation(
      widget.conversation.id,
      onNewMessage: (newMsg) {
        if (!mounted) return;
        final exists = _messages.any((m) => m.id == newMsg.id);
        if (!exists) {
          setState(() => _messages.add(newMsg));
          _scrollToBottom();
        }
      },
      onUpdatedMessage: (updatedMsg) {
        if (!mounted) return;
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == updatedMsg.id);
          if (idx != -1) {
            _messages[idx] = updatedMsg;
          }
        });
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage({
    String? customText,
    String messageType = 'text',
    String? viewingDate,
    String? viewingTime,
    String? viewingMode,
  }) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty && messageType == 'text') return;

    if (customText == null) {
      _messageController.clear();
    }

    setState(() => _isSending = true);

    final newMsg = await ChatService.sendMessage(
      conversationId: widget.conversation.id,
      messageText: text,
      messageType: messageType,
      viewingDate: viewingDate,
      viewingTime: viewingTime,
      viewingMode: viewingMode,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (newMsg != null) {
        final exists = _messages.any((m) => m.id == newMsg.id);
        if (!exists) {
          setState(() => _messages.add(newMsg));
          _scrollToBottom();
        }
      }
    }
  }

  Future<void> _handleUpdateViewingStatus(ChatMessage message, String status) async {
    final success = await ChatService.updateViewingStatus(
      messageId: message.id,
      status: status,
    );
    if (success && mounted) {
      setState(() {
        message.viewingStatus = status;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'confirmed'
                ? 'Viewing appointment confirmed!'
                : 'Status updated to $status',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: status == 'confirmed'
              ? VizareColors.emeraldGreen
              : VizareColors.obsidianSurface,
        ),
      );
    }
  }

  void _openScheduleViewing() {
    if (widget.conversation.property == null) return;
    ScheduleViewingDialog.show(
      context: context,
      property: widget.conversation.property!,
      onSchedule: (date, timeSlot, tourMode, note) {
        final formattedDate = DateFormat('EEE, MMM d, yyyy').format(date);
        final modeLabel = tourMode == 'virtual_ar'
            ? 'Virtual 3D AR Walkthrough'
            : 'In-Person On-Site Tour';
        final messageContent = note.isNotEmpty
            ? 'Viewing Request: $modeLabel on $formattedDate at $timeSlot.\nNote: "$note"'
            : 'Viewing Request: $modeLabel on $formattedDate at $timeSlot.';

        _handleSendMessage(
          customText: messageContent,
          messageType: 'viewing_request',
          viewingDate: formattedDate,
          viewingTime: timeSlot,
          viewingMode: tourMode,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prop = widget.conversation.property;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? VizareColors.obsidianBlack : VizareColors.alabasterWhite,
      body: AbstractBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(context, prop),
          body: SafeArea(
            child: Column(
              children: [
                // Property Mini Banner
                if (prop != null) _buildPropertyBanner(context, prop),

                // Messages Stream Area
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: VizareColors.champagneGold,
                          ),
                        )
                      : _messages.isEmpty
                          ? _buildEmptyState()
                          : _buildMessagesList(),
                ),

                // Quick Action Chips
                _buildQuickChips(),

                // Bottom Input Bar
                _buildInputBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Property? prop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: VisionGlassCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconColor: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 38,
            onTap: () => Navigator.pop(context),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? VizareColors.obsidianSurface : Colors.white,
              border: Border.all(
                color: VizareColors.champagneGold.withValues(alpha: 0.8),
                width: 1.2,
              ),
              image: widget.conversation.otherUser.profilePic != null
                  ? DecorationImage(
                      image: NetworkImage(widget.conversation.otherUser.profilePic!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.conversation.otherUser.profilePic == null
                ? const Icon(
                    Icons.person_rounded,
                    color: VizareColors.champagneGold,
                    size: 18,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.otherUser.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: VizareColors.emeraldGreen,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.conversation.otherUser.role.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: VizareColors.champagneGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (prop != null)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: _openScheduleViewing,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: VizareColors.champagneGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: VizareColors.champagneGold.withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: VizareColors.champagneGold,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Book Tour',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: VizareColors.champagneGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPropertyBanner(BuildContext context, Property prop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsPage(property: prop),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? VizareColors.obsidianSurface.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? VizareColors.champagneGold.withValues(alpha: 0.2)
                : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                prop.imagePath,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  width: 46,
                  height: 46,
                  color: Colors.white10,
                  child: const Icon(Icons.apartment_rounded, color: Colors.white38),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    prop.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark
                          ? VizareColors.textSecondary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              prop.price,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: VizareColors.champagneGold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: VizareColors.champagneGold,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VizareColors.champagneGold.withValues(alpha: 0.1),
                border: Border.all(
                  color: VizareColors.champagneGold.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: VizareColors.champagneGold,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start the Conversation',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Inquire about luxury amenities, schedule an on-site tour, or request 3D AR walk-throughs.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? VizareColors.textSecondary : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _currentUserId ||
            (message.senderId != widget.conversation.otherUser.id && message.senderId != 0);

        if (message.isViewingRequest) {
          return _buildViewingAppointmentCard(message, isMe);
        }

        return _buildTextBubble(message, isMe);
      },
    );
  }

  Widget _buildTextBubble(ChatMessage message, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('h:mm a').format(message.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [
                    Color(0xFFE5C058),
                    VizareColors.champagneGold,
                  ],
                )
              : null,
          color: isMe
              ? null
              : (isDark
                  ? VizareColors.obsidianSurface.withValues(alpha: 0.9)
                  : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.messageText,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.w400,
                color: isMe
                    ? Colors.black87
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: isMe
                        ? Colors.black.withValues(alpha: 0.6)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : const Color(0xFF94A3B8)),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 12,
                    color: Colors.black.withValues(alpha: 0.65),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewingAppointmentCard(ChatMessage message, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = message.viewingStatus ?? 'pending';
    final isConfirmed = status == 'confirmed';
    final isPending = status == 'pending';
    final isVirtual = message.viewingMode == 'virtual_ar';
    final isHomeowner = _currentUserRole == 'homeowner';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? VizareColors.obsidianSurface.withValues(alpha: 0.94)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isConfirmed
              ? VizareColors.emeraldGreen
              : (isDark
                  ? VizareColors.champagneGold.withValues(alpha: 0.5)
                  : const Color(0xFFCBD5E1)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isConfirmed ? VizareColors.emeraldGreen : VizareColors.champagneGold)
                .withValues(alpha: isDark ? 0.15 : 0.10),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isVirtual ? Icons.view_in_ar_rounded : Icons.location_city_rounded,
                    color: VizareColors.champagneGold,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isVirtual ? 'Virtual 3D AR Tour' : 'On-Site Viewing',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? VizareColors.emeraldGreen.withValues(alpha: 0.2)
                      : VizareColors.champagneGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isConfirmed
                        ? VizareColors.emeraldGreen
                        : VizareColors.champagneGold,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  isConfirmed ? 'CONFIRMED' : 'PENDING REVIEW',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isConfirmed
                        ? VizareColors.emeraldGreen
                        : VizareColors.champagneGold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          Divider(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            height: 16,
          ),

          // Date & Time Details
          Row(
            children: [
              const Icon(
                Icons.event_rounded,
                color: VizareColors.champagneGold,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                message.viewingDate ?? 'Date specified',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.access_time_rounded,
                color: VizareColors.champagneGold,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                message.viewingTime ?? 'Time specified',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          if (message.messageText.contains('Note:')) ...[
            const SizedBox(height: 8),
            Text(
              message.messageText.split('Note:').last.replaceAll('"', '').trim(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark ? VizareColors.textSecondary : const Color(0xFF64748B),
              ),
            ),
          ],

          // Homeowner Action Buttons (if pending and user is homeowner)
          if (isPending && isHomeowner) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleUpdateViewingStatus(message, 'confirmed'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: VizareColors.emeraldGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Confirm Booking',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleUpdateViewingStatus(message, 'rescheduled'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Reschedule',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chips = [
      '📅 Schedule Viewing',
      '💰 Price Breakdown',
      '📍 Location Details',
      '📐 Floor Plan & Specs',
    ];

    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return GestureDetector(
            onTap: () {
              if (chip.startsWith('📅')) {
                _openScheduleViewing();
              } else {
                _handleSendMessage(
                  customText: chip.replaceFirst(RegExp(r'^[^\s]+\s'), ''),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? VizareColors.obsidianSurface.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? VizareColors.champagneGold.withValues(alpha: 0.3)
                      : const Color(0xFFCBD5E1),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  chip,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: VizareColors.champagneGold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? VizareColors.obsidianSurface.withValues(alpha: 0.9)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? VizareColors.champagneGold.withValues(alpha: 0.3)
                      : const Color(0xFFCBD5E1),
                  width: 1.0,
                ),
              ),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendMessage(),
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 13.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: GoogleFonts.inter(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : const Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSending ? null : () => _handleSendMessage(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFDF7A),
                    VizareColors.champagneGold,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: VizareColors.champagneGold.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
