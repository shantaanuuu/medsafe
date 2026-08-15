import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';

class SideEffectProfilerScreen extends ConsumerWidget {
  final Medicine medicine;

  const SideEffectProfilerScreen({super.key, required this.medicine});

  // Fetch mock FAERS reporting signals based on drug profiles
  List<Map<String, dynamic>> _getMockFaersSignals() {
    if (medicine.name.contains('Paracetamol')) {
      return [
        {
          'effect': 'Hepatic Injury (Liver stress)',
          'severity': 'caution',
          'prr': '2.1',
          'ror': '2.3',
          'description': 'Elevated liver enzymes reported in cases exceeding recommended thresholds.',
        },
        {
          'effect': 'Nausea & Vomiting',
          'severity': 'monitor',
          'prr': '1.3',
          'ror': '1.4',
          'description': 'Common mild gastrointestinal reporting signal.',
        },
        {
          'effect': 'Allergic Skin Rash',
          'severity': 'monitor',
          'prr': '1.1',
          'ror': '1.2',
          'description': 'Infrequent cutaneous hypersensitivity reports.',
        },
      ];
    } else if (medicine.name.contains('Metformin')) {
      return [
        {
          'effect': 'Lactic Acidosis',
          'severity': 'contraindicated',
          'prr': '3.8',
          'ror': '4.1',
          'description': 'Critical, rare metabolic signal. Risk increases in patients with renal impairment.',
        },
        {
          'effect': 'Gastrointestinal Distress (Diarrhea)',
          'severity': 'caution',
          'prr': '2.7',
          'ror': '2.9',
          'description': 'Very common reporting signal, typically decreases over duration of use.',
        },
        {
          'effect': 'Vitamin B12 Deficiency',
          'severity': 'monitor',
          'prr': '1.4',
          'ror': '1.5',
          'description': 'Reported association with long-term absorption inhibition.',
        },
      ];
    } else {
      return [
        {
          'effect': 'Diarrhea',
          'severity': 'monitor',
          'prr': '1.9',
          'ror': '2.0',
          'description': 'Gastrointestinal microbiome alteration signal.',
        },
        {
          'effect': 'Skin Rash (Hives)',
          'severity': 'caution',
          'prr': '2.2',
          'ror': '2.4',
          'description': 'Common penicillin-class drug hypersensitivity signal.',
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);
    
    final signals = _getMockFaersSignals();

    return Scaffold(
      backgroundColor: access.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: access.textColor,
        elevation: 0,
        title: Text(
          'Side Effect Risk Profiler',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Explanation Header Card
                  _buildProfilerHeader(access),
                  const SizedBox(height: 24),

                  // Database Verified Side Effects
                  _buildDatabaseSideEffectsSection(access),

                  // Known Drug Interactions
                  _buildDatabaseInteractionsSection(access),

                  // FAERS Signals Header
                  Text(
                    'FDA FAERS Reporting Signals',
                    style: access.getTextStyle(
                      baseSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Signals List
                  ...signals.map((sig) => _buildSignalCard(sig, access)),

                  const SizedBox(height: 20),
                  // Explanation of terms
                  _buildTermGlossary(access),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilerHeader(AccessibilityConfig access) {
    return Container(
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
            'Information Transparency Notice',
            style: access.getTextStyle(
              baseSize: 14.0,
              fontWeight: FontWeight.bold,
              color: access.primaryTeal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This profile presents statistical signals from the FDA Adverse Event Reporting System (FAERS). These figures represent reported population safety correlations, NOT a personalized medical diagnosis of risk for your specific case.',
            style: access.getTextStyle(
              baseSize: 13.0,
              color: access.textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalCard(Map<String, dynamic> sig, AccessibilityConfig access) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(access.scaleSpacing(16.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: access.textColor.withOpacity(0.08), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sig['effect'],
                  style: access.getTextStyle(
                    baseSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SeverityChip(access: access, severity: sig['severity']),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sig['description'],
            style: access.getTextStyle(
              baseSize: 13.0,
              color: access.textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMetricBadge('PRR: ${sig['prr']}', access),
              const SizedBox(width: 8),
              _buildMetricBadge('ROR: ${sig['ror']}', access),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String text, AccessibilityConfig access) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: access.textColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: access.textColor.withOpacity(0.08)),
      ),
      child: Text(
        text,
        style: access.getTextStyle(
          baseSize: 11.0,
          fontWeight: FontWeight.w900,
          color: access.textColor.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildTermGlossary(AccessibilityConfig access) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: access.textColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Glossary of Safety Metrics',
            style: access.getTextStyle(
              baseSize: 13.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• PRR (Proportional Reporting Ratio): Compares reporting rates of this drug to rates in overall data. Values > 2 indicate active monitoring signals.',
            style: access.getTextStyle(
              baseSize: 12.0,
              color: access.textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• ROR (Reporting Odds Ratio): Expresses the odds of reporting this side effect relative to other drug reports.',
            style: access.getTextStyle(
              baseSize: 12.0,
              color: access.textColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseSideEffectsSection(AccessibilityConfig access) {
    if (medicine.sideEffects == null || medicine.sideEffects!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final dbSideEffects = medicine.sideEffects!
        .split(RegExp(r'[,;.]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 2)
        .toList();

    if (dbSideEffects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.report_problem_outlined, color: Colors.orange.shade700, size: access.scaleText(20.0)),
            const SizedBox(width: 8),
            Text(
              'DATABASE VERIFIED SIDE EFFECTS',
              style: access.getTextStyle(
                baseSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ).copyWith(letterSpacing: 1.1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(access.scaleSpacing(16.0)),
          decoration: BoxDecoration(
            color: Colors.orange.shade50.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade100, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patients taking this medicine have reported the following symptoms:',
                style: access.getTextStyle(
                  baseSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: access.textColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8.0,
                runSpacing: 10.0,
                children: dbSideEffects.map((effect) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: access.scaleText(14.0),
                          color: Colors.orange.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          effect,
                          style: access.getTextStyle(
                            baseSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDatabaseInteractionsSection(AccessibilityConfig access) {
    if (medicine.drugInteractions == null || medicine.drugInteractions!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final dbInteractions = medicine.drugInteractions!
        .split(RegExp(r'[,;.]'))
        .map((i) => i.trim())
        .where((i) => i.isNotEmpty && i.length > 2)
        .toList();

    if (dbInteractions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade700, size: access.scaleText(20.0)),
            const SizedBox(width: 8),
            Text(
              'KNOWN DRUG INTERACTIONS',
              style: access.getTextStyle(
                baseSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ).copyWith(letterSpacing: 1.1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(access.scaleSpacing(16.0)),
          decoration: BoxDecoration(
            color: Colors.red.shade50.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Avoid co-administering this medicine with these substances or consult your physician:',
                style: access.getTextStyle(
                  baseSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: access.textColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8.0,
                runSpacing: 10.0,
                children: dbInteractions.map((interaction) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.block_outlined,
                          size: access.scaleText(14.0),
                          color: Colors.red.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          interaction,
                          style: access.getTextStyle(
                            baseSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
