import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/localization/language_provider.dart';
import '../../core/utils/feedback_helper.dart';
import 'offline_assistant_engine.dart';

class ChatMessage {
  final bool isUser;
  final String text;
  final AssistantResponse? response;
  final DateTime timestamp;

  ChatMessage({
    required this.isUser,
    required this.text,
    this.response,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AssistantDrawer extends ConsumerStatefulWidget {
  const AssistantDrawer({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AssistantDrawer(),
    );
  }

  @override
  ConsumerState<AssistantDrawer> createState() => _AssistantDrawerState();
}

class _AssistantDrawerState extends ConsumerState<AssistantDrawer> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _quickChips = [
    '👥 Sino may utang?',
    '📦 Kulang na stock',
    '💰 Benta ngayon',
    '📱 Tubo sa GCash',
    '🚚 Utang sa bodega',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        isUser: false,
        text: 'Kumusta! Ako si TindaBot, ang iyong offline store assistant. Pindutin ang isa sa mga tanong sa ibaba o mag-type ng nais mong malaman.',
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(isUser: true, text: clean));
      _isLoading = true;
    });
    _scrollToBottom();

    final db = ref.read(databaseProvider);
    final engine = OfflineAssistantEngine(db: db);
    final response = await engine.ask(clean);

    await FeedbackHelper.triggerSuccessFeedback();

    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            isUser: false,
            text: response.answer,
            response: response,
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(stringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: isLight ? AppColors.softShadowLight : AppColors.softShadowDark,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle Bar & Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withAlpha(25),
                    radius: 18,
                    child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'TindaBot AI',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '100% OFFLINE',
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.green.shade700),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          tr.isTaglish ? 'Walang internet kailangan • 0ms Latency' : 'No internet needed • 0ms Latency',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Quick Suggestion Chips
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _quickChips.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final chip = _quickChips[index];
                  return ActionChip(
                    label: Text(
                      chip,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: isLight ? Colors.grey.shade100 : Colors.grey.shade900,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: () => _handleSend(chip.replaceAll(RegExp(r'^[^\s]+\s+'), '')),
                  );
                },
              ),
            ),

            // Messages View
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(context, msg, isLight, borderColor);
                },
              ),
            ),

            // Typing Indicator
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      tr.isTaglish ? 'Kinakalkula ang sagot mula sa local database...' : 'Calculating answer from local database...',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

            // Text Input Field Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : AppColors.surfaceDark,
                border: Border(top: BorderSide(color: borderColor, width: 1.0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _handleSend,
                      decoration: InputDecoration(
                        hintText: tr.isTaglish ? 'Magtanong sa Taglish o Ingles...' : 'Ask in Taglish or English...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _handleSend(_textController.text),
                    icon: const Icon(Icons.send_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg, bool isLight, Color borderColor) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.text,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final resp = msg.response;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 30),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLight ? Colors.grey.shade100 : Colors.grey.shade900,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resp != null) ...[
              Text(
                resp.title,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              msg.text,
              style: GoogleFonts.inter(fontSize: 13),
            ),
            if (resp != null && resp.bulletPoints.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...resp.bulletPoints.map((b) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          b,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
