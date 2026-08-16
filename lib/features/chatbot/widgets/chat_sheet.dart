import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accessibility_config.dart';
import '../../../shared_states.dart';
import '../../../shared_widgets.dart';
import '../providers/chatbot_provider.dart';
import '../models/chat_message.dart';

class ChatSheet extends ConsumerStatefulWidget {
  const ChatSheet({super.key});

  @override
  ConsumerState<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends ConsumerState<ChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isFullScreen = false;

  final List<String> _suggestedPrompts = [
    "How do I scan a medicine?",
    "How do I add a schedule?",
    "How does caregiver mode work?",
    "How do I manage dependents?",
    "How do I search medicines?",
    "How does cabinet tracking work?",
  ];

  final List<String> _mockTranscripts = [
    "How do I add a new medicine schedule?",
    "Can you explain how caregiver mode works?",
    "Where do I scan my medicine barcode?",
    "How do I track my daily taken doses?",
    "How do I view my dependent profiles?",
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _submitMessage([String? presetText]) async {
    final text = presetText ?? _controller.text.trim();
    if (text.isEmpty) return;

    if (presetText == null) {
      _controller.clear();
    }

    _scrollToBottom();
    await ref.read(chatHistoryProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  String _getRandomMockTranscript() {
    final random = Random();
    return _mockTranscripts[random.nextInt(_mockTranscripts.length)];
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatHistoryProvider);
    final isLoading = ref.watch(chatLoadingProvider);
    final activeScreen = ref.watch(currentScreenProvider);
    
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);

    // Dynamic color values matching existing MedSafe theme
    const Color primaryColor = Color(0xFF2563EB); // MedSafe Blue
    const Color tealColor = Color(0xFF0D9488); // MedSafe Teal Accent
    const Color bgLight = Color(0xFFF8FAFC);

    final double sheetHeight = _isFullScreen 
        ? MediaQuery.of(context).size.height * 0.9 
        : MediaQuery.of(context).size.height * 0.65;

    // Trigger scroll to bottom on load
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: access.borderColor.withOpacity(0.5)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MedSafe AI Support',
                          style: access.getTextStyle(
                            baseSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: access.textColor,
                          ),
                        ),
                        Text(
                          'Context: $activeScreen',
                          style: access.getTextStyle(
                            baseSize: 11.0,
                            color: access.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Expand/Collapse Toggle
                    IconButton(
                      icon: Icon(
                        _isFullScreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        color: access.secondaryTextColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isFullScreen = !_isFullScreen;
                        });
                      },
                      tooltip: _isFullScreen ? 'Exit full screen' : 'Expand full screen',
                    ),
                    // Clear Chat History Button
                    IconButton(
                      icon: Icon(
                        Icons.delete_sweep_outlined,
                        color: access.alertRed.withOpacity(0.8),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear Chat History?'),
                            content: const Text(
                              'Are you sure you want to clear your local chat history? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref.read(chatHistoryProvider.notifier).clearHistory();
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Clear',
                                  style: TextStyle(color: access.alertRed),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: 'Clear history',
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: access.textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Message Board / Body
          Expanded(
            child: Container(
              color: bgLight,
              child: messages.isEmpty
                  ? _buildEmptyState(access, tealColor)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return _buildTypingIndicator(access, primaryColor);
                        }
                        return _buildMessageBubble(messages[index], access, primaryColor, tealColor);
                      },
                    ),
            ),
          ),

          // Input field row
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: VoiceInputField(
                    access: access,
                    controller: _controller,
                    labelText: 'Ask about MedSafe features...',
                    icon: Icons.chat_bubble_outline_rounded,
                    mockTranscript: _getRandomMockTranscript(),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () => _submitMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AccessibilityConfig access, Color tealColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: access.secondaryTextColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to MedSafe Assistant!',
            textAlign: TextAlign.center,
            style: access.getTextStyle(
              baseSize: 18.0,
              fontWeight: FontWeight.bold,
              color: access.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about cabinet tracking, medication schedules, caregiver profiles, scan features, or manual entry.',
            textAlign: TextAlign.center,
            style: access.getTextStyle(
              baseSize: 13.0,
              color: access.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Suggested Prompts:',
              style: access.getTextStyle(
                baseSize: 13.0,
                fontWeight: FontWeight.bold,
                color: access.textColor.withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedPrompts.map((prompt) {
              return ActionChip(
                label: Text(
                  prompt,
                  style: access.getTextStyle(
                    baseSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: tealColor,
                  ),
                ),
                backgroundColor: Colors.white,
                side: BorderSide(color: tealColor.withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () => _submitMessage(prompt),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      ChatMessage message, AccessibilityConfig access, Color primaryColor, Color tealColor) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tealColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.support_agent_rounded, size: 18, color: tealColor),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isUser ? null : Border.all(color: access.borderColor.withOpacity(0.3)),
              ),
              child: RichText(
                text: TextSpan(
                  children: _parseMarkdown(
                    message.text,
                    access.getTextStyle(
                      baseSize: 14.0,
                      color: isUser ? Colors.white : access.textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_rounded, size: 18, color: primaryColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(AccessibilityConfig access, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.support_agent_rounded, size: 18, color: primaryColor),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: access.borderColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'AI is writing...',
                  style: access.getTextStyle(
                    baseSize: 12.0,
                    color: access.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<TextSpan> _parseMarkdown(String text, TextStyle baseStyle) {
  final List<TextSpan> spans = [];
  final RegExp regex = RegExp(r'\*\*(.*?)\*\*');
  int lastMatchEnd = 0;

  for (final Match match in regex.allMatches(text)) {
    // Add plain text before match
    if (match.start > lastMatchEnd) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd, match.start),
        style: baseStyle,
      ));
    }
    // Add bold text
    spans.add(TextSpan(
      text: match.group(1),
      style: baseStyle.copyWith(fontWeight: FontWeight.bold),
    ));
    lastMatchEnd = match.end;
  }

  // Add remaining plain text
  if (lastMatchEnd < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastMatchEnd),
      style: baseStyle,
    ));
  }

  return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
}
