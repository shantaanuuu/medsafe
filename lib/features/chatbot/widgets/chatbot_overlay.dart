import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accessibility_config.dart';
import '../../../shared_states.dart';
import 'chat_sheet.dart';

class ChatbotOverlayButton extends ConsumerWidget {
  const ChatbotOverlayButton({super.key});

  void _showChatbot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChatSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);
    
    const Color primaryColor = Color(0xFF2563EB); // MedSafe Blue

    return FloatingActionButton(
      heroTag: 'medsafe_chatbot_fab',
      onPressed: () => _showChatbot(context),
      backgroundColor: primaryColor,
      elevation: 6,
      child: const Icon(
        Icons.support_agent_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
