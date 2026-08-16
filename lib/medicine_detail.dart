import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';
import 'dosage_calculator.dart';
import 'risk_profiler.dart';
import 'models/medicine_model.dart';
import 'models/medication_schedule.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'services/api_service.dart';
import 'features/chatbot/widgets/chatbot_overlay.dart';
import 'features/chatbot/providers/chatbot_provider.dart';

class MedicineDetailScreen extends ConsumerWidget {
  final Medicine medicine;

  const MedicineDetailScreen({super.key, required this.medicine});

  // Helper method to look up mock interactions for a specific medicine
  List<Map<String, String>> _getMockInteractions(List<Medicine> cabinet) {
    final List<Map<String, String>> interactions = [];
    final otherMeds = cabinet.where((m) => m.id != medicine.id).toList();

    for (var other in otherMeds) {
      if (medicine.name.contains('Paracetamol') && other.name.contains('Metformin')) {
        interactions.add({
          'otherMed': other.name,
          'severity': 'monitor',
          'description': 'Concomitant use may alter glycemic control. Monitor blood glucose closely.',
        });
      } else if (medicine.name.contains('Metformin') && other.name.contains('Paracetamol')) {
        interactions.add({
          'otherMed': other.name,
          'severity': 'monitor',
          'description': 'Concomitant use may alter glycemic control. Monitor blood glucose closely.',
        });
      }
    }
    return interactions;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final cabinet = ref.watch(cabinetProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);
    
    final interactions = _getMockInteractions(cabinet);

    // Dynamic Source Icon and Label
    IconData sourceIcon;
    String sourceText;
    switch (medicine.verifiedSource) {
      case VerifiedSource.barcode:
        sourceIcon = Icons.qr_code_scanner_rounded;
        sourceText = 'Barcode Scanner (100% Verified)';
        break;
      case VerifiedSource.ocr:
        sourceIcon = Icons.document_scanner_outlined;
        sourceText = 'Prescription OCR (Verified)';
        break;
      case VerifiedSource.manual:
      default:
        sourceIcon = Icons.edit_note_rounded;
        sourceText = 'Manual Entry (Unverified)';
        break;
    }

    final schedulesAsync = ref.watch(schedulesProvider);
    final scheduleList = schedulesAsync.value ?? [];
    MedicationSchedule? schedule;
    for (var s in scheduleList) {
      if (s.cabinetItemId == medicine.id) {
        schedule = s;
        break;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenProvider.notifier).setScreen('Medicine Detail Screen for ${medicine.name} (${medicine.genericName})');
    });

