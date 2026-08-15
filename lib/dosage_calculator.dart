import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';

class DosageCalculatorScreen extends ConsumerStatefulWidget {
  final Medicine medicine;

  const DosageCalculatorScreen({super.key, required this.medicine});

  @override
  ConsumerState<DosageCalculatorScreen> createState() => _DosageCalculatorScreenState();
}

class _DosageCalculatorScreenState extends ConsumerState<DosageCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();

  String? _resultMessage;
  String? _citation;

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _calculateRange(AccessibilityConfig access) {
    if (!_formKey.currentState!.validate()) return;

    final age = double.tryParse(_ageController.text) ?? 0.0;
    final weight = double.tryParse(_weightController.text) ?? 0.0;

    setState(() {
      if (widget.medicine.name.contains('Paracetamol')) {
        // Mock math for pediatric Paracetamol safe range: 10-15 mg/kg per dose
        final minDose = (weight * 10).toStringAsFixed(0);
        final maxDose = (weight * 15).toStringAsFixed(0);
        _resultMessage = 'Safe Dosage Range: $minDose mg to $maxDose mg per dose (max 4 times daily).';
        _citation = 'Source: openFDA (NDA #019845 - Acetaminophen Structured Product Labeling)';
      } else if (widget.medicine.name.contains('Metformin')) {
        // Adult dosage for Metformin
        if (age < 10) {
          _resultMessage = 'Contraindicated: Safety and efficacy of Metformin has not been established for children under 10.';
          _citation = 'Source: openFDA (NDA #020357 - Metformin HCl Labeling Guideline)';
        } else {
          _resultMessage = 'Standard safe starting range: 500 mg to 850 mg daily, maximum 2000 mg per day.';
          _citation = 'Source: openFDA (NDA #020357 - Metformin HCl Structured Labeling)';
        }
      } else {
        // Default general range fallback
        _resultMessage = 'Consult labeling directions: Typical adult dosage formulation of ${widget.medicine.dosageForm}.';
        _citation = 'Source: RxNorm standard drug product labeling library.';
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
          'Dosage Range Check',
          style: access.getTextStyle(
            baseSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Elderly toggle in header
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
          // Shared disclaimer banner at top
          DisclaimerBanner(access: access),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: access.scaleSpacing(20.0),
                vertical: access.scaleSpacing(20.0),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Medicine info summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: access.textColor.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.scale_rounded, color: access.primaryTeal, size: access.scaleText(24.0)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.medicine.name,
                                  style: access.getTextStyle(baseSize: 16.0, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Calculating safety thresholds based on age and weight parameters.',
                                  style: access.getTextStyle(baseSize: 12.0, color: access.textColor.withOpacity(0.5)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Inputs with Voice Dictation Suffix
                    VoiceInputField(
                      access: access,
                      controller: _ageController,
                      labelText: 'Patient Age (years)',
                      icon: Icons.calendar_month_outlined,
                      mockTranscript: '6',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter age';
                        if (double.tryParse(val) == null) return 'Enter a numeric age';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    VoiceInputField(
                      access: access,
                      controller: _weightController,
                      labelText: 'Patient Weight (kg)',
                      icon: Icons.monitor_weight_outlined,
                      mockTranscript: '20',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter weight';
                        if (double.tryParse(val) == null) return 'Enter a numeric weight';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Action Trigger
                    ElevatedButton(
                      onPressed: () => _calculateRange(access),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: access.primaryTeal,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, access.minTapTargetSize),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Calculate Safe Range',
                        style: access.getTextStyle(
                          baseSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Calculations Result Panel
                    if (_resultMessage != null) ...[
                      const SizedBox(height: 28),
                      Container(
                        padding: EdgeInsets.all(access.scaleSpacing(16.0)),
                        decoration: BoxDecoration(
                          color: access.primaryTeal.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: access.primaryTeal.withOpacity(0.12), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CALCULATED SAFE THRESHOLDS',
                              style: access.getTextStyle(
                                baseSize: 11.0,
                                fontWeight: FontWeight.w900,
                                color: access.primaryTeal,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _resultMessage!,
                              style: access.getTextStyle(
                                baseSize: 15.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _citation!,
                              style: access.getTextStyle(
                                baseSize: 12.0,
                                color: access.textColor.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),
                    // Strict Clinical Safety Disclaimer
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
                              'Safety Notice: This tool only calculates general range limits found in drug labeling documentation. Never administer doses based on self-suggested range values without a direct physician prescription.',
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
