import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'main.dart';
import 'services/pdf_report_service.dart';
import 'shared_states.dart';

class MedicalInformationScreen extends ConsumerWidget {
  const MedicalInformationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = AccessibilityConfig(
      isElderlyMode: ref.watch(elderlyModeProvider),
    );
    final profile =
        ref.watch(activeProfileProvider) ??
        ref.watch(onboardingProfileProvider).value;
    final medicines = ref.watch(cabinetProvider);
    final schedules = ref.watch(schedulesProvider).value ?? [];
    if (profile == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: access.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Medical Information',
          style: access.getTextStyle(baseSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.nickname?.isNotEmpty == true
                      ? profile.nickname!
                      : 'Patient',
                  style: access.getTextStyle(
                    baseSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Age: ${profile.age ?? 'Not recorded'}   •   Sex: ${profile.sex ?? 'Not recorded'}   •   Weight: ${profile.weightKg?.toString() ?? 'Not recorded'} kg',
                  style: access.getTextStyle(
                    baseSize: 13,
                    color: access.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _section(
            'Known allergies',
            profile.allergies.isEmpty ? ['None reported'] : profile.allergies,
            access,
            critical: true,
          ),
          _section(
            'Chronic conditions',
            profile.chronicConditions.isEmpty
                ? ['None reported']
                : profile.chronicConditions,
            access,
          ),
          _section(
            'Current medicines',
            medicines.isEmpty
                ? ['No medicine in cabinet']
                : medicines.map((med) {
                    final matches = schedules.where(
                      (item) => item.cabinetItemId == med.id,
                    );
                    final schedule = matches.isEmpty ? null : matches.first;
                    return '${med.name} • ${schedule == null ? 'No schedule' : '${schedule.frequencyPerDay}x daily at ${schedule.scheduledTimes.join(', ')}'}';
                  }).toList(),
            access,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => PdfReportService.shareDoctorReport(
              profile: profile,
              medicines: medicines,
              schedules: schedules,
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export medical summary PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: access.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    List<String> lines,
    AccessibilityConfig access, {
    bool critical = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: critical
              ? access.alertRed.withOpacity(.3)
              : access.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: access.getTextStyle(
              baseSize: 16,
              fontWeight: FontWeight.bold,
              color: critical ? access.alertRed : access.textColor,
            ),
          ),
          const SizedBox(height: 9),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('• $line', style: access.getTextStyle(baseSize: 13)),
            ),
          ),
        ],
      ),
    ),
  );
}
