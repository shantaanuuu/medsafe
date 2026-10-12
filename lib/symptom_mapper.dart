import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'accessibility_config.dart';
import 'services/api_service.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';

class SymptomMapperScreen extends ConsumerStatefulWidget {
  const SymptomMapperScreen({super.key});

  @override
  ConsumerState<SymptomMapperScreen> createState() =>
      _SymptomMapperScreenState();
}

class _SymptomMapperScreenState extends ConsumerState<SymptomMapperScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _symptomController = TextEditingController();
  String _sex = 'M';
  bool _isLoading = false;
  String? _error;
  SymptomAnalysisResult? _result;
  final SpeechToText _speech = SpeechToText();
  List<LocaleName> _locales = const [];
  bool _speechReady = false;
  bool _isListening = false;
  String _language = 'auto';
  String _speechSeed = '';

  @override
  void initState() {
    super.initState();
    _prepareSpeech();
  }

  Future<void> _prepareSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (mounted && status == 'done') setState(() => _isListening = false);
      },
      onError: (error) {
        if (mounted)
          setState(() {
            _isListening = false;
            _error = 'Voice input: ${error.errorMsg}';
          });
      },
    );
    if (!mounted) return;
    final locales = available ? await _speech.locales() : <LocaleName>[];
    setState(() {
      _speechReady = available;
      _locales = locales;
    });
  }

  String? get _localeId {
    if (_language == 'auto') return null;
    final prefix = _language == 'hindi' ? 'hi' : 'en';
    for (final locale in _locales) {
      if (locale.localeId.toLowerCase().startsWith(prefix))
        return locale.localeId;
    }
    return null;
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    if (!_speechReady) {
      await _prepareSpeech();
      if (!_speechReady) {
        if (mounted)
          setState(
            () => _error =
                'Speech recognition is unavailable. Check microphone permission and speech services.',
          );
        return;
      }
    }
    _speechSeed = _symptomController.text.trim();
    setState(() {
      _error = null;
      _isListening = true;
    });
    await _speech.listen(
      localeId: _localeId,
      partialResults: true,
      cancelOnError: true,
      onResult: (result) {
        final spoken = result.recognizedWords.trim();
        if (spoken.isNotEmpty)
          _symptomController.text = _speechSeed.isEmpty
              ? spoken
              : '$_speechSeed $spoken';
        if (mounted) setState(() => _isListening = !result.finalResult);
      },
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _symptomController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ref
          .read(apiServiceProvider)
          .analyzeSymptoms(
            age: int.parse(_ageController.text.trim()),
            sex: _sex,
            description: _symptomController.text.trim(),
          );
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);
    return Scaffold(
      backgroundColor: access.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: access.textColor,
        title: Text(
          'Symptom Checker',
          style: access.getTextStyle(baseSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ElderlyModeToggle(
              access: access,
              value: isElderlyMode,
              onChanged: (_) => ref.read(elderlyModeProvider.notifier).toggle(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(access.scaleSpacing(20)),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DisclaimerBanner(access: access),
              const SizedBox(height: 20),
              Text(
                'Describe what you are feeling',
                style: access.getTextStyle(
                  baseSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Write in English or Hinglish. Your symptoms are matched to show possible conditions.',
                style: access.getTextStyle(
                  baseSize: 13,
                  color: access.textColor.withOpacity(.65),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final age = int.tryParse(value?.trim() ?? '');
                        return age == null || age < 0 || age > 120
                            ? 'Enter age from 0 to 120'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _sex,
                      decoration: const InputDecoration(
                        labelText: 'Sex',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'M', child: Text('Male')),
                        DropdownMenuItem(value: 'F', child: Text('Female')),
                      ],
                      onChanged: _isLoading
                          ? null
                          : (value) => setState(() => _sex = value ?? 'M'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Symptoms',
                      style: access.getTextStyle(
                        baseSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _language,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'auto', child: Text('Auto')),
                      DropdownMenuItem(value: 'hindi', child: Text('Hindi')),
                      DropdownMenuItem(
                        value: 'english',
                        child: Text('English'),
                      ),
                    ],
                    onChanged: _isListening
                        ? null
                        : (value) =>
                              setState(() => _language = value ?? 'auto'),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              TextFormField(
                controller: _symptomController,
                minLines: 4,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText:
                      'e.g. Mujhe sar dard, khujli aur aankhein laal ho rahi hain.',
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(7),
                    child: IconButton.filled(
                      tooltip: _isListening
                          ? 'Stop listening'
                          : 'Speak symptoms',
                      onPressed: _isLoading ? null : _toggleListening,
                      icon: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _isListening
                            ? const Color(0xffdc2626)
                            : access.primaryTeal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 3
                    ? 'Describe your symptoms in a little more detail'
                    : null,
              ),
              if (_isListening) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.graphic_eq_rounded,
                      color: Color(0xffdc2626),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Listening... speak naturally; your words will appear above.',
                      style: access.getTextStyle(
                        baseSize: 12,
                        color: const Color(0xffdc2626),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Tap the microphone to speak in Hindi, English, or Hinglish.',
                  style: access.getTextStyle(
                    baseSize: 12,
                    color: access.textColor.withOpacity(.6),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _analyze,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.health_and_safety_outlined),
                label: Text(
                  _isLoading ? 'Checking symptoms...' : 'Check symptoms',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: access.primaryTeal,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, access.minTapTargetSize),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 18),
                _messageCard(
                  _error!,
                  access,
                  icon: Icons.error_outline,
                  color: access.alertRed,
                ),
              ],
              if (_result != null) ...[
                const SizedBox(height: 24),
                if (_result!.emergency) ...[
                  _messageCard(
                    '${_result!.emergencyReason ?? 'Urgent symptoms detected'}. Please call your local emergency number or seek emergency care now. Do not rely on this app for emergency assessment.',
                    access,
                    icon: Icons.emergency,
                    color: access.alertRed,
                  ),
                  const SizedBox(height: 14),
                ],
                _triageHeaderCard(_result!, access),
                const SizedBox(height: 16),
                _breakdownCard(_result!, access),
                if (_result!.advice.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _adviceCard(_result!.advice, access),
                ],
                const SizedBox(height: 16),
                _messageCard(
                  _result!.disclaimer,
                  access,
                  icon: Icons.health_and_safety_outlined,
                  color: access.textColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _triageHeaderCard(
    SymptomAnalysisResult result,
    AccessibilityConfig access,
  ) {
    Color badgeColor = const Color(0xFF2563EB);
    Color badgeBg = const Color(0xFFEFF6FF);
    if (result.emergency ||
        result.triageLevel.toLowerCase().contains('critical') ||
        result.triageLevel.toLowerCase().contains('high')) {
      badgeColor = const Color(0xFFDC2626);
      badgeBg = const Color(0xFFFEF2F2);
    } else if (result.triageLevel.toLowerCase().contains('moderate')) {
      badgeColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFFFBEB);
    } else if (result.triageLevel.toLowerCase().contains('mild') ||
        result.triageLevel.toLowerCase().contains('routine')) {
      badgeColor = const Color(0xFF16A34A);
      badgeBg = const Color(0xFFF0FDF4);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    color: badgeColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CLINICAL TRIAGE ASSESSMENT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withOpacity(0.4)),
                ),
                child: Text(
                  result.triageCode,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.triageLevel,
            style: access.getTextStyle(
              baseSize: 18,
              fontWeight: FontWeight.bold,
              color: access.textColor,
            ),
          ),
          if (result.affectedSystems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'AFFECTED PHYSIOLOGICAL SYSTEMS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: access.textColor.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.affectedSystems
                  .map(
                    (sys) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sys,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _breakdownCard(
    SymptomAnalysisResult result,
    AccessibilityConfig access,
  ) => _card(
    access,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 18,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 8),
            Text(
              'Clinical Triage Synthesis',
              style: access.getTextStyle(
                baseSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (result.summary.isNotEmpty)
          Text(
            result.summary,
            style: access.getTextStyle(baseSize: 13, height: 1.4),
          ),
        const SizedBox(height: 14),
        Text(
          'DOCUMENTED SYMPTOM MARKERS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: access.textColor.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: result.symptoms
              .map(
                (s) => Chip(
                  backgroundColor: const Color(0xFFF8FAFC),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  label: Text(
                    s.normalised.isEmpty ? s.phrase : s.normalised,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );

  Widget _adviceCard(List<String> advice, AccessibilityConfig access) => _card(
    access,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.fact_check_outlined,
              size: 18,
              color: Color(0xFF16A34A),
            ),
            const SizedBox(width: 8),
            Text(
              'Recommended Triage Protocol',
              style: access.getTextStyle(
                baseSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...advice.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFFDCFCE7),
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.value,
                    style: access.getTextStyle(baseSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _messageCard(
    String text,
    AccessibilityConfig access, {
    required IconData icon,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(.25)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: access.getTextStyle(
              baseSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _card(AccessibilityConfig access, {required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: access.textColor.withOpacity(.1)),
        ),
        child: child,
      );
}
