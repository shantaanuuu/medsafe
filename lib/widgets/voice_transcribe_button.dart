import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceTranscribeButton extends StatefulWidget {
  const VoiceTranscribeButton({super.key, required this.controller});
  final TextEditingController controller;
  @override
  State<VoiceTranscribeButton> createState() => _VoiceTranscribeButtonState();
}

class _VoiceTranscribeButtonState extends State<VoiceTranscribeButton> {
  final speech = SpeechToText();
  bool ready = false, listening = false;
  String language = 'Auto';
  String seed = '';
  Future<void> toggle() async {
    if (listening) {
      await speech.stop();
      if (mounted) setState(() => listening = false);
      return;
    }
    ready = await speech.initialize(
      onStatus: (s) {
        if (mounted && s == 'done') setState(() => listening = false);
      },
      onError: (_) {
        if (mounted) setState(() => listening = false);
      },
    );
    if (!ready) return;
    final locales = await speech.locales();
    final code = language == 'Hindi'
        ? 'hi'
        : language == 'Marathi'
        ? 'mr'
        : language == 'English'
        ? 'en'
        : '';
    String? id;
    for (final item in locales) {
      if (item.localeId.toLowerCase().startsWith(code)) {
        id = item.localeId;
        break;
      }
    }
    seed = widget.controller.text.trim();
    setState(() => listening = true);
    await speech.listen(
      localeId: id,
      partialResults: true,
      onResult: (r) {
        if (r.recognizedWords.isNotEmpty)
          widget.controller.text = seed.isEmpty
              ? r.recognizedWords
              : '$seed ${r.recognizedWords}';
        if (mounted) setState(() => listening = !r.finalResult);
      },
    );
  }

  @override
  void dispose() {
    speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Voice input and language',
    icon: Icon(
      listening ? Icons.stop_circle_rounded : Icons.mic_rounded,
      color: listening ? Colors.red : const Color(0xff2563eb),
    ),
    onSelected: (x) {
      if (x == 'Listen' || x == 'Stop')
        toggle();
      else
        setState(() => language = x);
    },
    itemBuilder: (_) => [
      PopupMenuItem(
        value: listening ? 'Stop' : 'Listen',
        child: Text(listening ? 'Stop listening' : 'Start listening'),
      ),
      const PopupMenuDivider(),
      ...['Auto', 'Hinglish', 'Hindi', 'English', 'Marathi']
          .map(
            (x) => PopupMenuItem(
              value: x,
              child: Text('$x${x == language ? '  ✓' : ''}'),
            ),
          )
          .toList(),
    ],
  );
}
