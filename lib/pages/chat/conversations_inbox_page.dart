import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:untitled/models/chat_models.dart';
import 'package:untitled/pages/chat/chat_page.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/chat_service.dart';
import 'package:untitled/pages/utils/abstract_background.dart';

class ConversationsInboxPage extends StatefulWidget {
  const ConversationsInboxPage({super.key});

  @override
  State<ConversationsInboxPage> createState() => _ConversationsInboxPageState();
}

class _ConversationsInboxPageState extends State<ConversationsInboxPage> {
  final _searchController = TextEditingController();
  List<Conversation> _conversations = [];
  List<Conversation> _filteredConversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchConversations() async {
    setState(() => _isLoading = true);
    final convs = await ChatService.getConversations();
    if (mounted) {
      setState(() {
        _conversations = convs;
        _filterConversations();
        _isLoading = false;
      });
    }
  }

  void _filterConversations() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filteredConversations = List.from(_conversations);
    } else {
      _filteredConversations = _conversations.where((c) {
        final propMatch = c.property?.name.toLowerCase().contains(query) ?? false;
        final userMatch = c.otherUser.fullName.toLowerCase().contains(query);
        final msgMatch = c.lastMessage.toLowerCase().contains(query);
        return propMatch || userMatch || msgMatch;
      }).toList();
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? VizareColors.obsidianBlack : VizareColors.alabasterWhite,
      body: AbstractBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: VisionGlassCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  iconColor: isDark ? Colors.white : const Color(0xFF0F172A),
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
            title: Text(
              'Messages',
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: VisionGlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    borderRadius: 28.0,
                    backgroundColor: isDark
                        ? VizareColors.obsidianSurface.withValues(alpha: 0.88)
                        : Colors.white.withValues(alpha: 0.95),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(_filterConversations),
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                        fontSize: 14.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search conversations & properties...',
                        hintStyle: GoogleFonts.inter(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : const Color(0xFF94A3B8),
                          fontSize: 13.5,
                        ),
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14.0, horizontal: 8.0),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: VizareColors.champagneGold,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(_filterConversations);
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // Content List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: VizareColors.champagneGold,
                          ),
                        )
                      : RefreshIndicator(
                          color: VizareColors.champagneGold,
                          backgroundColor: isDark
                              ? VizareColors.obsidianSurface
                              : Colors.white,
                          onRefresh: _fetchConversations,
                          child: _filteredConversations.isEmpty
                              ? _buildEmptyInbox(isDark)
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  itemCount: _filteredConversations.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final conv = _filteredConversations[index];
                                    return _buildConversationCard(conv, isDark);
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationCard(Conversation conv, bool isDark) {
    final prop = conv.property;
    final timeStr = _formatRelativeTime(conv.lastMessageAt);
    final hasUnread = conv.unreadCount > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(conversation: conv),
          ),
        ).then((_) => _fetchConversations());
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? (hasUnread
                  ? VizareColors.obsidianSurface.withValues(alpha: 0.95)
                  : VizareColors.obsidianSurface.withValues(alpha: 0.8))
              : (hasUnread
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.95)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasUnread
                ? VizareColors.champagneGold.withValues(alpha: 0.7)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFE2E8F0)),
            width: hasUnread ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: hasUnread
                  ? VizareColors.champagneGold.withValues(alpha: 0.15)
                  : (isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.05)),
              blurRadius: hasUnread ? 16 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: prop != null
                      ? Image.network(
                          prop.imagePath,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 58,
                            height: 58,
                            color: Colors.white10,
                            child: const Icon(Icons.apartment_rounded, color: Colors.white38),
                          ),
                        )
                      : Container(
                          width: 58,
                          height: 58,
                          color: Colors.white10,
                          child: const Icon(Icons.apartment_rounded, color: Colors.white38),
                        ),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? VizareColors.obsidianBlack : Colors.white,
                      border: Border.all(
                        color: VizareColors.champagneGold,
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: VizareColors.champagneGold,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv.otherUser.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                          color: hasUnread
                              ? VizareColors.champagneGold
                              : (isDark
                                  ? VizareColors.textSecondary
                                  : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  if (prop != null)
                    Text(
                      prop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: VizareColors.champagneGold,
                      ),
                    ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage.isEmpty ? 'No messages yet' : conv.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                            color: hasUnread
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark
                                    ? VizareColors.textSecondary
                                    : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: VizareColors.champagneGold,
                          ),
                          child: Text(
                            conv.unreadCount.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInbox(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VizareColors.champagneGold.withValues(alpha: 0.1),
                border: Border.all(
                  color: VizareColors.champagneGold.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.mark_chat_unread_rounded,
                color: VizareColors.champagneGold,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Conversations Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Inquiries from homebuyers or estate agents will appear here with live updates and appointment schedules.',
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
}
