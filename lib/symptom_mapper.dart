import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';

class SymptomMapperScreen extends ConsumerStatefulWidget {
  const SymptomMapperScreen({super.key});

  @override
  ConsumerState<SymptomMapperScreen> createState() => _SymptomMapperScreenState();
}

class _SymptomMapperScreenState extends ConsumerState<SymptomMapperScreen> {
  final _symptomController = TextEditingController();
  List<Map<String, String>>? _suggestedClasses;

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  void _mapSymptom(AccessibilityConfig access) {
    final query = _symptomController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    setState(() {
      if (query.contains('pain') || query.contains('headache') || query.contains('body ache')) {
        _suggestedClasses = [
          {
            'class': 'Analgesics (Pain Relievers)',
            'description': 'Helps block pain signals. Common examples include Acetaminophen or NSAIDs.',
          },
          {
            'class': 'Antipyretics (Fever Reducers)',
            'description': 'Helps lower body temperature by acting on the hypothalamus.',
          }
        ];
      } else if (query.contains('stomach') || query.contains('acid') || query.contains('heartburn')) {
        _suggestedClasses = [
          {
            'class': 'Antacids',
            'description': 'Neutralizes excess stomach acid quickly to relieve indigestion.',
          },
          {
            'class': 'H2 Receptor Antagonists / PPIs',
            'description': 'Reduces the amount of acid produced by glands in your stomach lining.',
          }
        ];
      } else if (query.contains('cough') || query.contains('cold') || query.contains('fever')) {
        _suggestedClasses = [
          {
            'class': 'Antihistamines',
            'description': 'Blocks allergy-causing histamines to reduce runny nose and sneezing.',
          },
          {
            'class': 'Antipyretics',
            'description': 'Assists in reducing high body temperature.',
          }
        ];
      } else {
        _suggestedClasses = [
          {
            'class': 'Primary Care Consultation Required',
            'description': 'Symptom profile does not match common OTC therapeutic drug classes. Please consult a clinician.',
          }
        ];
      }
    });
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
        elevation: 0,
        title: Text(
          'Symptom Mapper',
          style: access.getTextStyle(
            baseSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: ElderlyModeToggle(
              access: access,
              value: isElderlyMode,
              onChanged: (val) {
                ref.read(elderlyModeProvider.notifier).toggle();
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Non-dismissible disclaimer banner
          DisclaimerBanner(access: access),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: access.scaleSpacing(20.0),
                vertical: access.scaleSpacing(20.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Symptom-to-Drug-Class Mapper',
                    style: access.getTextStyle(
                      baseSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter your symptoms to view matching clinical drug classes. Dictation voice input is fully supported.',
                    style: access.getTextStyle(
                      baseSize: 13.0,
                      color: access.textColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Voice Assisted Symptom Input Field
                  VoiceInputField(
                    access: access,
                    controller: _symptomController,
                    labelText: 'Describe Symptom (e.g. stomach pain)',
                    icon: Icons.bubble_chart_outlined,
                    mockTranscript: 'stomach pain',
                  ),
                  const SizedBox(height: 16),

                  // Trigger button
                  ElevatedButton(
                    onPressed: () => _mapSymptom(access),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: access.primaryTeal,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, access.minTapTargetSize),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Search Drug Classes',
                      style: access.getTextStyle(
                        baseSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Gated safety warning banner
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: access.alertRed.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: access.alertRed.withOpacity(0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: access.alertRed, size: access.scaleText(20.0)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Warning: Suggestions represent drug therapeutic classes only, not specific brand names. Gated behind clinical guidelines: Always consult a physician before taking any medication.',
                            style: access.getTextStyle(
                              baseSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: access.alertRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Suggestions list output
                  if (_suggestedClasses != null) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Suggested Therapeutic Classes',
                      style: access.getTextStyle(
                        baseSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._suggestedClasses!.map((sug) => _buildSuggestionCard(sug, access)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, String> sug, AccessibilityConfig access) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(access.scaleSpacing(16.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: access.textColor.withOpacity(0.08), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sug['class']!,
            style: access.getTextStyle(
              baseSize: 15.0,
              fontWeight: FontWeight.bold,
              color: access.primaryTeal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sug['description']!,
            style: access.getTextStyle(
              baseSize: 13.0,
              color: access.textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