    return Scaffold(
      floatingActionButton: const ChatbotOverlayButton(),
      backgroundColor: access.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: access.textColor,
        elevation: 0,
        title: Text(
          'Medicine Profile',
          style: access.getTextStyle(
            baseSize: 20.0,
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
          // Non-dismissible disclaimer at the top
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
                  // 1. Medicine Header Information Card
                  _buildHeaderCard(context, ref, access, sourceIcon, sourceText),
                  const SizedBox(height: 24),

                  // Medication Schedule Card
                  _buildScheduleCard(context, ref, schedule, access),
                  const SizedBox(height: 24),

                  // 2. Drug Interaction Status
                  Text(
                    'Cabinet Interactions',
                    style: access.getTextStyle(
                      baseSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (interactions.isEmpty)
                    _buildNoInteractionsCard(access)
                  else
                    ...interactions.map((inter) => _buildInteractionTile(inter, access)),

                  const SizedBox(height: 24),

                  // 3. Clinical Guidelines & Info (mocked from FDA labels)
                  Text(
                    'Clinical Information',
                    style: access.getTextStyle(
                      baseSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildClinicalInfoCard(access),
                  const SizedBox(height: 20),

                  // Dosage Calculator Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DosageCalculatorScreen(medicine: medicine),
                        ),
                      );
                    },
                    icon: Icon(Icons.calculate_outlined, size: access.scaleText(20.0), color: Colors.white),
                    label: Text(
                      'Check Safe Dosage Range',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: access.primaryTeal,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, access.minTapTargetSize),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Side Effect Profiler Button
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SideEffectProfilerScreen(medicine: medicine),
                        ),
                      );
                    },
                    icon: Icon(Icons.analytics_outlined, size: access.scaleText(18.0), color: access.primaryTeal),
                    label: Text(
                      'Side Effect Risk Profile (FAERS)',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: access.primaryTeal,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: access.primaryTeal, width: 1.5),
                      minimumSize: Size(double.infinity, access.minTapTargetSize),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // 4. Action triggers
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(cabinetProvider.notifier).removeMedicine(medicine.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${medicine.name} removed from cabinet.'),
                          backgroundColor: access.textColor,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.delete_outline_rounded, color: access.alertRed),
                    label: Text(
                      'Remove from Cabinet',
                      style: access.getTextStyle(
                        baseSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: access.alertRed,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: access.alertRed.withOpacity(0.5), width: 1.5),
                      minimumSize: Size(double.infinity, access.minTapTargetSize),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    WidgetRef ref,
    AccessibilityConfig access,
    IconData sourceIcon,
    String sourceText,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(access.scaleSpacing(20.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: access.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: access.pastelBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: access.primaryBlue,
                  size: access.scaleText(32.0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (medicine.nickname != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: access.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          medicine.nickname!.toUpperCase(),
                          style: access.getTextStyle(
                            baseSize: 11.0,
                            fontWeight: FontWeight.bold,
                            color: access.primaryTeal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      medicine.name,
                      style: access.getTextStyle(
                        baseSize: 22.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medicine.genericName,
                      style: access.getTextStyle(
                        baseSize: 15.0,
                        color: access.textColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Metadata Grid
          _buildMetaRow('Formulation', medicine.dosageForm, access),
          const SizedBox(height: 10),
          if (medicine.nickname != null) ...[
            _buildMetaRow('Nickname', medicine.nickname!, access),
            const SizedBox(height: 10),
          ],
          if (medicine.quantity != null) ...[
            _buildMetaRow('Quantity', '${medicine.quantity!.toStringAsFixed(0)} units', access),
            const SizedBox(height: 10),
          ],
          if (medicine.dosageSchedule != null) ...[
            _buildMetaRow('Schedule', medicine.dosageSchedule!, access),
            const SizedBox(height: 10),
          ],
          if (medicine.batchNumber != null) ...[
            _buildMetaRow('Batch Code', medicine.batchNumber!, access),
            const SizedBox(height: 10),
          ],
          // Expiry Date Row with Edit Pen Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expiry Date',
                style: access.getTextStyle(
                  baseSize: 14.0,
                  color: access.textColor.withOpacity(0.5),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${medicine.expiryDate.year}-${medicine.expiryDate.month.toString().padLeft(2, '0')}-${medicine.expiryDate.day.toString().padLeft(2, '0')}',
                    style: access.getTextStyle(
                      baseSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: medicine.expiryDate.difference(DateTime.now()).inDays <= 30
                          ? access.alertRed
                          : access.textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.edit_rounded, size: 18, color: access.primaryTeal),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: medicine.expiryDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        _updateExpiryDate(context, ref, picked, access);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Source Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Source Status',
                style: access.getTextStyle(
                  baseSize: 14.0,
                  color: access.textColor.withOpacity(0.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: access.primaryTeal.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(sourceIcon, size: access.scaleText(14.0), color: access.primaryTeal),
                    const SizedBox(width: 6),
                    Text(
                      sourceText,
                      style: access.getTextStyle(
                        baseSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: access.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateExpiryDate(
    BuildContext context,
    WidgetRef ref,
    DateTime newDate,
    AccessibilityConfig access,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updating expiry date...')),
    );

    try {
      final newMedicine = Medicine(
        id: medicine.id,
        name: medicine.name,
        genericName: medicine.genericName,
        batchNumber: medicine.batchNumber,
        expiryDate: newDate,
        addedDate: medicine.addedDate,
        dosageForm: medicine.dosageForm,
        verifiedSource: medicine.verifiedSource,
        price: medicine.price,
        manufacturer: medicine.manufacturer,
        sideEffects: medicine.sideEffects,
        drugInteractions: medicine.drugInteractions,
        medicineDesc: medicine.medicineDesc,
        substitutes: medicine.substitutes,
        chemicalClass: medicine.chemicalClass,
        therapeuticClass: medicine.therapeuticClass,
        habitForming: medicine.habitForming,
        nickname: medicine.nickname,
        quantity: medicine.quantity,
        dosageSchedule: medicine.dosageSchedule,
      );

      await ref.read(cabinetProvider.notifier).addMedicine(newMedicine);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expiry date updated successfully!'),
            backgroundColor: const Color(0xFF2563EB),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update expiry date: $e'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    }
  }

  Widget _buildMetaRow(String label, String value, AccessibilityConfig access, {bool isAlert = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: access.getTextStyle(
            baseSize: 14.0,
            color: access.textColor.withOpacity(0.5),
          ),
        ),
        Text(
          value,
          style: access.getTextStyle(
            baseSize: 14.0,
            fontWeight: FontWeight.bold,
            color: isAlert ? access.alertRed : access.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNoInteractionsCard(AccessibilityConfig access) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(access.scaleSpacing(16.0)),
      decoration: BoxDecoration(
        color: access.successGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: access.successGreen.withOpacity(0.15), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: access.successGreen, size: access.scaleText(20.0)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No active interactions detected with medicines currently inside your cabinet.',
              style: access.getTextStyle(
                baseSize: 13.0,
                fontWeight: FontWeight.bold,
                color: access.successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionTile(Map<String, String> inter, AccessibilityConfig access) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(access.scaleSpacing(16.0)),
      decoration: BoxDecoration(
        color: access.alertRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: access.alertRed.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Interacts with: ${inter['otherMed']}',
                style: access.getTextStyle(
                  baseSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SeverityChip(access: access, severity: inter['severity']!),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            inter['description']!,
            style: access.getTextStyle(
              baseSize: 13.0,
              color: access.textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalInfoCard(AccessibilityConfig access) {
    final hasDbData = medicine.manufacturer != null || medicine.substitutes != null;

    return Container(
      width: double.infinity,
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
            hasDbData ? 'Database Verification & Metadata' : 'Approved FDA Labeling Highlights',
            style: access.getTextStyle(
              baseSize: 14.0,
              fontWeight: FontWeight.bold,
              color: access.primaryTeal,
            ),
          ),
          const SizedBox(height: 12),
          if (hasDbData) ...[
            if (medicine.manufacturer != null) ...[
              _buildMetaRow('Manufacturer', medicine.manufacturer!, access),
              const SizedBox(height: 8),
            ],
            if (medicine.price != null && medicine.price! > 0) ...[
              _buildMetaRow('MRP (Price)', '₹ ${medicine.price!.toStringAsFixed(2)}', access),
              const SizedBox(height: 8),
            ],
            if (medicine.therapeuticClass != null && medicine.therapeuticClass!.isNotEmpty) ...[
              _buildMetaRow('Therapeutic Class', medicine.therapeuticClass!, access),
              const SizedBox(height: 8),
            ],
            if (medicine.chemicalClass != null && medicine.chemicalClass!.isNotEmpty) ...[
              _buildMetaRow('Chemical Class', medicine.chemicalClass!, access),
              const SizedBox(height: 8),
            ],
            if (medicine.habitForming != null && medicine.habitForming!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Habit Forming: ',
                    style: access.getTextStyle(baseSize: 13.0, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    medicine.habitForming!,
                    style: access.getTextStyle(
                      baseSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: medicine.habitForming!.toLowerCase() == 'yes' ? access.alertRed : access.successGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (medicine.medicineDesc != null && medicine.medicineDesc!.isNotEmpty) ...[
              Text(
                'Description:',
                style: access.getTextStyle(baseSize: 13.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                medicine.medicineDesc!,
                style: access.getTextStyle(baseSize: 12.0, color: access.textColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 12),
            ],
            if (medicine.substitutes != null && medicine.substitutes!.isNotEmpty) ...[
              const Divider(height: 32),
              Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, color: access.primaryTeal, size: access.scaleText(20.0)),
                  const SizedBox(width: 8),
                  Text(
                    'ALTERNATIVE SUBSTITUTES',
                    style: access.getTextStyle(
                      baseSize: 13.0,
                      fontWeight: FontWeight.w900,
                      color: access.primaryTeal,
                    ).copyWith(letterSpacing: 1.1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 10.0,
                children: medicine.substitutes!
                    .split(',')
                    .map((sub) => sub.trim())
                    .where((sub) => sub.isNotEmpty)
                    .map((subName) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: access.primaryTeal.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: access.scaleText(16.0),
                          color: access.primaryTeal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          subName,
                          style: access.getTextStyle(
                            baseSize: 13.0,
                            fontWeight: FontWeight.bold,
                            color: access.textColor.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ] else ...[
            _buildBulletPoint('Do not exceed the maximum daily dosage ranges.', access),
            const SizedBox(height: 8),
            _buildBulletPoint('Consult with a medical professional if symptoms persist.', access),
            const SizedBox(height: 8),
            _buildBulletPoint('Store in a cool, dry place away from direct sunlight.', access),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, AccessibilityConfig access) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: access.getTextStyle(
            baseSize: 14.0,
            fontWeight: FontWeight.bold,
            color: access.primaryTeal,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: access.getTextStyle(
              baseSize: 13.0,
              color: access.textColor.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(
    BuildContext context,
    WidgetRef ref,
    MedicationSchedule? schedule,
    AccessibilityConfig access,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(access.scaleSpacing(20.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: access.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dosing Schedule',
                style: access.getTextStyle(
                  baseSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_calendar_rounded, color: access.primaryTeal),
                onPressed: () {
                  _showEditScheduleBottomSheet(context, ref, schedule, access);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (schedule == null) ...[
            Text(
              'No active schedule set for this medicine.',
              style: access.getTextStyle(
                baseSize: 14.0,
                color: access.textColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                _showEditScheduleBottomSheet(context, ref, null, access);
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Add Schedule', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: access.primaryTeal,
                minimumSize: Size(double.infinity, access.minTapTargetSize),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.repeat_rounded, color: access.primaryTeal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Frequency:',
                  style: access.getTextStyle(baseSize: 14.0, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Text(
                  '${schedule.frequencyPerDay} times/day',
                  style: access.getTextStyle(baseSize: 14.0, fontWeight: FontWeight.bold, color: access.primaryTeal),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Scheduled Dose Times:',
              style: access.getTextStyle(baseSize: 14.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: schedule.scheduledTimes.map((timeStr) {
                return Chip(
                  avatar: Icon(Icons.access_time_rounded, size: 16, color: access.primaryTeal),
                  label: Text(
                    timeStr,
                    style: access.getTextStyle(baseSize: 13.0, fontWeight: FontWeight.w600, color: access.textColor),
                  ),
                  backgroundColor: access.primaryTeal.withOpacity(0.06),
                  side: BorderSide(color: access.primaryTeal.withOpacity(0.12)),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditScheduleBottomSheet(
    BuildContext context,
    WidgetRef ref,
    MedicationSchedule? existing,
    AccessibilityConfig access,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        var initialFreq = 'Once Daily';
        if (existing != null) {
          if (existing.frequencyPerDay == 1) initialFreq = 'Once Daily';
          else if (existing.frequencyPerDay == 2) initialFreq = 'Twice Daily';
          else if (existing.frequencyPerDay == 3) initialFreq = 'Three Times Daily';
          else if (existing.frequencyPerDay == 4) initialFreq = 'Four Times Daily';
          else initialFreq = 'Custom';
        }

        return _EditScheduleSheetBody(
          existing: existing,
          initialFreq: initialFreq,
          medicine: medicine,
          ref: ref,
          access: access,
          onSave: () => Navigator.pop(context),
        );
      },
    );
  }
}

class _EditScheduleSheetBody extends StatefulWidget {
  final MedicationSchedule? existing;
  final String initialFreq;
  final Medicine medicine;
  final WidgetRef ref;
  final AccessibilityConfig access;
  final VoidCallback onSave;

  const _EditScheduleSheetBody({
    required this.existing,
    required this.initialFreq,
    required this.medicine,
    required this.ref,
    required this.access,
    required this.onSave,
  });

  @override
  State<_EditScheduleSheetBody> createState() => _EditScheduleSheetBodyState();
}

class _EditScheduleSheetBodyState extends State<_EditScheduleSheetBody> {
  late String _frequency;
  late int _customTimesCount;
  late List<TimeOfDay> _doseTimes;

  @override
  void initState() {
    super.initState();
    _frequency = widget.initialFreq;
    if (widget.existing != null) {
      _customTimesCount = widget.existing!.frequencyPerDay;
      _doseTimes = widget.existing!.scheduledTimes.map((t) => _parseTimeOfDay(t)).toList();
    } else {
      _customTimesCount = 1;
      _doseTimes = [const TimeOfDay(hour: 9, minute: 0)];
    }
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      final timeParts = parts[0].split(':');
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPm = parts[1].toUpperCase() == 'PM';
      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  void _updateDoseTimesForFrequency(String freq) {
    setState(() {
      _frequency = freq;
      if (freq == 'Once Daily') {
        _doseTimes = [const TimeOfDay(hour: 9, minute: 0)];
      } else if (freq == 'Twice Daily') {
        _doseTimes = [
          const TimeOfDay(hour: 9, minute: 0),
          const TimeOfDay(hour: 21, minute: 0),
        ];
      } else if (freq == 'Three Times Daily') {
        _doseTimes = [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];
      } else if (freq == 'Four Times Daily') {
        _doseTimes = [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 12, minute: 0),
          const TimeOfDay(hour: 16, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];
      } else if (freq == 'Custom') {
        _customTimesCount = _doseTimes.length;
        if (_customTimesCount == 0) {
          _customTimesCount = 1;
          _doseTimes = [const TimeOfDay(hour: 9, minute: 0)];
        }
      }
    });
  }

  void _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final activeProfile = widget.ref.read(activeProfileProvider);
    final caregiverProfile = widget.ref.read(onboardingProfileProvider).value;
    final String? dependentId = (activeProfile != null && caregiverProfile != null && activeProfile.id != caregiverProfile.id)
        ? activeProfile.id
        : null;

    final List<String> formattedTimes = _doseTimes.map((t) {
      final hr = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final min = t.minute.toString().padLeft(2, '0');
      final period = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '${hr.toString().padLeft(2, '0')}:$min $period';
    }).toList();

    final schedule = MedicationSchedule(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      cabinetItemId: widget.medicine.id,
      dependentId: dependentId,
      userUid: user.uid,
      frequencyPerDay: _doseTimes.length,
      scheduledTimes: formattedTimes,
    );

    try {
      await widget.ref.read(apiServiceProvider).saveSchedule(schedule);
      widget.ref.invalidate(schedulesProvider);
      
      final updatedMedicine = widget.medicine.copyWith(
        dosageSchedule: '${_doseTimes.length} times/day',
      );
      await widget.ref.read(cabinetProvider.notifier).addMedicine(updatedMedicine);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule saved successfully!'),
            backgroundColor: Color(0xFF2563EB),
          ),
        );
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save schedule: $e'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    }
  }

  void _delete() async {
    if (widget.existing == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await widget.ref.read(apiServiceProvider).deleteSchedule(user.uid, widget.existing!.id);
      widget.ref.invalidate(schedulesProvider);
      
      final updatedMedicine = widget.medicine.copyWith(
        dosageSchedule: null,
      );
      await widget.ref.read(cabinetProvider.notifier).addMedicine(updatedMedicine);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule deleted successfully!'),
            backgroundColor: Color(0xFF2563EB),
          ),
        );
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete schedule: $e'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = widget.access;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existing != null ? 'Edit Schedule' : 'Add Schedule',
                style: access.getTextStyle(baseSize: 20.0, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Frequency Dropdown
          DropdownButtonFormField<String>(
            value: _frequency,
            dropdownColor: Colors.white,
            style: access.getTextStyle(baseSize: 15.0),
            decoration: InputDecoration(
              labelText: 'Frequency',
              labelStyle: access.getTextStyle(
                baseSize: 14.0,
                color: access.textColor.withOpacity(0.6),
              ),
              prefixIcon: Icon(
                Icons.repeat_rounded,
                color: access.textColor.withOpacity(0.6),
                size: access.scaleText(20.0),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: access.textColor.withOpacity(0.08), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: access.primaryTeal, width: 2.0),
              ),
            ),
            items: [
              'Once Daily',
              'Twice Daily',
              'Three Times Daily',
              'Four Times Daily',
              'Custom',
            ].map((f) {
              return DropdownMenuItem<String>(
                value: f,
                child: Text(f, style: access.getTextStyle(baseSize: 15.0)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                _updateDoseTimesForFrequency(val);
              }
            },
          ),
          const SizedBox(height: 16),

          // Custom Count Selector
          if (_frequency == 'Custom') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Number of doses per day:',
                  style: access.getTextStyle(baseSize: 15.0, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _customTimesCount > 1
                          ? () {
                              setState(() {
                                _customTimesCount--;
                                _doseTimes.removeLast();
                              });
                            }
                          : null,
                    ),
                    Text(
                      '$_customTimesCount',
                      style: access.getTextStyle(baseSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _customTimesCount < 12
                          ? () {
                              setState(() {
                                _customTimesCount++;
                                _doseTimes.add(const TimeOfDay(hour: 9, minute: 0));
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Dose time pickers list
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _doseTimes.length,
              itemBuilder: (context, index) {
                final time = _doseTimes[index];
                final hr = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
                final min = time.minute.toString().padLeft(2, '0');
                final period = time.period == DayPeriod.am ? 'AM' : 'PM';
                final formattedTime = '${hr.toString().padLeft(2, '0')}:$min $period';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (picked != null) {
                        setState(() {
                          _doseTimes[index] = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: access.textColor.withOpacity(0.08), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, color: access.primaryTeal),
                              const SizedBox(width: 12),
                              Text(
                                'Dose ${index + 1}',
                                style: access.getTextStyle(baseSize: 15.0, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                formattedTime,
                                style: access.getTextStyle(baseSize: 15.0, fontWeight: FontWeight.bold, color: access.primaryTeal),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down, color: access.textColor.withOpacity(0.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Save / Delete Buttons
          Row(
            children: [
              if (widget.existing != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                    label: const Text('Delete', style: TextStyle(color: Color(0xFFDC2626))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                      minimumSize: Size(double.infinity, access.minTapTargetSize),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_rounded, color: Colors.white),
                  label: const Text('Save Plan', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: access.primaryTeal,
                    minimumSize: Size(double.infinity, access.minTapTargetSize),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
